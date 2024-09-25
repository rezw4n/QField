/***************************************************************************
    smartcloudconnection.cpp
    ---------------------
    begin                : January 2020
    copyright            : (C) 2020 by Matthias Kuhn
    email                : matthias at opengis dot ch
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "smartfield.h"
#include "smartcloudconnection.h"
#include "smartcloudutils.h"

#include <QFile>
#include <QHttpMultiPart>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLockFile>
#include <QNetworkCookie>
#include <QNetworkCookieJar>
#include <QSettings>
#include <QTextDocumentFragment>
#include <QTimer>
#include <QUrlQuery>
#include <qgsapplication.h>
#include <qgsmessagelog.h>
#include <qgsnetworkaccessmanager.h>
#include <qgssettings.h>


SmartCloudConnection::SmartCloudConnection()
  : mUrl( QSettings().value( QStringLiteral( "/SmartCloud/url" ), defaultUrl() ).toString() )
  , mUsername( QSettings().value( QStringLiteral( "/SmartCloud/username" ) ).toString() )
  , mToken( QSettings().value( QStringLiteral( "/SmartCloud/token" ) ).toByteArray() )
{
  QgsNetworkAccessManager::instance()->setTimeout( 60 * 60 * 1000 );
  QgsNetworkAccessManager::instance()->setTransferTimeout( 5 * 60 * 1000 );
  // we cannot use "/" as separator, since QGIS puts a suffix QGIS/31700 anyway
  const QString userAgent = QStringLiteral( "smartfield|%1|%2|%3|" ).arg( smartfield::appVersion, smartfield::appVersionStr.normalized( QString::NormalizationForm_KD ), smartfield::gitRev );
  QgsSettings().setValue( QStringLiteral( "/qgis/networkAndProxy/userAgent" ), userAgent );
}

QMap<QString, QString> SmartCloudConnection::sErrors = QMap<QString, QString>(
  {
    { "unknown_error", QObject::tr( "SmartCloud Unknown Error" ) },
    { "status_not_ok", QObject::tr( "Status not ok" ) },
    { "empty_content", QObject::tr( "Empty content" ) },
    { "object_not_found", QObject::tr( "Object not found" ) },
    { "api_error", QObject::tr( "API Error" ) },
    { "validation_error", QObject::tr( "Validation Error" ) },
    { "multiple_projects", QObject::tr( "Multiple Projects" ) },
    { "invalid_deltafile", QObject::tr( "Invalid delta file" ) },
    { "no_qgis_project", QObject::tr( "The project does not contain a valid QGIS project file" ) },
    { "invalid_job", QObject::tr( "Invalid job" ) },
    { "qgis_export_error", QObject::tr( "QGIS export failed" ) },
    { "qgis_cannot_open_project", QObject::tr( "QGIS is unable to open the QGIS project" ) },
  } );

QString SmartCloudConnection::errorString( QNetworkReply *reply )
{
  return CloudError( reply ).message();
}

QString SmartCloudConnection::url() const
{
  return mUrl;
}

void SmartCloudConnection::setUrl( const QString &url )
{
  if ( url == mUrl )
    return;

  mUrl = url;

  QSettings().setValue( QStringLiteral( "/SmartCloud/url" ), url );

  emit urlChanged();
}

QString SmartCloudConnection::defaultUrl()
{
  return QStringLiteral( "https://app.smartfield.cloud" );
}

QString SmartCloudConnection::username() const
{
  return mUsername;
}

QString SmartCloudConnection::avatarUrl() const
{
  return mAvatarUrl;
}

void SmartCloudConnection::setUsername( const QString &username )
{
  if ( mUsername == username )
    return;

  mUsername = username;
  invalidateToken();

  emit usernameChanged();
}

QString SmartCloudConnection::password() const
{
  return mPassword;
}

void SmartCloudConnection::setPassword( const QString &password )
{
  if ( password == mPassword )
    return;

  mPassword = password;
  emit passwordChanged();
}

QString SmartCloudConnection::token() const
{
  return mToken;
}

CloudUserInformation SmartCloudConnection::userInformation() const
{
  return mUserInformation;
}

void SmartCloudConnection::login()
{
  const bool loginUsingToken = !mToken.isEmpty() && ( mPassword.isEmpty() || mUsername.isEmpty() );
  NetworkReply *reply = loginUsingToken
                          ? get( QStringLiteral( "/api/v1/auth/user/" ) )
                          : post( QStringLiteral( "/api/v1/auth/token/" ), QVariantMap(
                                                                             {
                                                                               { "username", mUsername },
                                                                               { "password", mPassword },
                                                                             } ) );

  setStatus( ConnectionStatus::Connecting );

  // Handle login redirect as an error state
  connect( reply, &NetworkReply::redirected, this, [=]() {
    QNetworkReply *rawReply = reply->reply();
    reply->deleteLater();
    rawReply->deleteLater();

    emit loginFailed( tr( "Login error due to unexpected redirect, please retry later" ) );

    setStatus( ConnectionStatus::Disconnected );
    return;
  } );

  connect( reply, &NetworkReply::finished, this, [=]() {
    QNetworkReply *rawReply = reply->reply();

    Q_ASSERT( reply->isFinished() );
    Q_ASSERT( rawReply );

    reply->deleteLater();
    rawReply->deleteLater();

    if ( rawReply->error() != QNetworkReply::NoError )
    {
      int httpCode = rawReply->attribute( QNetworkRequest::HttpStatusCodeAttribute ).toInt();

      if ( rawReply->error() == QNetworkReply::HostNotFoundError )
      {
        emit loginFailed( tr( "Server not found, please check the server URL" ) );
      }
      else if ( rawReply->error() == QNetworkReply::TimeoutError )
      {
        emit loginFailed( tr( "Timeout error, please retry" ) );
      }
      else if ( httpCode == 400 || httpCode == 401 )
      {
        if ( !loginUsingToken )
        {
          emit loginFailed( tr( "Wrong username or password" ) );
        }
        else
        {
          emit loginFailed( tr( "Session expired" ) );
        }
      }
      else
      {
        QString message( errorString( rawReply ) );
        emit loginFailed( message );
      }

      setStatus( ConnectionStatus::Disconnected );
      return;
    }

    QJsonObject resp = QJsonDocument::fromJson( rawReply->readAll() ).object();

    if ( resp.isEmpty() )
    {
      emit loginFailed( tr( "Login temporary unavailable" ) );
      setStatus( ConnectionStatus::Disconnected );
      return;
    }

    QByteArray token = resp.value( QStringLiteral( "token" ) ).toString().toUtf8();

    if ( !token.isEmpty() )
    {
      setToken( token );
    }

    mUsername = resp.value( QStringLiteral( "username" ) ).toString();
    QSettings().setValue( "/SmartCloud/username", mUsername );
    emit usernameChanged();

    mAvatarUrl = resp.value( QStringLiteral( "avatar_url" ) ).toString();
    emit avatarUrlChanged();
    mUserInformation = CloudUserInformation( mUsername, resp.value( QStringLiteral( "email" ) ).toString() );
    emit userInformationChanged();

    setStatus( ConnectionStatus::LoggedIn );
  } );
}

void SmartCloudConnection::logout()
{
  QgsNetworkAccessManager *nam = QgsNetworkAccessManager::instance();
  QNetworkRequest request( mUrl + QStringLiteral( "/api/v1/auth/logout/" ) );
  request.setHeader( QNetworkRequest::ContentTypeHeader, "application/json" );
  setAuthenticationToken( request );

  QNetworkReply *reply = nam->post( request, QByteArray() );

  connect( reply, &QNetworkReply::finished, this, [reply]() {
    reply->deleteLater();
  } );

  mPassword.clear();
  invalidateToken();

  mAvatarUrl.clear();
  emit avatarUrlChanged();

  setStatus( ConnectionStatus::Disconnected );
}

SmartCloudConnection::ConnectionStatus SmartCloudConnection::status() const
{
  return mStatus;
}

SmartCloudConnection::ConnectionState SmartCloudConnection::state() const
{
  return mState;
}

NetworkReply *SmartCloudConnection::post( const QString &endpoint, const QVariantMap &params, const QStringList &fileNames )
{
  QNetworkRequest request( mUrl + endpoint );
  QByteArray requestBody = QJsonDocument( QJsonObject::fromVariantMap( params ) ).toJson();
  setAuthenticationToken( request );
  request.setAttribute( QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::RedirectPolicy::NoLessSafeRedirectPolicy );

  if ( fileNames.isEmpty() )
  {
    request.setHeader( QNetworkRequest::ContentTypeHeader, "application/json" );

    return NetworkManager::post( request, requestBody );
  }

  QHttpMultiPart *multiPart = new QHttpMultiPart( QHttpMultiPart::FormDataType );
  QHttpPart textPart;

  QJsonDocument doc( QJsonObject::fromVariantMap( params ) );
  textPart.setHeader( QNetworkRequest::ContentTypeHeader, QVariant( "application/json" ) );
  textPart.setHeader( QNetworkRequest::ContentDispositionHeader, QVariant( "form-data; name=\"text\"" ) );
  textPart.setBody( doc.toJson() );

  multiPart->append( textPart );

  for ( const QString &fileName : fileNames )
  {
    QHttpPart filePart;
    QFile *file = new QFile( fileName, multiPart );

    if ( !file->open( QIODevice::ReadOnly ) )
      return nullptr;

    const QString header = QStringLiteral( "form-data; name=\"file\"; filename=\"%1\"" ).arg( fileName );
    filePart.setHeader( QNetworkRequest::ContentTypeHeader, QVariant( "application/json" ) );
    filePart.setHeader( QNetworkRequest::ContentDispositionHeader, header );
    filePart.setBodyDevice( file );

    multiPart->append( filePart );
  }

  setClientHeaders( request );

  NetworkReply *reply = NetworkManager::post( request, multiPart );

  multiPart->setParent( reply );

  mPendingRequests++;
  setState( ConnectionState::Busy );
  connect( reply, &NetworkReply::finished, this, [=]() {
    QNetworkReply *rawReply = reply->reply();
    if ( --mPendingRequests == 0 )
    {
      if ( rawReply->error() != QNetworkReply::NoError )
      {
        int httpCode = rawReply->attribute( QNetworkRequest::HttpStatusCodeAttribute ).toInt();
        if ( httpCode == 401 )
        {
          // Access token has been invalidated remotely
          invalidateToken();
          setStatus( ConnectionStatus::Disconnected );
        }
      }
      setState( ConnectionState::Idle );
    }
  } );

  return reply;
}

NetworkReply *SmartCloudConnection::get( const QString &endpoint, const QVariantMap &params )
{
  QNetworkRequest request;

  request.setHeader( QNetworkRequest::ContentTypeHeader, "application/json" );
  request.setAttribute( QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::RedirectPolicy::NoLessSafeRedirectPolicy );
  setAuthenticationToken( request );

  return get( request, endpoint, params );
}


NetworkReply *SmartCloudConnection::get( QNetworkRequest &request, const QString &endpoint, const QVariantMap &params )
{
  QUrl url( endpoint );

  if ( url.isRelative() )
    url.setUrl( mUrl + endpoint );

  return get( request, url, params );
}

NetworkReply *SmartCloudConnection::get( QNetworkRequest &request, const QUrl &url, const QVariantMap &params )
{
  QUrlQuery urlQuery = QUrlQuery( url.query() );

  for ( auto [key, value] : smartfield::asKeyValueRange( params ) )
    urlQuery.addQueryItem( key, value.toString() );

  QUrl requestUrl = url;
  requestUrl.setQuery( urlQuery );

  request.setUrl( requestUrl );

  setClientHeaders( request );

  NetworkReply *reply = NetworkManager::get( request );

  mPendingRequests++;
  setState( ConnectionState::Busy );
  connect( reply, &NetworkReply::finished, this, [=]() {
    QNetworkReply *rawReply = reply->reply();
    if ( --mPendingRequests == 0 )
    {
      if ( rawReply->error() != QNetworkReply::NoError )
      {
        int httpCode = rawReply->attribute( QNetworkRequest::HttpStatusCodeAttribute ).toInt();
        if ( httpCode == 401 )
        {
          // Access token has been invalidated remotely
          invalidateToken();
          setStatus( ConnectionStatus::Disconnected );
        }
      }
      setState( ConnectionState::Idle );
    }
  } );

  // assume all redirect will never emit "redirected"
  connect( reply, &NetworkReply::redirected, this, [=]() {
    if ( --mPendingRequests == 0 )
    {
      setState( ConnectionState::Idle );
    }
  } );

  return reply;
}

void SmartCloudConnection::setToken( const QByteArray &token )
{
  if ( mToken == token )
    return;

  mToken = token;
  QSettings().setValue( "/SmartCloud/token", token );

  emit tokenChanged();
}

void SmartCloudConnection::invalidateToken()
{
  if ( mToken.isNull() )
    return;

  mToken = QByteArray();
  QSettings().remove( "/SmartCloud/token" );

  emit tokenChanged();
}

void SmartCloudConnection::setStatus( ConnectionStatus status )
{
  if ( mStatus == status )
    return;

  mStatus = status;
  emit statusChanged();
}

void SmartCloudConnection::setState( ConnectionState state )
{
  if ( mState == state )
    return;

  mState = state;
  emit stateChanged();
}

void SmartCloudConnection::setAuthenticationToken( QNetworkRequest &request )
{
  if ( !mToken.isNull() )
  {
    request.setRawHeader( "Authorization", "Token " + mToken );
  }
}

void SmartCloudConnection::setClientHeaders( QNetworkRequest &request )
{
  const QByteArray acceptLanguageHeader( "Accept-Language" );
  if ( !request.hasRawHeader( acceptLanguageHeader ) )
  {
    // the standard requires locales with dash instead of underscore
    request.setRawHeader( acceptLanguageHeader, QLocale::system().name().replace( QStringLiteral( "_" ), QStringLiteral( "-" ) ).toUtf8() );
  }
}

SmartCloudConnection::CloudError::CloudError( QNetworkReply *reply )
{
  if ( !reply )
    return;

  QString errorMessage;

  mError = reply->error();
  mHttpCode = reply->attribute( QNetworkRequest::HttpStatusCodeAttribute ).toInt();

  switch ( mError )
  {
    case QNetworkReply::NoError:
      break;
    case QNetworkReply::TimeoutError:
      errorMessage += tr( "[timeout] The request took too long to finish, please retry." );
      break;
    case QNetworkReply::OperationCanceledError:
      errorMessage += tr( "[aborted] The request has been aborted." );
      break;
    default:
      mPayload = reply->readAll();
      QJsonParseError jsonError;
      mJson = QJsonDocument::fromJson( mPayload.toUtf8(), &jsonError );
      mJsonError = jsonError;

      QJsonObject doc = mJson.object();

      if ( jsonError.error == QJsonParseError::NoError )
      {
        if ( doc.contains( QStringLiteral( "code" ) ) )
        {
          mQfcCode = doc.value( QStringLiteral( "code" ) ).toString();
          errorMessage += QStringLiteral( "[QF/%1] " ).arg( mQfcCode );

          if ( sErrors.contains( mQfcCode ) )
            errorMessage += sErrors.value( mQfcCode );
          else
            errorMessage += doc.value( QStringLiteral( "message" ) ).toString();
        }
        else
          errorMessage += QStringLiteral( "<no server details>" );

        if ( errorMessage.isEmpty() )
          errorMessage += QStringLiteral( "<empty server details>" );
      }
      break;
  }

  errorMessage = QTextDocumentFragment::fromHtml( errorMessage ).toPlainText().trimmed();

  QString httpErrorMessage = QStringLiteral( "[HTTP/%1] %2 " ).arg( mHttpCode ).arg( reply->url().toString() );
  httpErrorMessage += ( mHttpCode >= 400 )
                        ? tr( "Server Error." )
                        : tr( "Network Error." );
  httpErrorMessage += mPayload.left( 200 );
  httpErrorMessage = QTextDocumentFragment::fromHtml( httpErrorMessage ).toPlainText().trimmed();
  QString payloadPlainText = QTextDocumentFragment::fromHtml( mPayload ).toPlainText().trimmed();

  if ( mPayload.size() > 200 )
    errorMessage += QStringLiteral( "…" );

  if ( errorMessage.isEmpty() )
  {
    errorMessage = httpErrorMessage;
    QgsMessageLog::logMessage( QStringLiteral( "%1\n%2\n%3" ).arg( errorMessage, payloadPlainText ).arg( reply->errorString() ) );
  }
  else
  {
    QgsMessageLog::logMessage( QStringLiteral( "%1\n%2\n%3\n%4" ).arg( errorMessage, httpErrorMessage, payloadPlainText ).arg( reply->errorString() ) );
  }

  // strip HTML tags
  errorMessage = QTextDocumentFragment::fromHtml( httpErrorMessage ).toPlainText();

  mMessage = errorMessage;
}

int SmartCloudConnection::uploadPendingAttachments()
{
  if ( mUploadingAttachments )
    return 0;

  QMultiMap<QString, QString> attachments = SmartCloudUtils::getPendingAttachments();
  if ( attachments.isEmpty() )
  {
    emit pendingAttachmentsUploadFinished();
    return 0;
  }

  mUploadCount = attachments.size();
  QMultiMap<QString, QString>::const_iterator it = attachments.constBegin();
  while ( it != attachments.constEnd() )
  {
    if ( !QFileInfo( it.value() ).exists() )
    {
      // A pending attachment has been deleted from the local device, remove
      // This can happen when for e.g. users remove a cloud project from their devices
      SmartCloudUtils::removePendingAttachment( it.key(), it.value() );
      continue;
    }

    QFileInfo projectInfo( SmartCloudUtils::localProjectFilePath( mUsername, it.key() ) );
    QDir projectDir( projectInfo.absolutePath() );
    const QString apiPath = projectDir.relativeFilePath( it.value() );
    NetworkReply *attachmentCloudReply = post( QStringLiteral( "/api/v1/files/%1/%2/" ).arg( it.key(), apiPath ), QVariantMap(), QStringList( { it.value() } ) );

    QString projectId = it.key();
    QString fileName = it.value();
    connect( attachmentCloudReply, &NetworkReply::finished, this, [=]() {
      QNetworkReply *attachmentReply = attachmentCloudReply->reply();
      attachmentCloudReply->deleteLater();

      Q_ASSERT( attachmentCloudReply->isFinished() );
      Q_ASSERT( attachmentReply );

      // if there is an error, don't panic, we continue uploading. The files may be later manually synced.
      if ( attachmentReply->error() != QNetworkReply::NoError )
      {
        QgsMessageLog::logMessage( tr( "Failed to upload attachment stored at `%1`, reason:\n%2" )
                                     .arg( fileName )
                                     .arg( SmartCloudConnection::errorString( attachmentReply ) ) );
      }
      else
      {
        SmartCloudUtils::removePendingAttachment( projectId, fileName );
      }

      mUploadCount--;
      if ( mUploadCount == 0 )
      {
        // Once a batch of uploads has been successfully sent, check for any new attachments that would have been added in the meantime
        uploadPendingAttachments();
      }
    } );

    ++it;
  }
  return mUploadCount;
}

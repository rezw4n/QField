/***************************************************************************
              smartfieldappauthrequesthandler.cpp
              -------------------
              begin                : August 2019
              copyright            : (C) 2019 by David Signer
              email                : david (at) opengis.ch
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "smartfieldappauthrequesthandler.h"

#include <QAuthenticator>
#include <QThread>
#include <qgscredentials.h>
#include <qgsdatasourceuri.h>
#include <qgsmessagelog.h>

SmartFieldAppAuthRequestHandler::SmartFieldAppAuthRequestHandler()
{
  QgsCredentials::setInstance( this );
}

bool SmartFieldAppAuthRequestHandler::request( const QString &realm, QString &username, QString &password, const QString &message )
{
  authNeeded( realm );
  return false;
}

void SmartFieldAppAuthRequestHandler::enterCredentials( const QString &realm, const QString &username, const QString &password )
{
  QgsCredentials::instance()->put( realm, username, password );
}

QString SmartFieldAppAuthRequestHandler::getFirstUnhandledRealm() const
{
  auto entry = std::find_if( mRealms.begin(), mRealms.end(), []( const RealmEntry &entry ) { return !entry.canceled; } );
  return entry != mRealms.end() ? entry->realm : QString();
}

bool SmartFieldAppAuthRequestHandler::handleLayerLogins()
{
  if ( !getFirstUnhandledRealm().isEmpty() )
  {
    showLogin();
    connect( this, &SmartFieldAppAuthRequestHandler::loginDialogClosed, [=]( const QString &realm, bool canceled ) {
      if ( canceled )
      {
        //realm not successful handled - but canceled
        for ( int i = 0; i < mRealms.count(); i++ )
        {
          if ( mRealms.at( i ).realm == realm )
          {
            mRealms.replace( i, RealmEntry( realm, true ) );
            break;
          }
        }
      }
      else
      {
        //realm successful handled (credentials saved) - remove realm
        for ( int i = 0; i < mRealms.count(); i++ )
        {
          if ( mRealms.at( i ).realm == realm )
          {
            mRealms.removeAt( i );
            break;
          }
        }
      }

      if ( !getFirstUnhandledRealm().isEmpty() )
      {
        //show dialog as long as there are unhandled realms
        showLogin();
      }
      else
      {
        emit reloadEverything();
      }
    } );
  }
  else
  {
    return false;
  }
  return true;
}

void SmartFieldAppAuthRequestHandler::clearStoredRealms()
{
  mRealms.clear();
}

void SmartFieldAppAuthRequestHandler::showLogin()
{
  QString realm = getFirstUnhandledRealm();
  QString title = getCredentialTitle( realm );
  emit showLoginDialog( realm, title );
}

void SmartFieldAppAuthRequestHandler::authNeeded( const QString &realm )
{
  if ( std::any_of( mRealms.begin(), mRealms.end(), [&realm]( const RealmEntry &entry ) { return entry.realm == realm; } ) )
  {
    //realm already in list
    return;
  }

  RealmEntry unhandledRealm( realm );
  mRealms << unhandledRealm;
}

void SmartFieldAppAuthRequestHandler::handleAuthRequest( QNetworkReply *reply, QAuthenticator *auth )
{
  Q_ASSERT( qApp->thread() == QThread::currentThread() );

  QString username = auth->user();
  QString password = auth->password();

  if ( username.isEmpty() && password.isEmpty() && reply->request().hasRawHeader( "Authorization" ) )
  {
    QByteArray header( reply->request().rawHeader( "Authorization" ) );
    if ( header.startsWith( "Basic " ) )
    {
      QByteArray authorization( QByteArray::fromBase64( header.mid( 6 ) ) );
      int pos = authorization.indexOf( ':' );
      if ( pos >= 0 )
      {
        username = authorization.left( pos );
        password = authorization.mid( pos + 1 );
      }
    }
  }

  for ( ;; )
  {
    bool ok = QgsCredentials::instance()->get(
      QStringLiteral( "%1 at %2" ).arg( auth->realm(), reply->url().host() ),
      username, password,
      QObject::tr( "Authentication required" ) );

    if ( !ok )
    {
      authNeeded( QStringLiteral( "%1 at %2" ).arg( auth->realm(), reply->url().host() ) );
      return;
    }

    if ( auth->user() != username || ( password != auth->password() && !password.isNull() ) )
    {
      // save credentials
      QgsCredentials::instance()->put(
        QStringLiteral( "%1 at %2" ).arg( auth->realm(), reply->url().host() ),
        username, password );
      break;
    }
    else
    {
      // credentials didn't change - stored ones probably wrong? clear password and retry
      QgsCredentials::instance()->put(
        QStringLiteral( "%1 at %2" ).arg( auth->realm(), reply->url().host() ),
        username, QString() );
    }
  }

  auth->setUser( username );
  auth->setPassword( password );
}

void SmartFieldAppAuthRequestHandler::handleAuthRequestOpenBrowser( const QUrl &url )
{
  emit showLoginBrowser( url.toString() );
}

void SmartFieldAppAuthRequestHandler::handleAuthRequestCloseBrowser()
{
  emit hideLoginBrowser();
}

void SmartFieldAppAuthRequestHandler::abortAuthBrowser()
{
  QgsNetworkAccessManager::instance()->abortAuthBrowser();
}

QString SmartFieldAppAuthRequestHandler::getCredentialTitle( const QString &realm )
{
  QgsDataSourceUri uri = QgsDataSourceUri( realm );

  if ( uri.database().isEmpty() )
    return realm;

  return "Please enter credentials for database <b>" + uri.database() + "</b> at host <b>" + uri.host() + ".</b>";
}

/***************************************************************************
                            androidplatformutilities.cpp  -  utilities for smartfield

                              -------------------
              begin                : February 2016
              copyright            : (C) 2016 by Matthias Kuhn
              email                : matthias@opengis.ch
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "androidplatformutilities.h"
#include "androidprojectsource.h"
#include "androidresourcesource.h"
#include "androidviewstatus.h"
#include "appinterface.h"
#include "fileutils.h"
#include "smartfield.h"
#include "smartfield_android.h"
#include "smartcloudconnection.h"


#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>
#include <QtAndroid>

inline QAndroidJniObject qtAndroidContext()
{
  auto result = QtAndroid::androidActivity();
  if ( result.isValid() )
    return result;
  return QtAndroid::androidService();
}

inline void runOnAndroidMainThread( const QtAndroid::Runnable &runnable )
{
  QtAndroid::runOnAndroidThread( runnable );
}

#else
#include <QJniEnvironment>
#include <QJniObject>
#include <QtCore/private/qandroidextras_p.h>

inline QJniObject qtAndroidContext()
{
  return QJniObject( QCoreApplication::instance()->nativeInterface<QNativeInterface::QAndroidApplication>()->context() );
}

inline void runOnAndroidMainThread( const std::function<void()> &runnable )
{
  QCoreApplication::instance()->nativeInterface<QNativeInterface::QAndroidApplication>()->runOnAndroidMainThread( [runnable]() {
    runnable();
    return QVariant();
  } );
}
#endif

#include <QApplication>
#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMap>
#include <QMimeDatabase>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QScreen>
#include <QSettings>
#include <QStandardPaths>
#include <QString>
#include <QTimer>
#include <qgsfileutils.h>

#include <android/bitmap.h>
#include <android/log.h>
#include <jni.h>

const char *const applicationName = "SmartField";

#define GLUE_HELPER( u, v, w, x, y, z ) u##v##w##x##y##z
#define JNI_FUNCTION_NAME( package_name, class_name, function_name ) GLUE_HELPER( Java_ch_opengis_, package_name, _, class_name, _, function_name )

AndroidPlatformUtilities::AndroidPlatformUtilities()
  : mActivity( qtAndroidContext() )
  , mSystemGenericDataLocation( QStandardPaths::writableLocation( QStandardPaths::AppDataLocation ) + QStringLiteral( "/share" ) )
{
}

PlatformUtilities::Capabilities AndroidPlatformUtilities::capabilities() const
{
  PlatformUtilities::Capabilities capabilities = Capabilities() | NativeCamera | AdjustBrightness | CustomLocalDataPicker | CustomImport | CustomExport | CustomSend | FilePicker | VolumeKeys | UpdateProjectFromArchive;
#ifdef WITH_SENTRY
  capabilities |= SentryFramework;
#endif
  return capabilities;
}

void AndroidPlatformUtilities::afterUpdate()
{
  // Copy data away from the virtual path `assets:/` to a path accessible also for non-qt-based libs

  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject messageJni = QAndroidJniObject::fromString( QObject::tr( "Please wait while SmartField installation finalizes." ) );
#else
        QJniObject messageJni = QJniObject::fromString( QObject::tr( "Please wait while SmartField installation finalizes." ) );
#endif
        activity.callMethod<void>( "showBlockingProgressDialog", "(Ljava/lang/String;)V", messageJni.object<jstring>() );
      }
    } );
  }

  FileUtils::copyRecursively( QStringLiteral( "assets:/" ), mSystemGenericDataLocation );

  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        activity.callMethod<void>( "dismissBlockingProgressDialog" );
      }
    } );
  }
}

QString AndroidPlatformUtilities::systemSharedDataLocation() const
{
  return mSystemGenericDataLocation;
}

bool AndroidPlatformUtilities::hasQgsProject() const
{
  return !getIntentExtra( "QGS_PROJECT" ).isEmpty();
}

void AndroidPlatformUtilities::loadQgsProject() const
{
  if ( mActivity.isValid() && hasQgsProject() )
  {
    runOnAndroidMainThread( [] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        activity.callMethod<void>( "processProjectIntent" );
      }
    } );
  }
}

QStringList AndroidPlatformUtilities::appDataDirs() const
{
  const QString dataDirs = getIntentExtra( "SMARTFIELD_APP_DATA_DIRS" );
  return ( !dataDirs.isEmpty() ? dataDirs.split( "--;--" ) : QStringList() );
}

QString AndroidPlatformUtilities::applicationDirectory() const
{
  if ( mActivity.isValid() )
  {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
    QAndroidJniObject rootDirs = mActivity.callObjectMethod<jstring>( "getApplicationDirectory" );
#else
    QJniObject rootDirs = mActivity.callObjectMethod<jstring>( "getApplicationDirectory" );
#endif
    if ( rootDirs.isValid() )
    {
      return rootDirs.toString();
    }
  }

  return QString();
}

QStringList AndroidPlatformUtilities::additionalApplicationDirectories() const
{
  if ( mActivity.isValid() )
  {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
    QAndroidJniObject rootDirs = mActivity.callObjectMethod<jstring>( "getAdditionalApplicationDirectories" );
#else
    QJniObject rootDirs = mActivity.callObjectMethod<jstring>( "getAdditionalApplicationDirectories" );
#endif
    if ( rootDirs.isValid() )
    {
      return rootDirs.toString().split( "--;--" );
    }
  }

  return QStringList();
}

QStringList AndroidPlatformUtilities::rootDirectories() const
{
  if ( mActivity.isValid() )
  {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
    QAndroidJniObject rootDirs = mActivity.callObjectMethod<jstring>( "getRootDirectories" );
#else
    QJniObject rootDirs = mActivity.callObjectMethod<jstring>( "getRootDirectories" );
#endif
    if ( rootDirs.isValid() )
    {
      return rootDirs.toString().split( "--;--" );
    }
  }

  return QStringList();
}

void AndroidPlatformUtilities::importProjectFolder() const
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        activity.callMethod<void>( "triggerImportProjectFolder" );
      }
    } );
  }
}

void AndroidPlatformUtilities::importProjectArchive() const
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        activity.callMethod<void>( "triggerImportProjectArchive" );
      }
    } );
  }
}

void AndroidPlatformUtilities::importDatasets() const
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        activity.callMethod<void>( "triggerImportDatasets" );
      }
    } );
  }
}

void AndroidPlatformUtilities::updateProjectFromArchive( const QString &projectPath ) const
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [projectPath] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject projectPathJni = QAndroidJniObject::fromString( projectPath );
#else
        QJniObject projectPathJni = QJniObject::fromString( projectPath );
#endif
        activity.callMethod<void>( "triggerUpdateProjectFromArchive", "(Ljava/lang/String;)V", projectPathJni.object<jstring>() );
      }
    } );
  }
}

void AndroidPlatformUtilities::sendDatasetTo( const QString &path ) const
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [path] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        QStringList paths = QStringList() << path;
        const QSet<QString> files = QgsFileUtils::sidecarFilesForPath( path );
        for ( const QString &file : files )
        {
          paths << file;
        }
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject pathsJni = QAndroidJniObject::fromString( paths.join( "--;--" ) );
#else
        QJniObject pathsJni = QJniObject::fromString( paths.join( "--;--" ) );
#endif
        activity.callMethod<void>( "sendDatasetTo", "(Ljava/lang/String;)V", pathsJni.object<jstring>() );
      }
    } );
  }
}

void AndroidPlatformUtilities::exportDatasetTo( const QString &path ) const
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [path] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        QStringList paths = QStringList() << path;
        const QSet<QString> files = QgsFileUtils::sidecarFilesForPath( path );
        for ( const QString &file : files )
        {
          paths << file;
        }
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject pathsJni = QAndroidJniObject::fromString( paths.join( "--;--" ) );
#else
        QJniObject pathsJni = QJniObject::fromString( paths.join( "--;--" ) );
#endif
        activity.callMethod<void>( "exportToFolder", "(Ljava/lang/String;)V", pathsJni.object<jstring>() );
      }
    } );
  }
}

void AndroidPlatformUtilities::removeDataset( const QString &path ) const
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [path] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject pathJni = QAndroidJniObject::fromString( path );
#else
        QJniObject pathJni = QJniObject::fromString( path );
#endif
        activity.callMethod<void>( "removeDataset", "(Ljava/lang/String;)V", pathJni.object<jstring>() );
      }
    } );
  }
}

void AndroidPlatformUtilities::exportFolderTo( const QString &path ) const
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [path] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject pathJni = QAndroidJniObject::fromString( path );
#else
        QJniObject pathJni = QJniObject::fromString( path );
#endif
        activity.callMethod<void>( "exportToFolder", "(Ljava/lang/String;)V", pathJni.object<jstring>() );
      }
    } );
  }
}

void AndroidPlatformUtilities::sendCompressedFolderTo( const QString &path ) const
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [path] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject pathJni = QAndroidJniObject::fromString( path );
#else
        QJniObject pathJni = QJniObject::fromString( path );
#endif
        activity.callMethod<void>( "sendCompressedFolderTo", "(Ljava/lang/String;)V", pathJni.object<jstring>() );
      }
    } );
  }
}

void AndroidPlatformUtilities::removeFolder( const QString &path ) const
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [path] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject pathJni = QAndroidJniObject::fromString( path );
#else
        QJniObject pathJni = QJniObject::fromString( path );
#endif
        activity.callMethod<void>( "removeProjectFolder", "(Ljava/lang/String;)V", pathJni.object<jstring>() );
      }
    } );
  }
}

#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
QString AndroidPlatformUtilities::getIntentExtra( const QString &extra, QAndroidJniObject extras ) const
#else
QString AndroidPlatformUtilities::getIntentExtra( const QString &extra, QJniObject extras ) const
#endif
{
  if ( extras == nullptr )
  {
    extras = getNativeExtras();
  }
  if ( extras.isValid() )
  {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
    QAndroidJniObject extraJni = QAndroidJniObject::fromString( extra );
#else
    QJniObject extraJni = QJniObject::fromString( extra );
#endif
    extraJni = extras.callObjectMethod( "getString", "(Ljava/lang/String;)Ljava/lang/String;", extraJni.object<jstring>() );
    if ( extraJni.isValid() )
    {
      return extraJni.toString();
    }
  }
  return QString();
}

#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
QAndroidJniObject AndroidPlatformUtilities::getNativeIntent() const
{
  if ( mActivity.isValid() )
  {
    QAndroidJniObject intent = mActivity.callObjectMethod( "getIntent", "()Landroid/content/Intent;" );
    return intent;
  }
  return nullptr;
}

QAndroidJniObject AndroidPlatformUtilities::getNativeExtras() const
{
  QAndroidJniObject intent = getNativeIntent();
  if ( intent.isValid() )
  {
    QAndroidJniObject extras = intent.callObjectMethod( "getExtras", "()Landroid/os/Bundle;" );

    return extras;
  }
  return nullptr;
}
#else
QJniObject AndroidPlatformUtilities::getNativeIntent() const
{
  if ( mActivity.isValid() )
  {
    QJniObject intent = mActivity.callObjectMethod( "getIntent", "()Landroid/content/Intent;" );
    return intent;
  }
  return nullptr;
}

QJniObject AndroidPlatformUtilities::getNativeExtras() const
{
  QJniObject intent = getNativeIntent();
  if ( intent.isValid() )
  {
    QJniObject extras = intent.callObjectMethod( "getExtras", "()Landroid/os/Bundle;" );

    return extras;
  }
  return nullptr;
}
#endif

ResourceSource *AndroidPlatformUtilities::processCameraActivity( const QString &prefix, const QString &filePath, const QString &suffix, bool isVideo, QObject *parent )
{
  if ( !checkCameraPermissions() )
    return nullptr;

  const QFileInfo destinationInfo( prefix + filePath );
  const QDir prefixDir( prefix );
  prefixDir.mkpath( destinationInfo.absolutePath() );

  AndroidResourceSource *resourceSource = nullptr;
  if ( mActivity.isValid() )
  {
    resourceSource = new AndroidResourceSource( prefix, parent );

    runOnAndroidMainThread( [prefix, filePath, suffix, isVideo] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject prefixJni = QAndroidJniObject::fromString( prefix );
        QAndroidJniObject filePathJni = QAndroidJniObject::fromString( filePath );
        QAndroidJniObject suffixJni = QAndroidJniObject::fromString( suffix );
#else
        QJniObject prefixJni = QJniObject::fromString( prefix );
        QJniObject filePathJni = QJniObject::fromString( filePath );
        QJniObject suffixJni = QJniObject::fromString( suffix );
#endif
        QSettings().setValue( QStringLiteral( "SmartField/nativeCameraLaunched" ), true );
        activity.callMethod<void>( "getCameraResource", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V",
                                   prefixJni.object<jstring>(),
                                   filePathJni.object<jstring>(),
                                   suffixJni.object<jstring>(),
                                   isVideo );
      }
    } );
  }
  return resourceSource;
}

ResourceSource *AndroidPlatformUtilities::getCameraPicture( const QString &prefix, const QString &pictureFilePath, const QString &suffix, QObject *parent )
{
  return processCameraActivity( prefix, pictureFilePath, suffix, false, parent );
}

ResourceSource *AndroidPlatformUtilities::getCameraVideo( const QString &prefix, const QString &videoFilePath, const QString &suffix, QObject *parent )
{
  return processCameraActivity( prefix, videoFilePath, suffix, true, parent );
}

ResourceSource *AndroidPlatformUtilities::processGalleryActivity( const QString &prefix, const QString &filePath, const QString &mimeType, QObject *parent )
{
  const QFileInfo destinationInfo( prefix + filePath );
  const QDir prefixDir( prefix );
  prefixDir.mkpath( destinationInfo.absolutePath() );

  AndroidResourceSource *resourceSource = nullptr;
  if ( mActivity.isValid() )
  {
    resourceSource = new AndroidResourceSource( prefix, parent );

    runOnAndroidMainThread( [prefix, filePath, mimeType] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject prefixJni = QAndroidJniObject::fromString( prefix );
        QAndroidJniObject filePathJni = QAndroidJniObject::fromString( filePath );
        QAndroidJniObject mimeTypeJni = QAndroidJniObject::fromString( mimeType );
#else
        QJniObject prefixJni = QJniObject::fromString( prefix );
        QJniObject filePathJni = QJniObject::fromString( filePath );
        QJniObject mimeTypeJni = QJniObject::fromString( mimeType );
#endif
        QSettings().setValue( QStringLiteral( "SmartField/nativeCameraLaunched" ), true );
        activity.callMethod<void>( "getGalleryResource", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
                                   prefixJni.object<jstring>(),
                                   filePathJni.object<jstring>(),
                                   mimeTypeJni.object<jstring>() );
      }
    } );
  }
  return resourceSource;
}

ResourceSource *AndroidPlatformUtilities::getGalleryPicture( const QString &prefix, const QString &pictureFilePath, QObject *parent )
{
  return processGalleryActivity( prefix, pictureFilePath, QStringLiteral( "image/*" ), parent );
}

ResourceSource *AndroidPlatformUtilities::getGalleryVideo( const QString &prefix, const QString &videoFilePath, QObject *parent )
{
  return processGalleryActivity( prefix, videoFilePath, QStringLiteral( "video/*" ), parent );
}

ResourceSource *AndroidPlatformUtilities::getFile( const QString &prefix, const QString &filePath, FileType fileType, QObject *parent )
{
  const QFileInfo destinationInfo( prefix + filePath );
  const QDir prefixDir( prefix );
  prefixDir.mkpath( destinationInfo.absolutePath() );

  QString mimeType;
  switch ( fileType )
  {
    case AudioFiles:
      mimeType = "audio/*";
      break;
    case AllFiles:
    default:
      mimeType = "*/*";
      break;
  }

  AndroidResourceSource *resourceSource = nullptr;
  if ( mActivity.isValid() )
  {
    resourceSource = new AndroidResourceSource( prefix, parent );

    runOnAndroidMainThread( [prefix, filePath, mimeType] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject prefixJni = QAndroidJniObject::fromString( prefix );
        QAndroidJniObject filePathJni = QAndroidJniObject::fromString( filePath );
        QAndroidJniObject mimeTypeJni = QAndroidJniObject::fromString( mimeType );
#else
        QJniObject prefixJni = QJniObject::fromString( prefix );
        QJniObject filePathJni = QJniObject::fromString( filePath );
        QJniObject mimeTypeJni = QJniObject::fromString( mimeType );
#endif
        QSettings().setValue( QStringLiteral( "SmartField/nativeCameraLaunched" ), true );
        activity.callMethod<void>( "getFilePickerResource", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
                                   prefixJni.object<jstring>(),
                                   filePathJni.object<jstring>(),
                                   mimeTypeJni.object<jstring>() );
      }
    } );
  }
  return resourceSource;
}

ViewStatus *AndroidPlatformUtilities::open( const QString &filePath, bool isEditing, QObject *parent )
{
  if ( QFileInfo( filePath ).isDir() )
    return nullptr;

  checkWriteExternalStoragePermissions();

  QMimeDatabase db;
  const QString mimeType = db.mimeTypeForFile( filePath ).name();

  AndroidViewStatus *viewStatus = nullptr;
  if ( mActivity.isValid() )
  {
    if ( parent )
    {
      viewStatus = new AndroidViewStatus( parent );
    }

    runOnAndroidMainThread( [filePath, mimeType, isEditing] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject filePathJni = QAndroidJniObject::fromString( filePath );
        QAndroidJniObject mimeTypeJni = QAndroidJniObject::fromString( mimeType );
#else
        QJniObject filePathJni = QJniObject::fromString( filePath );
        QJniObject mimeTypeJni = QJniObject::fromString( mimeType );
#endif
        QSettings().setValue( QStringLiteral( "SmartField/nativeCameraLaunched" ), true );
        activity.callMethod<void>( "openResource", "(Ljava/lang/String;Ljava/lang/String;Z)V",
                                   filePathJni.object<jstring>(),
                                   mimeTypeJni.object<jstring>(),
                                   isEditing );
      }
    } );
  }
  return viewStatus;
}

bool AndroidPlatformUtilities::checkPositioningPermissions() const
{
  // First check for coarse permissions. If the user configured SmartField to only get coarse permissions
  // it's his wish and we just let it be.
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
  QtAndroid::PermissionResult r = QtAndroid::checkPermission( "android.permission.ACCESS_COARSE_LOCATION" );
  if ( r == QtAndroid::PermissionResult::Denied )
#else
  auto r = QtAndroidPrivate::checkPermission( "android.permission.ACCESS_COARSE_LOCATION" ).result();
  if ( r == QtAndroidPrivate::Denied )
#endif
  {
    return checkAndAcquirePermissions( "android.permission.ACCESS_FINE_LOCATION" );
  }
  return true;
}

bool AndroidPlatformUtilities::checkCameraPermissions() const
{
  return checkAndAcquirePermissions( "android.permission.CAMERA" );
}

bool AndroidPlatformUtilities::checkMicrophonePermissions() const
{
  return checkAndAcquirePermissions( "android.permission.RECORD_AUDIO" );
}

bool AndroidPlatformUtilities::checkWriteExternalStoragePermissions() const
{
  return checkAndAcquirePermissions( "android.permission.WRITE_EXTERNAL_STORAGE" );
}

bool AndroidPlatformUtilities::checkAndAcquirePermissions( const QString &permissions ) const
{
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
  QStringList requestedPermissions = permissions.split( ';' );
  requestedPermissions.erase( std::remove_if( requestedPermissions.begin(), requestedPermissions.end(),
                                              []( const QString &permission ) {
                                                return QtAndroid::checkPermission( permission ) != QtAndroid::PermissionResult::Denied;
                                              } ),
                              requestedPermissions.end() );

  if ( !requestedPermissions.isEmpty() )
  {
    QtAndroid::requestPermissionsSync( requestedPermissions );
    for ( const QString &permission : requestedPermissions )
    {
      QtAndroid::PermissionResult r = QtAndroid::checkPermission( permission );
      if ( r == QtAndroid::PermissionResult::Denied )
      {
        return false;
      }
    }
  }

  return true;
#else
  QStringList requestedPermissions = permissions.split( ';' );
  requestedPermissions.erase( std::remove_if( requestedPermissions.begin(), requestedPermissions.end(),
                                              []( const QString &permission ) {
                                                auto r = QtAndroidPrivate::checkPermission( permission ).result();
                                                return r != QtAndroidPrivate::Denied;
                                              } ),
                              requestedPermissions.end() );

  if ( !requestedPermissions.isEmpty() )
  {
    for ( const QString &permission : requestedPermissions )
    {
      auto r = QtAndroidPrivate::requestPermission( permission ).result();
      if ( r == QtAndroidPrivate::Denied )
      {
        return false;
      }
    }
  }

  return true;
#endif
}

void AndroidPlatformUtilities::setScreenLockPermission( const bool allowLock )
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [allowLock] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
        QAndroidJniObject window = activity.callObjectMethod( "getWindow", "()Landroid/view/Window;" );
#else
        QJniObject window = activity.callObjectMethod( "getWindow", "()Landroid/view/Window;" );
#endif

        if ( window.isValid() )
        {
          const int FLAG_KEEP_SCREEN_ON = 128;
          if ( !allowLock )
          {
            window.callMethod<void>( "addFlags", "(I)V", FLAG_KEEP_SCREEN_ON );
          }
          else
          {
            window.callMethod<void>( "clearFlags", "(I)V", FLAG_KEEP_SCREEN_ON );
          }
        }
      }

#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
      QAndroidJniEnvironment env;
#else
      QJniEnvironment env;
#endif
      if ( env->ExceptionCheck() )
      {
        env->ExceptionClear();
      }
    } );
  }
}

void AndroidPlatformUtilities::dimBrightness()
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        activity.callMethod<void>( "dimBrightness" );
      }
    } );
  }
}

void AndroidPlatformUtilities::restoreBrightness()
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        activity.callMethod<void>( "restoreBrightness" );
      }
    } );
  }
}

void AndroidPlatformUtilities::setHandleVolumeKeys( const bool handle )
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [handle] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        activity.callMethod<void>( handle ? "takeVolumeKeys" : "releaseVolumeKeys" );
      }
    } );
  }
}

QVariantMap AndroidPlatformUtilities::sceneMargins( QQuickWindow *window ) const
{
  Q_UNUSED( window )

  double statusBarMargin = std::abs( static_cast<double>( mActivity.callMethod<jdouble>( "statusBarMargin" ) ) );
  double navigationBarMargin = std::abs( static_cast<double>( mActivity.callMethod<jdouble>( "navigationBarMargin" ) ) );

  statusBarMargin /= QGuiApplication::primaryScreen()->devicePixelRatio();
  navigationBarMargin /= QGuiApplication::primaryScreen()->devicePixelRatio();

  QVariantMap margins;
  margins[QLatin1String( "top" )] = statusBarMargin;
  margins[QLatin1String( "right" )] = 0.0;
  margins[QLatin1String( "bottom" )] = navigationBarMargin;
  margins[QLatin1String( "left" )] = 0.0;
  return margins;
}

void AndroidPlatformUtilities::uploadPendingAttachments( SmartCloudConnection *connection ) const
{
  QTimer::singleShot( 500, [connection]() {
    if ( connection )
    {
      qInfo() << "Launching service from main...";
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
      QAndroidJniObject::callStaticMethod<void>( "ch/opengis/" APP_PACKAGE_NAME "/SmartFieldService",
                                                 "startSmartFieldService",
                                                 "(Landroid/content/Context;)V",
                                                 qtAndroidContext().object() );
#else
      QJniObject::callStaticMethod<void>( "ch/opengis/" APP_PACKAGE_NAME "/SmartFieldService",
                                          "startSmartFieldService",
                                          "(Landroid/content/Context;)V",
                                          qtAndroidContext().object() );
#endif
    }
  } );
}

bool AndroidPlatformUtilities::isSystemDarkTheme() const
{
  if ( mActivity.isValid() )
  {
    bool isDarkTheme = mActivity.callMethod<jboolean>( "isDarkTheme" ) == JNI_TRUE;
    return isDarkTheme;
  }
  return false;
}

void AndroidPlatformUtilities::vibrate( int milliseconds ) const
{
  if ( mActivity.isValid() )
  {
    runOnAndroidMainThread( [milliseconds] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        activity.callMethod<void>( "vibrate", "(I)V", milliseconds );
      }
    } );
  }
}

#ifdef __cplusplus
extern "C" {
#endif

// SmartFieldActivity class functions
JNIEXPORT void JNICALL JNI_FUNCTION_NAME( APP_PACKAGE_JNI_NAME, SmartFieldActivity, openProject )( JNIEnv *env, jobject obj, jstring path )
{
  if ( AppInterface::instance() )
  {
    const char *pathStr = env->GetStringUTFChars( path, NULL );
    AppInterface::instance()->loadFile( QString( pathStr ) );
    env->ReleaseStringUTFChars( path, pathStr );
  }
  return;
}

JNIEXPORT void JNICALL JNI_FUNCTION_NAME( APP_PACKAGE_JNI_NAME, SmartFieldActivity, openPath )( JNIEnv *env, jobject obj, jstring path )
{
  if ( AppInterface::instance() )
  {
    const char *pathStr = env->GetStringUTFChars( path, NULL );
    emit AppInterface::instance()->openPath( QString( pathStr ) );
    env->ReleaseStringUTFChars( path, pathStr );
  }
  return;
}

#define ANDROID_VOLUME_DOWN 25
#define ANDROID_VOLUME_UP 24

JNIEXPORT void JNICALL JNI_FUNCTION_NAME( APP_PACKAGE_JNI_NAME, SmartFieldActivity, volumeKeyDown )( JNIEnv *env, jobject obj, int volumeKeyCode )
{
  if ( AppInterface::instance() )
  {
    emit AppInterface::instance()->volumeKeyDown( volumeKeyCode == ANDROID_VOLUME_DOWN ? Qt::Key_VolumeDown : Qt::Key_VolumeUp );
  }
  return;
}

JNIEXPORT void JNICALL JNI_FUNCTION_NAME( APP_PACKAGE_JNI_NAME, SmartFieldActivity, volumeKeyUp )( JNIEnv *env, jobject obj, int volumeKeyCode )
{
  if ( AppInterface::instance() )
  {
    emit AppInterface::instance()->volumeKeyUp( volumeKeyCode == ANDROID_VOLUME_DOWN ? Qt::Key_VolumeDown : Qt::Key_VolumeUp );
  }
  return;
}

JNIEXPORT void JNICALL JNI_FUNCTION_NAME( APP_PACKAGE_JNI_NAME, SmartFieldActivity, resourceReceived )( JNIEnv *env, jobject obj, jstring path )
{
  if ( PlatformUtilities::instance() )
  {
    const char *pathStr = env->GetStringUTFChars( path, NULL );
    emit PlatformUtilities::instance()->resourceReceived( QString( pathStr ) );
    env->ReleaseStringUTFChars( path, pathStr );
  }
  return;
}

JNIEXPORT void JNICALL JNI_FUNCTION_NAME( APP_PACKAGE_JNI_NAME, SmartFieldActivity, resourceOpened )( JNIEnv *env, jobject obj, jstring path )
{
  if ( PlatformUtilities::instance() )
  {
    const char *pathStr = env->GetStringUTFChars( path, NULL );
    emit PlatformUtilities::instance()->resourceOpened( QString( pathStr ) );
    env->ReleaseStringUTFChars( path, pathStr );
  }
  return;
}

JNIEXPORT void JNICALL JNI_FUNCTION_NAME( APP_PACKAGE_JNI_NAME, SmartFieldActivity, resourceCanceled )( JNIEnv *env, jobject obj, jstring message )
{
  if ( PlatformUtilities::instance() )
  {
    const char *messageStr = env->GetStringUTFChars( message, NULL );
    emit PlatformUtilities::instance()->resourceCanceled( QString( messageStr ) );
    env->ReleaseStringUTFChars( message, messageStr );
  }
  return;
}

#ifdef __cplusplus
}
#endif

/***************************************************************************
  smartfieldservice.cpp - SmartFieldService

 ---------------------
 begin                : 04.12.2022
 copyright            : (C) 2022 by Mathieu Pellerin
 email                : mathieu at opengis dot ch
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "smartfield_android.h"
#include "smartcloudconnection.h"
#include "smartfieldservice.h"

#include <QSettings>

SmartFieldService::SmartFieldService( int &argc, char **argv )
  : QAndroidService( argc, argv )
{
  QSettings settings;
  QEventLoop loop( this );
  SmartCloudConnection connection;
  QObject::connect( &connection, &SmartCloudConnection::pendingAttachmentsUploadFinished, &loop, &QEventLoop::quit );
  int pendingAttachments = connection.uploadPendingAttachments();
  if ( pendingAttachments > 0 )
  {
    loop.exec();
  }

#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
  QAndroidJniObject activity = QtAndroid::androidService();
#else
  QJniObject activity = QCoreApplication::instance()->nativeInterface<QNativeInterface::QAndroidApplication>()->context();
#endif
  activity.callMethod<void>( "stopSelf" );

  exit( 0 );
}

SmartFieldService::~SmartFieldService()
{
}

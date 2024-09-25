/***************************************************************************
  sentry_classic.cpp

 ---------------------
 begin                : August 2022
 copyright            : (C) 2022 by Matthias Kuhn, OPENGIS.ch
 email                : matthias@opengis.ch
 ***************************************************************************
 *                                                                         *
 *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
#include "sentry_config.h"
#include "sentry_wrapper.h"

#include <QStandardPaths>
#include <QString>
#include <QtGlobal>

#include <sentry.h>
#ifdef ANDROID
#include <android/log.h>

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
#endif

namespace sentry_wrapper
{
  static QtMessageHandler originalMessageHandler = nullptr;

  static const char *
    logLevelForMessageType( QtMsgType msgType )
  {
    switch ( msgType )
    {
      case QtDebugMsg:
        return "debug";
      case QtWarningMsg:
        return "warning";
      case QtCriticalMsg:
        return "error";
      case QtFatalMsg:
        return "fatal";
      case QtInfoMsg:
        Q_FALLTHROUGH();
      default:
        return "info";
    }
  }

  void qfMessageHandler( QtMsgType type, const QMessageLogContext &context, const QString &msg )
  {
    sentry_value_t crumb
      = sentry_value_new_breadcrumb( "default", qUtf8Printable( msg ) );

    sentry_value_set_by_key(
      crumb, "category", sentry_value_new_string( context.category ) );
    sentry_value_set_by_key(
      crumb, "level", sentry_value_new_string( logLevelForMessageType( type ) ) );

    if ( context.file && !QString( context.file ).isEmpty() )
    {
      sentry_value_t location = sentry_value_new_object();
      sentry_value_set_by_key(
        location, "file", sentry_value_new_string( context.file ) );
      sentry_value_set_by_key(
        location, "line", sentry_value_new_int32( context.line ) );
      sentry_value_set_by_key( crumb, "data", location );
    }

    sentry_add_breadcrumb( crumb );

#if ANDROID
    static const char *const applicationName = "SmartField";
    QString report = msg;
    if ( context.file && !QString( context.file ).isEmpty() )
    {
      report += " in file ";
      report += QString( context.file );
      report += " line ";
      report += QString::number( context.line );
    }

    if ( context.function && !QString( context.function ).isEmpty() )
    {
      report += +" function ";
      report += QString( context.function );
    }

    QByteArray reportLocal8Bit = report.toLocal8Bit();
    reportLocal8Bit.truncate( 4090 );
    const char *const local = reportLocal8Bit.constData();
    switch ( type )
    {
      case QtDebugMsg:
        __android_log_write( ANDROID_LOG_DEBUG, applicationName, local );
        break;
      case QtInfoMsg:
        __android_log_write( ANDROID_LOG_INFO, applicationName, local );
        break;
      case QtWarningMsg:
        __android_log_write( ANDROID_LOG_WARN, applicationName, local );
        break;
      case QtCriticalMsg:
        __android_log_write( ANDROID_LOG_ERROR, applicationName, local );
        break;
      case QtFatalMsg:
      default:
        __android_log_write( ANDROID_LOG_FATAL, applicationName, local );
        abort();
    }
#endif

    if ( originalMessageHandler )
      originalMessageHandler( type, context, msg );
  }

  void install_message_handler()
  {
    originalMessageHandler = qInstallMessageHandler( qfMessageHandler );
  }

  void init()
  {
#if ANDROID
    runOnAndroidMainThread( [] {
      auto activity = qtAndroidContext();
      if ( activity.isValid() )
      {
        activity.callMethod<void>( "initiateSentry" );
      }
    } );
#else
    sentry_options_t *options = sentry_options_new();
    sentry_options_set_dsn( options, sentryDsn );
    sentry_options_set_environment( options, sentryEnv );
    sentry_options_set_debug( options, 1 );
    sentry_options_set_database_path( options, ( QStandardPaths::writableLocation( QStandardPaths::AppDataLocation ) + '/' + QStringLiteral( ".sentry-native" ) ).toUtf8().constData() );
    sentry_init( options );
#endif
  }

  void close()
  {
    sentry_close();
  }

  void capture_event( const char *message, const char *cloudUser )
  {
    sentry_value_t event = sentry_value_new_message_event(
      SENTRY_LEVEL_INFO,
      "custom",
      message );

    sentry_value_t cloud = sentry_value_new_object();
    sentry_value_set_by_key( cloud, "user", sentry_value_new_string( cloudUser ) );
    sentry_value_t contexts = sentry_value_new_object();
    sentry_value_set_by_key( contexts, "cloud", cloud );
    sentry_value_set_by_key( event, "contexts", contexts );

    sentry_capture_event( event );
  }
} // namespace sentry_wrapper

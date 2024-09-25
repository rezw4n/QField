/***************************************************************************
    smartcloudutils.cpp
    ---------------------
    begin                : February 2020
    copyright            : (C) 2020 by Mathieu Pellerin
    email                : nirvn dot asia at gmail dot com
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "platformutilities.h"
#include "smartcloudutils.h"
#include "stringutils.h"

#include <QDir>
#include <QFile>
#include <QLockFile>
#include <QStandardPaths>
#include <QString>
#include <qgsapplication.h>
#include <qgsmessagelog.h>

static QString sLocalCloudDirectory;


void SmartCloudUtils::setLocalCloudDirectory( const QString &path )
{
  sLocalCloudDirectory = path;
}

const QString SmartCloudUtils::localCloudDirectory()
{
  QString cloudDirectoryPath = sLocalCloudDirectory.isNull()
                                 ? PlatformUtilities::instance()->systemLocalDataLocation( QStringLiteral( "cloud_projects" ) )
                                 : sLocalCloudDirectory;
  return cloudDirectoryPath;
}

const QString SmartCloudUtils::localProjectFilePath( const QString &username, const QString &projectId )
{
  QString project = QStringLiteral( "%1/%2/%3" ).arg( SmartCloudUtils::localCloudDirectory(), username, projectId );
  QDir projectDir( project );
  QStringList projectFiles = projectDir.entryList( QStringList() << QStringLiteral( "*.qgz" ) << QStringLiteral( "*.qgs" ) );
  if ( projectFiles.count() > 0 )
  {
    return QStringLiteral( "%1/%2" ).arg( project, projectFiles.at( 0 ) );
  }
  return QString();
}

bool SmartCloudUtils::isCloudAction( const QgsMapLayer *layer )
{
  Q_ASSERT( layer );

  const QString layerAction( layer->customProperty( QStringLiteral( "SmartFieldSync/cloud_action" ) ).toString().toUpper() );

  if ( layerAction == QStringLiteral( "NO_ACTION" ) || layerAction == QStringLiteral( "REMOVE" ) )
    return false;
  return true;
}

const QString SmartCloudUtils::getProjectId( const QString &fileName )
{
  QFileInfo fi( fileName );
  QDir baseDir = fi.isDir() ? fi.canonicalFilePath() : fi.canonicalPath();
  QString basePath = QFileInfo( baseDir.path() ).canonicalFilePath();
  QString cloudPath = QFileInfo( localCloudDirectory() ).canonicalFilePath();

  if ( !cloudPath.isEmpty() && basePath.startsWith( cloudPath ) )
    return baseDir.dirName();

  return QString();
}

void SmartCloudUtils::setProjectSetting( const QString &projectId, const QString &setting, const QVariant &value )
{
  thread_local QgsSettings settings;
  const QString projectPrefix = QStringLiteral( "SmartCloud/projects/%1" ).arg( projectId );
  settings.setValue( QStringLiteral( "%1/%2" ).arg( projectPrefix, setting ), value );
}

const QVariant SmartCloudUtils::projectSetting( const QString &projectId, const QString &setting, const QVariant &defaultValue )
{
  thread_local QgsSettings settings;
  const QString projectPrefix = QStringLiteral( "SmartCloud/projects/%1" ).arg( projectId );
  return settings.value( QStringLiteral( "%1/%2" ).arg( projectPrefix, setting ), defaultValue );
}

const QMultiMap<QString, QString> SmartCloudUtils::getPendingAttachments()
{
  QMultiMap<QString, QString> files;

  QLockFile attachmentsLock( QStringLiteral( "%1/attachments.lock" ).arg( SmartCloudUtils::localCloudDirectory() ) );
  if ( attachmentsLock.tryLock( 10000 ) )
  {
    QFile attachmentsFile( QStringLiteral( "%1/attachments.csv" ).arg( SmartCloudUtils::localCloudDirectory() ) );
    QFileInfo fi( attachmentsFile );
    if ( !fi.exists() || fi.size() == 0 )
      return std::move( files );

    attachmentsFile.open( QFile::ReadWrite | QFile::Text );
    QTextStream attachmentsStream( &attachmentsFile );
    while ( !attachmentsStream.atEnd() )
    {
      const QString line = attachmentsStream.readLine().trimmed();
      const QStringList values = StringUtils::csvToStringList( line );

      // The expected CSV format must have two columns:
      // project_id,file_path
      if ( values.size() >= 2 )
      {
        files.insert( values.at( 0 ), values.at( 1 ) );
      }
    }
  }
  return std::move( files );
}

void SmartCloudUtils::addPendingAttachment( const QString &projectId, const QString &fileName )
{
  QLockFile attachmentsLock( QStringLiteral( "%1/attachments.lock" ).arg( SmartCloudUtils::localCloudDirectory() ) );
  if ( attachmentsLock.tryLock( 10000 ) )
  {
    QStringList values = QStringList() << projectId << fileName;

    QFile attachmentsFile( QStringLiteral( "%1/attachments.csv" ).arg( SmartCloudUtils::localCloudDirectory() ) );
    attachmentsFile.open( QFile::Append | QFile::Text );
    QTextStream attachmentsStream( &attachmentsFile );
    QFileInfo fi( attachmentsFile );
    attachmentsStream << StringUtils::stringListToCsv( values )
                      << Qt::endl;
    attachmentsFile.close();
  }
}

void SmartCloudUtils::removePendingAttachment( const QString &projectId, const QString &fileName )
{
  QLockFile attachmentsLock( QStringLiteral( "%1/attachments.lock" ).arg( SmartCloudUtils::localCloudDirectory() ) );
  if ( attachmentsLock.tryLock( 10000 ) )
  {
    const QString lineToRemove = StringUtils::stringListToCsv( QStringList() << projectId << fileName );
    QString output;
    QFile attachmentsFile( QStringLiteral( "%1/attachments.csv" ).arg( SmartCloudUtils::localCloudDirectory() ) );
    attachmentsFile.open( QFile::ReadWrite | QFile::Text );
    QTextStream attachmentsStream( &attachmentsFile );
    while ( !attachmentsStream.atEnd() )
    {
      const QString line = attachmentsStream.readLine();
      if ( !line.isEmpty() && !line.startsWith( lineToRemove ) )
      {
        output += line + QChar( '\n' );
      }
    }
    attachmentsFile.resize( 0 );
    attachmentsStream.reset();
    attachmentsStream << output;
    attachmentsFile.close();
  }
}

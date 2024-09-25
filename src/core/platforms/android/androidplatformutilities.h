/***************************************************************************
                            androidplatformutilities.h  -  utilities for smartfield

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

#ifndef ANDROIDPLATFORMUTILITIES_H
#define ANDROIDPLATFORMUTILITIES_H

#include "platformutilities.h"

#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
#include <QAndroidJniObject>
#else
#include <QJniObject>
#endif

class AndroidPlatformUtilities : public PlatformUtilities
{
  public:
    AndroidPlatformUtilities();

    PlatformUtilities::Capabilities capabilities() const override;
    void afterUpdate() override;
    QString systemSharedDataLocation() const override;

    bool hasQgsProject() const override;
    void loadQgsProject() const override;

    QStringList appDataDirs() const override;
    QString applicationDirectory() const override;
    QStringList additionalApplicationDirectories() const override;
    QStringList rootDirectories() const override;

    void importProjectFolder() const override;
    void importProjectArchive() const override;
    void importDatasets() const override;

    void updateProjectFromArchive( const QString &projectPath ) const override;

    void sendDatasetTo( const QString &path ) const override;
    void exportDatasetTo( const QString &path ) const override;
    void removeDataset( const QString &path ) const override;

    void exportFolderTo( const QString &path ) const override;
    void sendCompressedFolderTo( const QString &path ) const override;
    void removeFolder( const QString &path ) const override;

    ResourceSource *getCameraPicture( const QString &prefix, const QString &pictureFilePath, const QString &suffix, QObject *parent = nullptr ) override;
    ResourceSource *getCameraVideo( const QString &prefix, const QString &videoFilePath, const QString &suffix, QObject *parent = nullptr ) override;
    ResourceSource *getGalleryPicture( const QString &prefix, const QString &pictureFilePath, QObject *parent = nullptr ) override;
    ResourceSource *getGalleryVideo( const QString &prefix, const QString &videoFilePath, QObject *parent = nullptr ) override;
    ResourceSource *getFile( const QString &prefix, const QString &filePath, FileType fileType, QObject *parent = nullptr ) override;

    ViewStatus *open( const QString &filePath, bool isEditing, QObject *parent = nullptr ) override;

    bool checkPositioningPermissions() const override;
    bool checkCameraPermissions() const override;
    bool checkMicrophonePermissions() const override;
    bool checkWriteExternalStoragePermissions() const override;

    void setScreenLockPermission( const bool allowLock ) override;

    void dimBrightness() override;
    void restoreBrightness() override;

    void setHandleVolumeKeys( const bool handle ) override;

    QVariantMap sceneMargins( QQuickWindow *window ) const override;

    double systemFontPointSize() const override { return 16.0; }

    void uploadPendingAttachments( SmartCloudConnection *connection ) const override;

    bool isSystemDarkTheme() const override;

    void vibrate( int milliseconds ) const override;

  private:
    // separate multiple permissions using a semi-column (;)
    bool checkAndAcquirePermissions( const QString &permissions ) const;
    ResourceSource *processCameraActivity( const QString &prefix, const QString &filePath, const QString &suffix, bool isVideo, QObject *parent = nullptr );
    ResourceSource *processGalleryActivity( const QString &prefix, const QString &filePath, const QString &mimeType, QObject *parent = nullptr );
#if QT_VERSION < QT_VERSION_CHECK( 6, 0, 0 )
    QString getIntentExtra( const QString &, QAndroidJniObject = nullptr ) const;
    QAndroidJniObject getNativeIntent() const;
    QAndroidJniObject getNativeExtras() const;
    QAndroidJniObject mActivity;
#else
    QString getIntentExtra( const QString &, QJniObject = nullptr ) const;
    QJniObject getNativeIntent() const;
    QJniObject getNativeExtras() const;
    QJniObject mActivity;
#endif
    QString mSystemGenericDataLocation;
};

#endif // ANDROIDPLATFORMUTILITIES_H

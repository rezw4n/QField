/***************************************************************************
                          qgselevationprofilecanvas.h
                          ---------------
    begin                : October 2022
    copyright            : (C) 2022 by Mathieu Pellerin
    email                : mathieu at opengis dot ch
***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef QGSELEVATIONPROFILECANVAS_H
#define QGSELEVATIONPROFILECANVAS_H

#include "qgscoordinatereferencesystem.h"
#include "qgsgeometry.h"
#include "qgsmaplayer.h"

#include <QQuickItem>

class QgsProfilePlotRenderer;
class QgsElevationProfilePlotItem;

class QgsQuickElevationProfileCanvas : public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY( QgsProject *project READ project WRITE setProject NOTIFY projectChanged )

    Q_PROPERTY( QgsCoordinateReferenceSystem crs READ crs WRITE setCrs NOTIFY crsChanged )
    Q_PROPERTY( QgsGeometry profileCurve READ profileCurve WRITE setProfileCurve NOTIFY profileCurveChanged )
    Q_PROPERTY( double tolerance READ tolerance WRITE setTolerance NOTIFY toleranceChanged )

    Q_PROPERTY( QColor backgroundColor READ backgroundColor WRITE setBackgroundColor NOTIFY backgroundColorChanged )
    Q_PROPERTY( QColor borderColor READ borderColor WRITE setBorderColor NOTIFY borderColorChanged )
    Q_PROPERTY( QColor axisLabelColor READ axisLabelColor WRITE setAxisLabelColor NOTIFY axisLabelColorChanged )
    Q_PROPERTY( double axisLabelSize READ axisLabelSize WRITE setAxisLabelSize NOTIFY axisLabelSizeChanged )

    /**
     * The isRendering property is set to true while a rendering job is pending for this
     * elevation profile canvas. It can be used to show a notification icon about an
     * ongoing rendering job.
     * This is a readonly property.
     */
    Q_PROPERTY( bool isRendering READ isRendering NOTIFY isRenderingChanged )

  public:
    /**
     * Constructor for QgsElevationProfileCanvas, with the specified \a parent widget.
     */
    explicit QgsQuickElevationProfileCanvas( QQuickItem *parent = nullptr );
    ~QgsQuickElevationProfileCanvas();

    QSGNode *updatePaintNode( QSGNode *oldNode, QQuickItem::UpdatePaintNodeData * ) override;

    void cancelJobs();

    //! \copydoc QgsQuickElevationProfileCanvas::isRendering
    bool isRendering() const;

    /**
     * Triggers a complete regeneration of the profile, causing the profile extraction to perform in the
     * background.
     */
    Q_INVOKABLE void refresh();

    /**
     * Returns the project associated with the profile.
     */
    QgsProject *project() const { return mProject; }

    /**
     * Sets the \a project associated with the profile.
     *
     * This must be set before any layers which utilize terrain based elevation settings can be
     * included in the canvas.
     */
    void setProject( QgsProject *project );

    /**
     * Populates the current profile with elevation-enabled layers from the associated project.
     */
    Q_INVOKABLE void populateLayersFromProject();

    /**
     * Returns the list of layers included in the profile.
     *
     * \see layers()
     */
    QList<QgsMapLayer *> layers() const;

    /**
     * Returns the crs associated with map coordinates
     */
    QgsCoordinateReferenceSystem crs() const { return mCrs; }

    /**
     * Sets the \a crs associated with the map coordinates.
     *
     * \see crs()
     */
    void setCrs( const QgsCoordinateReferenceSystem &crs );

    /**
     * Sets the profile \a curve geometry.
     *
     * The CRS associated with \a curve is set via setCrs().
     *
     * \see profileCurve()
     */
    void setProfileCurve( QgsGeometry curve );

    /**
     * Returns the profile curve geometry.
     *
     * The CRS associated with the curve is retrieved via crs().
     *
     * \see setProfileCurve()
     */
    QgsGeometry profileCurve() const { return mProfileCurve; };

    /**
     * Sets the profile tolerance (in crs() units).
     *
     * This value determines how far from the profileCurve() is appropriate for inclusion of results. For instance,
     * when a profile is generated for a point vector layer this tolerance distance will dictate how far from the
     * actual profile curve a point can reside within to be included in the results.
     *
     * \see tolerance()
     */
    void setTolerance( double tolerance );

    /**
     * Returns the tolerance of the profile (in crs() units).
     *
     * This value determines how far from the profileCurve() is appropriate for inclusion of results. For instance,
     * when a profile is generated for a point vector layer this tolerance distance will dictate how far from the
     * actual profile curve a point can reside within to be included in the results.
     *
     * \see setTolerance()
     */
    double tolerance() const { return mTolerance; }

    /**
     * Sets the visible area of the plot.
     *
     * \see visibleDistanceRange()
     * \see visibleElevationRange()
     */
    void setVisiblePlotRange( double minimumDistance, double maximumDistance, double minimumElevation, double maximumElevation );

    /**
     * Returns the distance range currently visible in the plot.
     *
     * \see visibleElevationRange()
     * \see setVisiblePlotRange()
     */
    QgsDoubleRange visibleDistanceRange() const;

    /**
     * Returns the elevation range currently visible in the plot.
     *
     * \see visibleDistanceRange()
     * \see setVisiblePlotRange()
     */
    QgsDoubleRange visibleElevationRange() const;

    /**
     * Returns the background color used when rendering the elevation profile.
     *
     * \see setBackgroundColor
     */
    QColor backgroundColor() const;

    /**
     * Sets the background color used when rendering the elevation profile.
     *
     * \see backgroundColor
     */
    void setBackgroundColor( const QColor &color );

    /**
     * Returns the border color used when rendering the elevation profile.
     *
     * \see setBorderColor
     */
    QColor borderColor() const;

    /**
     * Sets the border color used when rendering the elevation profile.
     *
     * \see borderColor
     */
    void setBorderColor( const QColor &color );

    /**
     * Returns the axis label color used when rendering the elevation profile.
     *
     * \see setAxisLabelColor
     */
    QColor axisLabelColor() const;

    /**
     * Sets the axis label color used when rendering the elevation profile.
     *
     * \see axisLabelColor
     */
    void setAxisLabelColor( const QColor &color );

    /**
     * Returns the axis label size (in point) used when rendering the elevation profile.
     *
     * \see setAxisLabelSize
     */
    double axisLabelSize() const;

    /**
     * Sets the axis label size (in point) used when rendering the elevation profile.
     *
     * \see axisLabelSize
     */
    void setAxisLabelSize( double size );

  signals:

    //! Emitted when the number of active background jobs changes.
    void activeJobCountChanged( int count );

    //! Emitted when the associated project changes.
    void projectChanged();

    //! Emitted when the CRS linked to the profile curve geometry changes.
    void crsChanged();

    //! Emitted when the profile curve geometry changes.
    void profileCurveChanged();

    //! Emitted when the tolerance changes.
    void toleranceChanged();

    //! \copydoc QgsQuickMapCanvasMap::isRendering
    void isRenderingChanged();

    //! Emitted when the background color changes.
    void backgroundColorChanged();

    //! Emitted when the border color changes.
    void borderColorChanged();

    //! Emitted when the axis label color changes.
    void axisLabelColorChanged();

    //! Emitted when the axis label size (in point) changes.
    void axisLabelSizeChanged();

  protected:
    void geometryChange( const QRectF &newGeometry, const QRectF &oldGeometry ) override;

  public slots:

    /**
     * Zooms to the full extent of the profile.
     */
    Q_INVOKABLE void zoomFull();

    /**
     * Zooms to the full extent of the profile while maintaining X and Y axes' length ratio.
     * \note This method only makes sense with CRSes having matching map units and elevation units types.
     */
    Q_INVOKABLE void zoomFullInRatio();

    /**
     * Clears the current profile.
     */
    Q_INVOKABLE void clear();

  private slots:

    void generationFinished();
    void onLayerProfileGenerationPropertyChanged();
    void onLayerProfileRendererPropertyChanged();
    void regenerateResultsForLayer();
    void scheduleDeferredRegeneration();
    void scheduleDeferredRedraw();
    void startDeferredRegeneration();
    void startDeferredRedraw();
    void refineResults();

  private:
    void setupLayerConnections( QgsMapLayer *layer, bool isDisconnect );
    void updateStyle();

    QgsCoordinateReferenceSystem mCrs;
    QgsProject *mProject = nullptr;

    QgsWeakMapLayerPointerList mLayers;

    QImage mImage;

    QgsElevationProfilePlotItem *mPlotItem = nullptr;
    QgsProfilePlotRenderer *mCurrentJob = nullptr;

    QTimer *mDeferredRegenerationTimer = nullptr;
    bool mDeferredRegenerationScheduled = false;
    QTimer *mDeferredRedrawTimer = nullptr;
    bool mDeferredRedrawScheduled = false;

    QgsGeometry mProfileCurve;
    double mTolerance = 0;

    bool mFirstDrawOccurred = false;

    bool mZoomFullWhenJobFinished = true;

    bool mForceRegenerationAfterCurrentJobCompletes = false;

    static constexpr double MAX_ERROR_PIXELS = 2;

    bool mDirty = false;

    QColor mBackgroundColor = QColor( 255, 255, 255 );
    QColor mBorderColor = QColor( 0, 0, 0 );
    QColor mAxisLabelColor = QColor( 0, 0, 0 );
    double mAxisLabelSize = 16;
};

#endif // QGSELEVATIONPROFILECANVAS_H

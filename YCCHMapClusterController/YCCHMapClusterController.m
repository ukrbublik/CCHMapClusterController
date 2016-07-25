//
//  YCCHMapClusterController.m
//  YCCHMapClusterController
//
//  Copyright (C) 2013 Claus Höfele
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

// Based on https://github.com/MarcoSero/MSMapClustering by MarcoSero/WWDC 2011

#import "YCCHMapClusterController.h"

#import "YCCHMapClusterControllerDebugPolygon.h"
#import "YCCHMapClusterControllerUtils.h"
#import "YCCHMapClusterAnnotation.h"
#import "YCCHMapClusterControllerDelegate.h"
#import "YCCHMapViewDelegateProxy.h"
#import "YCCHCenterOfMassMapClusterer.h"
#import "YCCHFadeInOutMapAnimator.h"
#import "YCCHMapClusterOperation.h"
#import "YCCHMapTree.h"

#define NODE_CAPACITY 10
#define WORLD_MIN_LAT -85
#define WORLD_MAX_LAT 85
#define WORLD_MIN_LON -180
#define WORLD_MAX_LON 180

#define fequal(a, b) (fabs((a) - (b)) < __FLT_EPSILON__)

@interface YCCHMapClusterController()<YMKMapViewDelegate>

@property (nonatomic) NSMutableSet *allAnnotations;
@property (nonatomic) YCCHMapTree *allAnnotationsMapTree;
@property (nonatomic) YCCHMapTree *visibleAnnotationsMapTree;
@property (nonatomic) NSOperationQueue *backgroundQueue;
@property (nonatomic) YMKMapView *mapView;
@property (nonatomic) YCCHMapViewDelegateProxy *mapViewDelegateProxy;
@property (nonatomic) id<MKAnnotation> annotationToSelect;
@property (nonatomic) YCCHMapClusterAnnotation *mapClusterAnnotationToSelect;
@property (nonatomic) MKCoordinateSpan regionSpanBeforeChange;
@property (nonatomic, getter = isRegionChanging) BOOL regionChanging;
@property (nonatomic) id<YCCHMapClusterer> strongClusterer;
@property (nonatomic) id<YCCHMapAnimator> strongAnimator;

@end

@implementation YCCHMapClusterController

- (instancetype)initWithMapView:(YMKMapView *)mapView
{
    self = [super init];
    if (self) {
        _marginFactor = 0.5;
        _cellSize = 60;
        _maxZoomLevelForClustering = DBL_MAX;
        _mapView = mapView;
        _allAnnotations = [NSMutableSet new];
        _allAnnotationsMapTree = [[YCCHMapTree alloc] initWithNodeCapacity:NODE_CAPACITY minLatitude:WORLD_MIN_LAT maxLatitude:WORLD_MAX_LAT minLongitude:WORLD_MIN_LON maxLongitude:WORLD_MAX_LON];
        _visibleAnnotationsMapTree = [[YCCHMapTree alloc] initWithNodeCapacity:NODE_CAPACITY minLatitude:WORLD_MIN_LAT maxLatitude:WORLD_MAX_LAT minLongitude:WORLD_MIN_LON maxLongitude:WORLD_MAX_LON];
        _backgroundQueue = [[NSOperationQueue alloc] init];
        _backgroundQueue.maxConcurrentOperationCount = 1;   // sync access to allAnnotationsMapTree & visibleAnnotationsMapTree
        
        if ([mapView.delegate isKindOfClass:YCCHMapViewDelegateProxy.class]) {
            YCCHMapViewDelegateProxy *delegateProxy = (YCCHMapViewDelegateProxy *)mapView.delegate;
            [delegateProxy addDelegate:self];
            _mapViewDelegateProxy = delegateProxy;
        } else {
            _mapViewDelegateProxy = [[YCCHMapViewDelegateProxy alloc] initWithMapView:mapView delegate:self];
        }
        
        // Keep strong reference to default instance because public property is weak
        id<YCCHMapClusterer> clusterer = [[YCCHCenterOfMassMapClusterer alloc] init];
        _clusterer = clusterer;
        _strongClusterer = clusterer;
        id<YCCHMapAnimator> animator = [[YCCHFadeInOutMapAnimator alloc] init];
        _animator = animator;
        _strongAnimator = animator;
        
        [self setReuseExistingClusterAnnotations:YES];
    }
    
    return self;
}

- (NSSet *)annotations
{
    return self.allAnnotations.copy;
}

- (void)setClusterer:(id<YCCHMapClusterer>)clusterer
{
    _clusterer = clusterer;
    self.strongClusterer = nil;
}

- (void)setAnimator:(id<YCCHMapAnimator>)animator
{
    _animator = animator;
    self.strongAnimator = nil;
}

- (double)zoomLevel
{
    MKCoordinateRegion region = YMKRegionToMK(self.mapView.region);
    return YCCHMapClusterControllerZoomLevelForRegion(region.center.longitude, region.span.longitudeDelta, self.mapView.bounds.size.width);
}

- (void)cancelAllClusterOperations
{
    NSOperationQueue *backgroundQueue = self.backgroundQueue;
    for (NSOperation *operation in backgroundQueue.operations) {
        if ([operation isKindOfClass:YCCHMapClusterOperation.class]) {
            [operation cancel];
        }
    }
}

- (void)addAnnotations:(NSArray *)annotations withCompletionHandler:(void (^)())completionHandler
{
    [self cancelAllClusterOperations];
    
    [self.allAnnotations addObjectsFromArray:annotations];
    
    [self.backgroundQueue addOperationWithBlock:^{
        BOOL updated = [self.allAnnotationsMapTree addAnnotations:annotations];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (updated && !self.isRegionChanging) {
                [self updateAnnotationsWithCompletionHandler:completionHandler];
            } else if (completionHandler) {
                completionHandler();
            }
        });
    }];
}

- (void)removeAnnotations:(NSArray *)annotations withCompletionHandler:(void (^)())completionHandler
{
    [self cancelAllClusterOperations];
    
    [self.allAnnotations minusSet:[NSSet setWithArray:annotations]];
    
    [self.backgroundQueue addOperationWithBlock:^{
        BOOL updated = [self.allAnnotationsMapTree removeAnnotations:annotations];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (updated && !self.isRegionChanging) {
                [self updateAnnotationsWithCompletionHandler:completionHandler];
            } else if (completionHandler) {
                completionHandler();
            }
        });
    }];
}

- (void)updateAnnotationsWithCompletionHandler:(void (^)())completionHandler
{
    [self cancelAllClusterOperations];
    
    YCCHMapClusterOperation *operation = [[YCCHMapClusterOperation alloc] initWithMapView:self.mapView
                                                                               cellSize:self.cellSize
                                                                           marginFactor:self.marginFactor
                                                        reuseExistingClusterAnnotations:self.reuseExistingClusterAnnotations
                                                              maxZoomLevelForClustering:self.maxZoomLevelForClustering
                                                        minUniqueLocationsForClustering:self.minUniqueLocationsForClustering];
    operation.allAnnotationsMapTree = self.allAnnotationsMapTree;
    operation.visibleAnnotationsMapTree = self.visibleAnnotationsMapTree;
    operation.clusterer = self.clusterer;
    operation.animator = self.animator;
    operation.clusterControllerDelegate = self.delegate;
    operation.clusterController = self;
    
    if (completionHandler) {
        operation.completionBlock = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler();
            });
        };
    };
    
    [self.backgroundQueue addOperation:operation];
    
    // Debugging
    if (self.isDebuggingEnabled) {
        double cellMapSize = [YCCHMapClusterOperation cellMapSizeForCellSize:self.cellSize withMapView:self.mapView];
        MKMapRect gridMapRect = [YCCHMapClusterOperation gridMapRectForMapRect:self.mapView.visibleMapRect withCellMapSize:cellMapSize marginFactor:self.marginFactor];
        [self updateDebugPolygonsInGridMapRect:gridMapRect withCellMapSize:cellMapSize];
    }
}

- (void)updateDebugPolygonsInGridMapRect:(MKMapRect)gridMapRect withCellMapSize:(double)cellMapSize
{
    /*
    YMKMapView *mapView = self.mapView;
     
    // Remove old polygons
    for (id<MKOverlay> overlay in mapView.overlays) {
        if ([overlay isKindOfClass:YCCHMapClusterControllerDebugPolygon.class]) {
            YCCHMapClusterControllerDebugPolygon *debugPolygon = (YCCHMapClusterControllerDebugPolygon *)overlay;
            if (debugPolygon.mapClusterController == self) {
                [mapView removeOverlay:overlay];
            }
        }
    }
    
    // Add polygons outlining each cell
    YCCHMapClusterControllerEnumerateCells(gridMapRect, cellMapSize, ^(MKMapRect cellMapRect) {
        //        cellMapRect.origin.x -= MKMapSizeWorld.width;  // fixes issue when view port spans 180th meridian
        
        MKMapPoint points[4];
        points[0] = MKMapPointMake(MKMapRectGetMinX(cellMapRect), MKMapRectGetMinY(cellMapRect));
        points[1] = MKMapPointMake(MKMapRectGetMaxX(cellMapRect), MKMapRectGetMinY(cellMapRect));
        points[2] = MKMapPointMake(MKMapRectGetMaxX(cellMapRect), MKMapRectGetMaxY(cellMapRect));
        points[3] = MKMapPointMake(MKMapRectGetMinX(cellMapRect), MKMapRectGetMaxY(cellMapRect));
        YCCHMapClusterControllerDebugPolygon *debugPolygon = (YCCHMapClusterControllerDebugPolygon *)[YCCHMapClusterControllerDebugPolygon polygonWithPoints:points count:4];
        debugPolygon.mapClusterController = self;
        [mapView addOverlay:debugPolygon];
    });
    */
}

- (void)deselectAllAnnotations
{
    [self.mapView setSelectedAnnotation:nil];
}

- (void)selectAnnotation:(id<MKAnnotation>)annotation andZoomToRegionWithLatitudinalMeters:(CLLocationDistance)latitudinalMeters longitudinalMeters:(CLLocationDistance)longitudinalMeters
{
    // Check for valid annotation
    BOOL existingAnnotation = [self.annotations containsObject:annotation];
    NSAssert(existingAnnotation, @"Invalid annotation - can only select annotations previously added by calling addAnnotations:withCompletionHandler:");
    if (!existingAnnotation) {
        return;
    }
    
    // Deselect annotations
    [self deselectAllAnnotations];
    
    // Zoom to annotation
    self.annotationToSelect = annotation;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, latitudinalMeters, longitudinalMeters);
    [self.mapView setRegion:YMKRegionFromMK(region) animated:YES];
    if (YCCHMapClusterControllerCoordinateEqualToCoordinate(region.center, self.mapView.centerCoordinate)) {
        // Manually call update methods because region won't change
        [self mapView:self.mapView regionWillChangeAnimated:YES];
        [self mapView:self.mapView regionDidChangeAnimated:YES];
    }
}

#pragma mark - Map view proxied delegate methods

- (void)mapView:(YMKMapView *)mapView didAddAnnotationViews:(NSArray *)annotationViews
{
    // Animate annotations that get added
    [self.animator mapClusterController:self didAddAnnotationViews:annotationViews];
}

- (void)mapView:(YMKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    self.regionSpanBeforeChange = YMKRegionSizeToMK(mapView.region.span);
    self.regionChanging = YES;
}

- (void)mapView:(YMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    self.regionChanging = NO;
    
    // Deselect all annotations when zooming in/out. Longitude delta will not change
    // unless zoom changes (in contrast to latitude delta).
    BOOL hasZoomed = !fequal(mapView.region.span.longitudeDelta, self.regionSpanBeforeChange.longitudeDelta);
    if (hasZoomed) {
        [self deselectAllAnnotations];
    }
    
    // Update annotations
    [self updateAnnotationsWithCompletionHandler:^{
        if (self.annotationToSelect) {
            // Map has zoomed to selected annotation; search for cluster annotation that contains this annotation
            YCCHMapClusterAnnotation *mapClusterAnnotation = YCCHMapClusterControllerClusterAnnotationForAnnotation(self.mapView, self.annotationToSelect, mapView.visibleMapRect);
            self.annotationToSelect = nil;
            
            if (YCCHMapClusterControllerCoordinateEqualToCoordinate(self.mapView.centerCoordinate, mapClusterAnnotation.coordinate)) {
                // Select immediately since region won't change
                [self.mapView setSelectedAnnotation:mapClusterAnnotation];
            } else {
                // Actual selection happens in next call to mapView:regionDidChangeAnimated:
                self.mapClusterAnnotationToSelect = mapClusterAnnotation;
                
                // Dispatch async to avoid calling regionDidChangeAnimated immediately
                dispatch_async(dispatch_get_main_queue(), ^{
                    // No zooming, only panning. Otherwise, annotation might change to a different cluster annotation
                    [self.mapView setCenterCoordinate:mapClusterAnnotation.coordinate animated:NO];
                });
            }
        } else if (self.mapClusterAnnotationToSelect) {
            // Map has zoomed to annotation
            [self.mapView setSelectedAnnotation:self.mapClusterAnnotationToSelect];
            self.mapClusterAnnotationToSelect = nil;
        }
    }];
}

@end

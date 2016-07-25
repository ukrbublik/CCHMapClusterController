//
//  YCCHMapClusterControllerUtils.h
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

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "YandexMapKit.h"
#import "YMKMapView+Additions.h"

@class YCCHMapClusterAnnotation;
@class YCCHMapClusterController;

MKMapRect YCCHMapClusterControllerAlignMapRectToCellSize(MKMapRect mapRect, double cellSize);
YCCHMapClusterAnnotation *YCCHMapClusterControllerFindVisibleAnnotation(NSSet *annotations, NSSet *visibleAnnotations);
#if TARGET_OS_IPHONE
double YCCHMapClusterControllerMapLengthForLength(YMKMapView *mapView, UIView *view, double length);
#else
double YCCHMapClusterControllerMapLengthForLength(YMKMapView *mapView, NSView *view, double length);
#endif
double YCCHMapClusterControllerAlignMapLengthToWorldWidth(double mapLength);
BOOL YCCHMapClusterControllerCoordinateEqualToCoordinate(CLLocationCoordinate2D coordinate0, CLLocationCoordinate2D coordinate1);
YCCHMapClusterAnnotation *YCCHMapClusterControllerClusterAnnotationForAnnotation(YMKMapView *mapView, id<MKAnnotation> annotation, MKMapRect mapRect);
void YCCHMapClusterControllerEnumerateCells(MKMapRect mapRect, double cellSize, void (^block)(MKMapRect cellMapRect));
MKMapRect YCCHMapClusterControllerMapRectForCoordinateRegion(MKCoordinateRegion coordinateRegion);
NSSet *YCCHMapClusterControllerClusterAnnotationsForAnnotations(NSArray *annotations, YCCHMapClusterController *mapClusterController);
double YCCHMapClusterControllerZoomLevelForRegion(CLLocationDegrees longitudeCenter, CLLocationDegrees longitudeDelta, CGFloat width);
NSArray *YCCHMapClusterControllerAnnotationSetsByUniqueLocations(NSSet *annotations, NSUInteger maxUniqueLocations);
BOOL YCCHMapClusterControllerIsUniqueLocation(NSSet *annotations);
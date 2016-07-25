//
//  YMKMapView+Additions.h
//  Mskobr
//
//  Created by ukrbublik on 25.07.16.
//  Copyright © 2016. All rights reserved.
//

#import "YandexMapKit.h"
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

MKCoordinateRegion YMKRegionToMK(YMKMapRegion region);
YMKMapRegion YMKRegionFromMK(MKCoordinateRegion region);
MKCoordinateSpan YMKRegionSizeToMK(YMKMapRegionSize size);
MKMapRect YMKMapRectToMK(YMKMapRect r);
YMKMapRect YMKMapRectFromMK(MKMapRect rect);

@interface YMKMapView (Additions)

-(MKMapRect)visibleMapRect;
- (CLLocationCoordinate2D)convertPoint:(CGPoint)point
                  toCoordinateFromView:(UIView *)view;
-(NSSet*)annotationsInMapRect:(MKMapRect)rect;

@end

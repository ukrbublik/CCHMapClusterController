//
//  YMKMapView+Additions.m
//  Mskobr
//
//  Created by ukrbublik on 25.07.16.
//  Copyright © 2016. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMKMapView+Additions.h"

@implementation YMKMapView (Additions)

-(MKMapRect)visibleMapRect {
    YMKMapRect r = YMKMapRectFromMapRegion(self.region);
    MKMapRect ret = YMKMapRectToMK(r);
    return ret;
}

- (CLLocationCoordinate2D)convertPoint:(CGPoint)point
                  toCoordinateFromView:(UIView *)view {
    CLLocationCoordinate2D coord = [self convertMapViewPointToLL:point];
    return coord;
}

MKCoordinateRegion YMKRegionToMK(YMKMapRegion r) {
    MKCoordinateRegion ret;
    ret.center = r.center;
    ret.span.latitudeDelta = r.span.latitudeDelta;
    ret.span.longitudeDelta = r.span.longitudeDelta;
    return ret;
}

YMKMapRegion YMKRegionFromMK(MKCoordinateRegion r) {
    YMKMapRegion ret;
    ret.center = r.center;
    ret.span.latitudeDelta = r.span.latitudeDelta;
    ret.span.longitudeDelta = r.span.longitudeDelta;
    return ret;
}


MKCoordinateSpan YMKRegionSizeToMK(YMKMapRegionSize size) {
    MKCoordinateSpan span;
    span.latitudeDelta = size.latitudeDelta;
    span.longitudeDelta = size.longitudeDelta;
    return span;
}

YMKMapRect YMKMapRectFromMK(MKMapRect rect) {
    YMKMapRect ret;
    CLLocationCoordinate2D tl = MKCoordinateForMapPoint(MKMapPointMake(rect.origin.x, rect.origin.y));
    CLLocationCoordinate2D br = MKCoordinateForMapPoint(MKMapPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height));
    ret = YMKMapRectMake(tl, br);
    return ret;
}

MKMapRect YMKMapRectToMK(YMKMapRect r) {
    MKMapRect ret;
    MKMapPoint tl = MKMapPointForCoordinate(r.topLeft);
    MKMapPoint br = MKMapPointForCoordinate(r.bottomRight);
    ret = MKMapRectMake(fmin(tl.x,br.x), fmin(tl.y,br.y), fabs(tl.x-br.x), fabs(tl.y-br.y));
    return ret;
}

-(NSArray*)annotationsInMapRect:(MKMapRect)rect {
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    for(id<YMKAnnotation> ann in self.annotations) {
        CLLocationCoordinate2D coord = ann.coordinate;
        BOOL isVis = YMKMapRegionContainsMapCoordinate(self.region, coord);
        if(isVis)
            [arr addObject:ann];
    }
    return arr;
}

@end

//
//  YMKMapView+Additions.m
//  Mskobr
//
//  Created by ukrbublik on 25.07.16.
//  Copyright © 2016. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMKMapView+Additions.h"
#import <objc/runtime.h>

@implementation YMKMapView (Additions)

#pragma mark - Internal views: YXScrollView, YMKMapOverlayView
- (UIScrollView<UIScrollViewDelegate>*)xScrollView {
    return objc_getAssociatedObject(self, @selector(xScrollView));
}
- (void)setXScrollView:(UIScrollView<UIScrollViewDelegate>*)xScrollView_ {
    objc_setAssociatedObject(self, @selector(xScrollView), xScrollView_, OBJC_ASSOCIATION_ASSIGN);
}

- (UIScrollView<UIScrollViewDelegate>*)mapOverlayView {
    return objc_getAssociatedObject(self, @selector(mapOverlayView));
}
- (void)setMapOverlayView:(UIScrollView<UIScrollViewDelegate>*)mapOverlayView_ {
    objc_setAssociatedObject(self, @selector(mapOverlayView), mapOverlayView_, OBJC_ASSOCIATION_ASSIGN);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self findYXScrollView];
}

-(void)findYXScrollView {
    if(!self.xScrollView) {
        for(UIView* v in self.subviews) {
            if([NSStringFromClass(v.class) isEqualToString:@"YXScrollView"]) {
                self.xScrollView = (UIScrollView<UIScrollViewDelegate>*) v;
                [self findYMKMapOverlayView];
                break;
            }
        }
    }
}

-(void)findYMKMapOverlayView {
    if(!self.mapOverlayView && self.xScrollView) {
        for(UIView* v in self.xScrollView.subviews) {
            if([NSStringFromClass(v.class) isEqualToString:@"YMKMapOverlayView"]) {
                self.mapOverlayView = (UIView*) v;
                break;
            }
        }
    }
}

#pragma mark - Adding and Inserting Overlays
- (NSArray<id<MKOverlay>>*)overlays {
    return objc_getAssociatedObject(self, @selector(overlays));
}
- (void)setOverlays:(NSArray<id<MKOverlay>>*)overlays_ {
    objc_setAssociatedObject(self, @selector(overlays), overlays_, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)addOverlay:(id<MKOverlay>)overlay {
    //todo
}

#pragma mark - Compatibility with MKMapKit
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

-(NSSet*)annotationsInMapRect:(MKMapRect)rect {
    NSMutableSet* arr = [[NSMutableSet alloc] init];
    for(id<YMKAnnotation> ann in self.annotations) {
        CLLocationCoordinate2D coord = ann.coordinate;
        BOOL isVis = YMKMapRegionContainsMapCoordinate(self.region, coord);
        if(isVis)
            [arr addObject:ann];
    }
    return arr;
}

@end

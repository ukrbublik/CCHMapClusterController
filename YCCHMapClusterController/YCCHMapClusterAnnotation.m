//
//  YCCHMapClusterAnnotation.m
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

#import "YCCHMapClusterAnnotation.h"

#import "YCCHMapClusterControllerDelegate.h"
#import "YCCHMapClusterControllerUtils.h"

@implementation YCCHMapClusterAnnotation

- (NSString *)title
{
    if (_title == nil && [self.delegate respondsToSelector:@selector(mapClusterController:titleForMapClusterAnnotation:)]) {
        _title = [self.delegate mapClusterController:self.mapClusterController titleForMapClusterAnnotation:self];
    } else if(_title == nil && !self.isCluster) {
        _title = self.oneAnnotation.title;
    }

    return _title;
}

- (NSString *)subtitle
{
    if (_subtitle == nil && [self.delegate respondsToSelector:@selector(mapClusterController:subtitleForMapClusterAnnotation:)]) {
        _subtitle = [self.delegate mapClusterController:self.mapClusterController subtitleForMapClusterAnnotation:self];
    } else if(_title == nil && !self.isCluster) {
        _subtitle = self.oneAnnotation.subtitle;
    }
    
    return _subtitle;
}

- (BOOL)isCluster
{
    return (self.annotations.count > 1);
}

-(id<YMKAnnotation>)oneAnnotation {
    if(self.isCluster)
        return nil;
    else
        return [self.annotations anyObject];
}

- (BOOL)isUniqueLocation
{
    return YCCHMapClusterControllerIsUniqueLocation(self.annotations);
}

- (BOOL)isOneLocation
{
    return [self isUniqueLocation];
}

- (MKMapRect)mapRect
{
    MKMapPoint clusterPoint = MKMapPointForCoordinate(self.coordinate);
    MKMapRect mapRect = MKMapRectMake(clusterPoint.x, clusterPoint.y, 0.1, 0.1);
    for (id<MKAnnotation> annotation in self.annotations)
    {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        mapRect = MKMapRectUnion(mapRect, pointRect);
    }
    
    return mapRect;
}

@end

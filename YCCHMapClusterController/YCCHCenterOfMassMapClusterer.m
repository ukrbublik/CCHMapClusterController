//
//  YCCHCenterOfMassMapClusterer.m
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

#import "YCCHCenterOfMassMapClusterer.h"
#import "YCCHMapClusterAnnotation.h"

@implementation YCCHCenterOfMassMapClusterer

- (CLLocationCoordinate2D)mapClusterController:(YCCHMapClusterController *)mapClusterController coordinateForAnnotations:(NSSet *)annotations inMapRect:(MKMapRect)mapRect
{
    double latitude = 0, longitude = 0;
    for (id<YMKAnnotation> annotation in annotations) {
        latitude += annotation.coordinate.latitude;
        longitude += annotation.coordinate.longitude;
    }
    
    CLLocationCoordinate2D coordinate;
    if (annotations.count > 0) {
        double count = (double)annotations.count;
        coordinate = CLLocationCoordinate2DMake(latitude / count, longitude / count);
    } else {
        coordinate = CLLocationCoordinate2DMake(0, 0);
    }
    
    return coordinate;
}

-(MKCoordinateRegion)regionForAnnotations:(NSSet *)annotations {
    MKCoordinateRegion ret;
    if(annotations.count) {
        double minLatitude = 1000, minLongitude = 1000, maxLatitude = -1000, maxLongitude = -1000;
        for (id<YMKAnnotation> annotation in annotations) {
            minLatitude = MIN(minLatitude, annotation.coordinate.latitude);
            minLongitude = MIN(minLongitude, annotation.coordinate.longitude);
            maxLatitude = MAX(maxLatitude, annotation.coordinate.latitude);
            maxLongitude = MAX(maxLongitude, annotation.coordinate.longitude);
        }
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(minLatitude + (maxLatitude - minLatitude) / 2, minLongitude + (maxLongitude - minLongitude) / 2);
        MKCoordinateSpan span = MKCoordinateSpanMake((maxLatitude - minLatitude) * 1.2, (maxLongitude - minLongitude) * 1.2);
        ret = MKCoordinateRegionMake(center, span);
    }
    return ret;
}

@end

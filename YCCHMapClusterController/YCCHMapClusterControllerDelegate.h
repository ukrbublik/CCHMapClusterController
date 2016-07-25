//
//  YCCHMapClusterControllerDelegate.h
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

@class YCCHMapClusterController;
@class YCCHMapClusterAnnotation;

/**
 Protocol to configure custom titles and subtitles for cluster annotations.
 */
@protocol YCCHMapClusterControllerDelegate <NSObject>

@optional

/**
 Returns the title for a cluster annotation.
 @param mapClusterController The cluster controller sending the message.
 @param mapClusterAnnotation The cluster annotation.
 */
- (NSString *)mapClusterController:(YCCHMapClusterController *)mapClusterController titleForMapClusterAnnotation:(YCCHMapClusterAnnotation *)mapClusterAnnotation;

/**
 Returns the subtitle for a cluster annotation.
 @param mapClusterController The cluster controller sending the message.
 @param mapClusterAnnotation The cluster annotation.
 */
- (NSString *)mapClusterController:(YCCHMapClusterController *)mapClusterController subtitleForMapClusterAnnotation:(YCCHMapClusterAnnotation *)mapClusterAnnotation;

/**
 Called before the given cluster annotation is reused for a cell.
 @param mapClusterController The cluster controller sending the message.
 @param mapClusterAnnotation The cluster annotation that's reused. Its properties are updated to reflect the current state.
 */
- (void)mapClusterController:(YCCHMapClusterController *)mapClusterController willReuseMapClusterAnnotation:(YCCHMapClusterAnnotation *)mapClusterAnnotation;

@end

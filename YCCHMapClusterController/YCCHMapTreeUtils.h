//
//  YCCHMapTreeUtils.h
//  YCCHMapClusterController
//
//  Copyright (C) 2013 Theodore Calmes
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

@interface YCCHMapTreeUnsafeMutableArray : NSObject

@property (nonatomic, assign, readonly) id __unsafe_unretained *objects;
@property (nonatomic, readonly) NSUInteger numObjects;

- (instancetype)initWithCapacity:(NSUInteger)capacity;
- (void)addObject:(__unsafe_unretained id)object;

@end

typedef struct YCCHMapTreeNodeData {
    double x, y;
    void *data;
} YCCHMapTreeNodeData;
NS_INLINE YCCHMapTreeNodeData YCCHMapTreeNodeDataMake(double x, double y, void *data) {
    return (YCCHMapTreeNodeData){x, y, data};
}

typedef struct YCCHMapTreeBoundingBox {
    double x0, y0, xf, yf;
} YCCHMapTreeBoundingBox;
NS_INLINE YCCHMapTreeBoundingBox YCCHMapTreeBoundingBoxMake(double x0, double y0, double xf, double yf) {
    return (YCCHMapTreeBoundingBox){x0, y0, xf, yf};
}

typedef struct YCCHMapTreeNode {
    YCCHMapTreeBoundingBox boundingBox;
    struct YCCHMapTreeNode *northWest;
    struct YCCHMapTreeNode *northEast;
    struct YCCHMapTreeNode *southWest;
    struct YCCHMapTreeNode *southEast;
    YCCHMapTreeNodeData *points;
    unsigned long count;
} YCCHMapTreeNode;
YCCHMapTreeNode *YCCHMapTreeNodeMake(YCCHMapTreeBoundingBox boundary, unsigned long bucketCapacity);
void YCCHMapTreeFreeQuadTreeNode(YCCHMapTreeNode *node);

typedef void(^YCCHMapTreeTraverseBlock)(YCCHMapTreeNode *currentNode);
void YCCHMapTreeTraverse(YCCHMapTreeNode *node, YCCHMapTreeTraverseBlock block);

typedef void(^YTBDataReturnBlock)(YCCHMapTreeNodeData data);
void YCCHMapTreeGatherDataInRange(YCCHMapTreeNode *node, YCCHMapTreeBoundingBox range, YTBDataReturnBlock block);
void YCCHMapTreeGatherDataInRange2(YCCHMapTreeNode *node, YCCHMapTreeBoundingBox range, __unsafe_unretained NSMutableSet *annotations);
void YCCHMapTreeGatherDataInRange3(YCCHMapTreeNode *node, YCCHMapTreeBoundingBox range, __unsafe_unretained YCCHMapTreeUnsafeMutableArray *annotations);

YCCHMapTreeNode *YCCHMapTreeBuildWithData(YCCHMapTreeNodeData *data, unsigned long count, YCCHMapTreeBoundingBox boundingBox, unsigned long bucketCapacity);
bool YCCHMapTreeNodeInsertData(YCCHMapTreeNode* node, YCCHMapTreeNodeData data, unsigned long bucketCapacity);
bool YCCHMapTreeNodeRemoveData(YCCHMapTreeNode* node, YCCHMapTreeNodeData data); // only removes first matching item
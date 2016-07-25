//
//  YCCHMapTreeUtils.m
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

#import "YCCHMapTreeUtils.h"

#pragma mark - Unsafe Mutable Array

@interface YCCHMapTreeUnsafeMutableArray()

@property (nonatomic, assign) id __unsafe_unretained *objects;
@property (nonatomic) NSUInteger numObjects;
@property (nonatomic) NSUInteger capacity;

@end

@implementation YCCHMapTreeUnsafeMutableArray

- (instancetype)initWithCapacity:(NSUInteger)capacity
{
    self = [super init];
    if (self) {
        _objects = (__unsafe_unretained id *)malloc(capacity * sizeof(id));
        _numObjects = 0;
        _capacity = capacity ? capacity : 1;
    }
    return self;
}

- (void)dealloc
{
    free(_objects);
}

- (void)addObject:(__unsafe_unretained id)object
{
    if (_numObjects >= _capacity) {
        _capacity *= 2;
        _objects = (__unsafe_unretained id *)realloc(_objects, _capacity * sizeof(id));
    }
    _objects[_numObjects++] = object;
}

@end

#pragma mark - Constructors

YCCHMapTreeNode *YCCHMapTreeNodeMake(YCCHMapTreeBoundingBox boundary, unsigned long bucketCapacity)
{
    YCCHMapTreeNode* node = malloc(sizeof(YCCHMapTreeNode));
    node->northWest = NULL;
    node->northEast = NULL;
    node->southWest = NULL;
    node->southEast = NULL;

    node->boundingBox = boundary;
    node->count = 0;
    node->points = malloc(sizeof(YCCHMapTreeNodeData) * bucketCapacity);

    return node;
}

#pragma mark - Bounding Box Functions

static inline bool YCCHMapTreeBoundingBoxContainsData(YCCHMapTreeBoundingBox box, YCCHMapTreeNodeData data)
{
    return (box.x0 <= data.x && data.x <= box.xf && box.y0 <= data.y && data.y <= box.yf);
}

static inline bool YCCHMapTreeBoundingBoxIntersectsBoundingBox(YCCHMapTreeBoundingBox b1, YCCHMapTreeBoundingBox b2)
{
    return (b1.x0 <= b2.xf && b1.xf >= b2.x0 && b1.y0 <= b2.yf && b1.yf >= b2.y0);
}

#pragma mark - Quad Tree Functions

void YCCHMapTreeNodeSubdivide(YCCHMapTreeNode *node, unsigned long bucketCapacity)
{
    YCCHMapTreeBoundingBox box = node->boundingBox;

    double xMid = (box.xf + box.x0) / 2.0;
    double yMid = (box.yf + box.y0) / 2.0;

    YCCHMapTreeBoundingBox northWest = YCCHMapTreeBoundingBoxMake(box.x0, box.y0, xMid, yMid);
    node->northWest = YCCHMapTreeNodeMake(northWest, bucketCapacity);

    YCCHMapTreeBoundingBox northEast = YCCHMapTreeBoundingBoxMake(xMid, box.y0, box.xf, yMid);
    node->northEast = YCCHMapTreeNodeMake(northEast, bucketCapacity);

    YCCHMapTreeBoundingBox southWest = YCCHMapTreeBoundingBoxMake(box.x0, yMid, xMid, box.yf);
    node->southWest = YCCHMapTreeNodeMake(southWest, bucketCapacity);

    YCCHMapTreeBoundingBox southEast = YCCHMapTreeBoundingBoxMake(xMid, yMid, box.xf, box.yf);
    node->southEast = YCCHMapTreeNodeMake(southEast, bucketCapacity);
}

YCCHMapTreeNode *YCCHMapTreeBuildWithData(YCCHMapTreeNodeData *data, unsigned long count, YCCHMapTreeBoundingBox boundingBox, unsigned long bucketCapacity)
{
    YCCHMapTreeNode *root = YCCHMapTreeNodeMake(boundingBox, bucketCapacity);
    for (unsigned long i = 0; i < count; i++) {
        YCCHMapTreeNodeInsertData(root, data[i], bucketCapacity);
    }
    
    return root;
}

bool YCCHMapTreeNodeInsertData(YCCHMapTreeNode *node, YCCHMapTreeNodeData data, unsigned long bucketCapacity)
{
    if (!YCCHMapTreeBoundingBoxContainsData(node->boundingBox, data)) {
        return false;
    }

    if (node->count < bucketCapacity) {
        node->points[node->count++] = data;
        return true;
    }

    if (node->northWest == NULL) {
        YCCHMapTreeNodeSubdivide(node, bucketCapacity);
    }

    if (YCCHMapTreeNodeInsertData(node->northWest, data, bucketCapacity)) return true;
    if (YCCHMapTreeNodeInsertData(node->northEast, data, bucketCapacity)) return true;
    if (YCCHMapTreeNodeInsertData(node->southWest, data, bucketCapacity)) return true;
    if (YCCHMapTreeNodeInsertData(node->southEast, data, bucketCapacity)) return true;

    return false;
}

bool YCCHMapTreeNodeRemoveData(YCCHMapTreeNode *node, YCCHMapTreeNodeData data)
{
    if (!YCCHMapTreeBoundingBoxContainsData(node->boundingBox, data)) {
        return false;
    }
    
    for (unsigned long i = 0; i < node->count; i++) {
        YCCHMapTreeNodeData *nodeData = &node->points[i];
        if (nodeData->data == data.data) {
            node->points[i] = node->points[node->count - 1];
            node->count--;
            return true;
        }
    }
    
    if (node->northWest == NULL) {
        return false;
    }
    
    if (YCCHMapTreeNodeRemoveData(node->northWest, data)) return true;
    if (YCCHMapTreeNodeRemoveData(node->northEast, data)) return true;
    if (YCCHMapTreeNodeRemoveData(node->southWest, data)) return true;
    if (YCCHMapTreeNodeRemoveData(node->southEast, data)) return true;
    
    return false;
}

void YCCHMapTreeGatherDataInRange(YCCHMapTreeNode *node, YCCHMapTreeBoundingBox range, YTBDataReturnBlock block)
{
    if (!YCCHMapTreeBoundingBoxIntersectsBoundingBox(node->boundingBox, range)) {
        return;
    }

    for (unsigned long i = 0; i < node->count; i++) {
        if (YCCHMapTreeBoundingBoxContainsData(range, node->points[i])) {
            block(node->points[i]);
        }
    }

    if (node->northWest == NULL) {
        return;
    }

    YCCHMapTreeGatherDataInRange(node->northWest, range, block);
    YCCHMapTreeGatherDataInRange(node->northEast, range, block);
    YCCHMapTreeGatherDataInRange(node->southWest, range, block);
    YCCHMapTreeGatherDataInRange(node->southEast, range, block);
}

void YCCHMapTreeGatherDataInRange2(YCCHMapTreeNode *node, YCCHMapTreeBoundingBox range, __unsafe_unretained NSMutableSet *annotations)
{
    if (!YCCHMapTreeBoundingBoxIntersectsBoundingBox(node->boundingBox, range)) {
        return;
    }
    
    for (unsigned long i = 0; i < node->count; i++) {
        if (YCCHMapTreeBoundingBoxContainsData(range, node->points[i])) {
            [annotations addObject:(__bridge id)node->points[i].data];
        }
    }
    
    if (node->northWest == NULL) {
        return;
    }
    
    YCCHMapTreeGatherDataInRange2(node->northWest, range, annotations);
    YCCHMapTreeGatherDataInRange2(node->northEast, range, annotations);
    YCCHMapTreeGatherDataInRange2(node->southWest, range, annotations);
    YCCHMapTreeGatherDataInRange2(node->southEast, range, annotations);
}

void YCCHMapTreeGatherDataInRange3(YCCHMapTreeNode *node, YCCHMapTreeBoundingBox range, __unsafe_unretained YCCHMapTreeUnsafeMutableArray *annotations)
{
    if (!YCCHMapTreeBoundingBoxIntersectsBoundingBox(node->boundingBox, range)) {
        return;
    }

    for (unsigned long i = 0; i < node->count; i++) {
        if (YCCHMapTreeBoundingBoxContainsData(range, node->points[i])) {
            [annotations addObject:(__bridge id)node->points[i].data];
        }
    }

    if (node->northWest == NULL) {
        return;
    }

    YCCHMapTreeGatherDataInRange3(node->northWest, range, annotations);
    YCCHMapTreeGatherDataInRange3(node->northEast, range, annotations);
    YCCHMapTreeGatherDataInRange3(node->southWest, range, annotations);
    YCCHMapTreeGatherDataInRange3(node->southEast, range, annotations);
}

void YCCHMapTreeTraverse(YCCHMapTreeNode *node, YCCHMapTreeTraverseBlock block)
{
    block(node);

    if (node->northWest == NULL) {
        return;
    }

    YCCHMapTreeTraverse(node->northWest, block);
    YCCHMapTreeTraverse(node->northEast, block);
    YCCHMapTreeTraverse(node->southWest, block);
    YCCHMapTreeTraverse(node->southEast, block);
}

void YCCHMapTreeFreeQuadTreeNode(YCCHMapTreeNode *node)
{
    if (node->northWest != NULL) YCCHMapTreeFreeQuadTreeNode(node->northWest);
    if (node->northEast != NULL) YCCHMapTreeFreeQuadTreeNode(node->northEast);
    if (node->southWest != NULL) YCCHMapTreeFreeQuadTreeNode(node->southWest);
    if (node->southEast != NULL) YCCHMapTreeFreeQuadTreeNode(node->southEast);

    free(node->points);
    free(node);
}

//
//  DelaunayTriangle.h
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/17/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DelaunayPoint;
@class DelaunayEdge;
@class DelaunayTriangulation;

@interface DelaunayTriangle : NSObject

@property (nonatomic, readonly) NSArray *edges;
@property (nonatomic, weak) DelaunayPoint *startPoint;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, readonly) NSArray *points;

+ (DelaunayTriangle *) triangleWithEdges:(NSArray *)edges andStartPoint:(DelaunayPoint *)startPoint andColor:(UIColor *)color;
- (BOOL)containsPoint:(DelaunayPoint *)point;
- (CGPoint)circumcenter;
- (BOOL)inFrameTriangleOfTriangulation:(DelaunayTriangulation *)triangulation;
- (void)remove;
- (void)drawInContext:(CGContextRef)ctx;
- (NSSet *)neighbors;
- (DelaunayPoint *)pointNotInEdge:(DelaunayEdge *)edge;
- (DelaunayEdge *)edgeStartingWithPoint:(DelaunayPoint *)point;
- (DelaunayEdge *)edgeEndingWithPoint:(DelaunayPoint *)point;
- (DelaunayPoint *)startPointOfEdge:(DelaunayEdge *)edgeInQuestion;
- (DelaunayPoint *)endPointOfEdge:(DelaunayEdge *)edgeInQuestion;

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

- (void)print;

@end

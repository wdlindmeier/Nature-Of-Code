//
//  DelaunayTriangulation+NOCHelpers.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/27/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "DelaunayTriangulation+NOCHelpers.h"
#import "Edgy.h"

@implementation DelaunayTriangulation (NOCHelpers)

// A triangulation centered on a -1..1,1..-1 gl grid
+ (DelaunayTriangulation*)triangulationWithGLSize:(CGSize)size
{
    
    float width = size.width;
    float height = size.height;
    float halfWidth = width * 0.5;
    float halfHeight = height * 0.5;
    
    DelaunayTriangulation *triangulation = [[DelaunayTriangulation alloc] init];
    
    DelaunayPoint *p0 = [DelaunayPoint pointAtX:0 andY:halfHeight*3];
    DelaunayPoint *p3 = [DelaunayPoint pointAtX:halfWidth*-3.0f andY:halfHeight*-3];
    DelaunayPoint *p5 = [DelaunayPoint pointAtX:halfWidth*3.0f andY:halfHeight*-3];
    
    DelaunayPoint *pf0 = [DelaunayPoint pointAtX:halfWidth*-1.0f andY:halfHeight];
    DelaunayPoint *pf1 = [DelaunayPoint pointAtX:halfWidth andY:halfHeight];
    DelaunayPoint *pf2 = [DelaunayPoint pointAtX:halfWidth andY:halfHeight*-1.0f];
    DelaunayPoint *pf3 = [DelaunayPoint pointAtX:halfWidth*-1.0f andY:halfHeight*-1.0f];
    
    DelaunayEdge *e1 = [DelaunayEdge edgeWithPoints:@[p0, p5]];
    DelaunayEdge *e2 = [DelaunayEdge edgeWithPoints:@[p5, p3]];
    DelaunayEdge *e3 = [DelaunayEdge edgeWithPoints:@[p3, p0]];
    
    DelaunayTriangle *triangle = [DelaunayTriangle triangleWithEdges:@[e1, e2, e3]
                                                       andStartPoint:p0
                                                            andColor:nil];
    
    triangulation.frameTrianglePoints = [NSSet setWithObjects:p0, p5, p3, nil];
    
    // How much of this is actually needed?
    triangulation.triangles = [NSMutableSet setWithObjects:triangle, nil];
    triangulation.edges = [NSMutableSet setWithObjects:e1, e2, e3, nil];
    triangulation.points = [NSMutableSet setWithObjects:p0, p5, p3, nil];
    
    // Now lets add a couple of points to create the view squre
    [triangulation addPoint:pf0
                   withColor:nil];
    [triangulation addPoint:pf1
                   withColor:nil];
    [triangulation addPoint:pf2
                   withColor:nil];
    [triangulation addPoint:pf3
                   withColor:nil];
    
    return triangulation;
}

@end

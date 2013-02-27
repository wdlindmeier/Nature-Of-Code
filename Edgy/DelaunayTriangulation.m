//
//  DelaunayTriangulation.m
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/17/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "DelaunayTriangulation.h"
#import "DelaunayPoint.h"
#import "DelaunayEdge.h"
#import "DelaunayTriangle.h"
#import "VoronoiCell.h"

@interface DelaunayTriangulation ()

- (void)removeTriangle:(DelaunayTriangle *)triangle;

@end

@implementation DelaunayTriangulation
@synthesize points;
@synthesize edges;
@synthesize triangles;
@synthesize frameTrianglePoints;

+ (DelaunayTriangulation *)triangulation
{
    return [DelaunayTriangulation triangulationWithSize:CGSizeMake(20000, 20000)];
}

+ (DelaunayTriangulation *)triangulationWithSize:(CGSize)size
{
    return [DelaunayTriangulation triangulationWithRect:CGRectMake(0, 0, size.width, size.height)];
}

+ (DelaunayTriangulation *)triangulationWithRect:(CGRect)rect
{
    DelaunayTriangulation *dt = [[self alloc] init];
    
    // ADD FRAME TRIANGLE
    float w = rect.size.width;
    float h = rect.size.height;
    float x = rect.origin.x;
    float y = rect.origin.y;

    DelaunayPoint *p1 = [DelaunayPoint pointAtX:x andY:y];
    DelaunayPoint *p2 = [DelaunayPoint pointAtX:x andY:h * 2];
    DelaunayPoint *p3 = [DelaunayPoint pointAtX:w * 2 andY:y];

    DelaunayEdge *e1 = [DelaunayEdge edgeWithPoints:[NSArray arrayWithObjects:p1, p2, nil]];
    DelaunayEdge *e2 = [DelaunayEdge edgeWithPoints:[NSArray arrayWithObjects:p2, p3, nil]];
    DelaunayEdge *e3 = [DelaunayEdge edgeWithPoints:[NSArray arrayWithObjects:p3, p1, nil]];
    
    DelaunayTriangle *triangle = [DelaunayTriangle triangleWithEdges:[NSArray arrayWithObjects:e1, e2, e3, nil] andStartPoint:p1 andColor:nil];
    dt.frameTrianglePoints = [NSSet setWithObjects:p1, p2, p3, nil];
    
    dt.triangles = [NSMutableSet setWithObject:triangle];
    dt.edges = [NSMutableSet setWithObjects:e1, e2, e3, nil];
    dt.points = [NSMutableSet setWithObjects:p1, p2, p3, nil];
    
    return dt;
}

- (id)copyWithZone:(NSZone *)zone
{
    DelaunayTriangulation *dt = [[DelaunayTriangulation alloc] init];
    
    NSMutableSet *triangleCopies = [NSMutableSet setWithCapacity: [self.triangles count]];
    NSMutableSet *edgeCopies = [NSMutableSet setWithCapacity: [self.edges count]];
    NSMutableSet *pointCopies = [NSMutableSet setWithCapacity: [self.points count]];
    
    for (DelaunayPoint *point in self.points)
    {
        [pointCopies addObject:[point copy]];
    }
    
    for (DelaunayEdge *edge in self.edges)
    {
        DelaunayPoint *p1 = [pointCopies member:[edge.points objectAtIndex:0]];
        DelaunayPoint *p2 = [pointCopies member:[edge.points objectAtIndex:1]];
        [edgeCopies addObject:[DelaunayEdge edgeWithPoints:[NSArray arrayWithObjects:p1, p2, nil]]];
    }
    
    for (DelaunayTriangle *triangle in self.triangles)
    {
        DelaunayEdge *e1 = [edgeCopies member:[triangle.edges objectAtIndex:0]];
        DelaunayEdge *e2 = [edgeCopies member:[triangle.edges objectAtIndex:1]];
        DelaunayEdge *e3 = [edgeCopies member:[triangle.edges objectAtIndex:2]];
        DelaunayTriangle *triangleCopy = [DelaunayTriangle triangleWithEdges:[NSArray arrayWithObjects:e1, e2, e3, nil] andStartPoint:[pointCopies member:triangle.startPoint] andColor:triangle.color];
        [triangleCopies addObject:triangleCopy];
    }

    dt.triangles = triangleCopies;
    dt.edges = edgeCopies;
    dt.points = pointCopies;
    NSMutableSet *frameTrianglePointsCopy = [NSMutableSet setWithCapacity:3];
    for ( DelaunayPoint *frameTrianglePoint in self.frameTrianglePoints )
    {
        [frameTrianglePointsCopy addObject:[pointCopies member:frameTrianglePoint]];
    }
    dt.frameTrianglePoints = frameTrianglePointsCopy;
    
    return dt;
}

- (void)print
{
    for (DelaunayTriangle *triangle in self.triangles)
    {
        [triangle print];
        NSLog(@"---");
    }
}

- (void)removeTriangle:(DelaunayTriangle *)triangle
{
    [triangle remove];
    [self.triangles removeObject:triangle];
}

- (BOOL)addPoint:(DelaunayPoint *)newPoint withColor:(UIColor *)color
{
    // TODO(mrotondo): Mirror the points into the 8 surrounding regions to fix up interpolation around the edges.
    DelaunayTriangle * triangle = [self triangleContainingPoint:newPoint];
    if (triangle != nil)
    {
        
        [self.points addObject:newPoint];
        
        [self removeTriangle:triangle];
        
        DelaunayEdge *e1 = [triangle.edges objectAtIndex:0];
        DelaunayEdge *e2 = [triangle.edges objectAtIndex:1];
        DelaunayEdge *e3 = [triangle.edges objectAtIndex:2];

        DelaunayPoint *edgeStartPoint = triangle.startPoint;
        DelaunayEdge *new1 = [DelaunayEdge edgeWithPoints:[NSArray arrayWithObjects:edgeStartPoint, newPoint, nil]];
        edgeStartPoint = [e1 otherPoint:edgeStartPoint];
        DelaunayEdge *new2 = [DelaunayEdge edgeWithPoints:[NSArray arrayWithObjects:edgeStartPoint, newPoint, nil]];
        edgeStartPoint = [e2 otherPoint:edgeStartPoint];
        DelaunayEdge *new3 = [DelaunayEdge edgeWithPoints:[NSArray arrayWithObjects:edgeStartPoint, newPoint, nil]];
        
        [self.edges addObject:new1];
        [self.edges addObject:new2];
        [self.edges addObject:new3];
        
        // Use start point and counter-clockwise ordered edges to enforce counter-clockwiseness in point-containment checking
        DelaunayTriangle * e1Triangle = [DelaunayTriangle triangleWithEdges:[NSArray arrayWithObjects:new1, e1, new2, nil]
                                                              andStartPoint:newPoint 
                                                                   andColor:color];
        DelaunayTriangle * e2Triangle = [DelaunayTriangle triangleWithEdges:[NSArray arrayWithObjects:new2, e2, new3, nil]
                                                              andStartPoint:newPoint
                                                                   andColor:color];
        DelaunayTriangle * e3Triangle = [DelaunayTriangle triangleWithEdges:[NSArray arrayWithObjects:new3, e3, new1, nil]
                                                              andStartPoint:newPoint
                                                                   andColor:color];
        
        [self.triangles addObject:e1Triangle];        
        [self.triangles addObject:e2Triangle];        
        [self.triangles addObject:e3Triangle];
        
        [self enforceDelaunayProperty];
        return YES;
    }
    return NO;
}

- (DelaunayTriangle *)triangleContainingPoint:(DelaunayPoint *)point
{
    for (DelaunayTriangle* triangle in self.triangles)
    {
        if ([triangle containsPoint:point])
        {
            return triangle;
        }
    }
    return nil;
}

- (void)enforceDelaunayProperty
{
    bool hadToFlip;
    
    do {
        hadToFlip = NO;
        
        NSMutableSet *trianglesToRemove = [NSMutableSet set];
        NSMutableSet *trianglesToAdd = [NSMutableSet set];
        
        // Flip all non-Delaunay edges
        for (DelaunayTriangle *triangle in self.triangles)
        {
            CGPoint circumcenter = [triangle circumcenter];
            
            float radius = sqrtf(powf(triangle.startPoint.x - circumcenter.x, 2) + powf(triangle.startPoint.y - circumcenter.y, 2));
            
            for (DelaunayEdge *sharedEdge in triangle.edges)
            {
                DelaunayTriangle *neighborTriangle = [sharedEdge neighborOf:triangle];
                if (neighborTriangle != nil)
                {
                    // Find the non-shared point in the other triangle
                    DelaunayPoint *ourNonSharedPoint = [triangle pointNotInEdge:sharedEdge];
                    DelaunayPoint *theirNonSharedPoint = [neighborTriangle pointNotInEdge:sharedEdge];
                    if (sqrtf(powf(theirNonSharedPoint.x - circumcenter.x, 2) + powf(theirNonSharedPoint.y - circumcenter.y, 2)) < radius )
                    {
                        // If the non-shared point is within the circumcircle of this triangle, flip to share the other two points
                        [trianglesToRemove addObject:triangle];
                        [trianglesToRemove addObject:neighborTriangle];

                        // Get the edges before & after the shared edge in the triangle
                        DelaunayEdge *beforeEdge = [triangle edgeStartingWithPoint:ourNonSharedPoint];
                        DelaunayEdge *afterEdge = [triangle edgeEndingWithPoint:ourNonSharedPoint];

                        DelaunayEdge *newEdge = [DelaunayEdge edgeWithPoints:[NSArray arrayWithObjects:theirNonSharedPoint, ourNonSharedPoint, nil]];
                        [self.edges addObject:newEdge];

                        // Get the edges before & after the shared edge in the neighbor triangle
                        DelaunayEdge *neighborBeforeEdge = [neighborTriangle edgeStartingWithPoint:theirNonSharedPoint];
                        DelaunayEdge *neighborAfterEdge = [neighborTriangle edgeEndingWithPoint:theirNonSharedPoint];
                        
                        DelaunayTriangle *newTriangle1 = [DelaunayTriangle triangleWithEdges:[NSArray arrayWithObjects:newEdge, beforeEdge, neighborAfterEdge, nil]
                                                                               andStartPoint:theirNonSharedPoint
                                                                                    andColor:triangle.color];
                        
                        DelaunayTriangle *newTriangle2 = [DelaunayTriangle triangleWithEdges:[NSArray arrayWithObjects:neighborBeforeEdge, afterEdge, newEdge, nil]
                                                                               andStartPoint:theirNonSharedPoint
                                                                                    andColor:neighborTriangle.color];
                        
                        [trianglesToAdd addObject:newTriangle1];
                        [trianglesToAdd addObject:newTriangle2];
                        [sharedEdge remove];
                        [self.edges removeObject:sharedEdge];
                        hadToFlip = YES;
                        break;
                    }
                }
            }
            if (hadToFlip)
                break;
        }
        
        for (DelaunayTriangle* triangleToRemove in trianglesToRemove)
        {
            [self removeTriangle:triangleToRemove];
        }
        for (DelaunayTriangle* triangleToAdd in trianglesToAdd)
        {
            [self.triangles addObject:triangleToAdd];
        }
    } while (hadToFlip);
}

- (NSDictionary*)voronoiCells
{
    NSMutableDictionary *cells = [NSMutableDictionary dictionary];
    for (DelaunayPoint *point in self.points)
    {
        // Don't add voronoi cells at the frame triangle points
        if ([self.frameTrianglePoints containsObject:point])
            continue;
        
        NSArray *pointEdges = [point counterClockwiseEdges];
        NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:[pointEdges count]];
        DelaunayEdge *prevEdge = [pointEdges lastObject];
        for (DelaunayEdge *edge in pointEdges)
        {
            DelaunayTriangle *sharedTriangle = [edge sharedTriangleWithEdge:prevEdge];
            [nodes addObject:[NSValue valueWithCGPoint:[sharedTriangle circumcenter]]];
            prevEdge = edge;
        }
        //[cells addObject:[VoronoiCell voronoiCellAtSite:point withNodes:nodes]];
        [cells setObject:[VoronoiCell voronoiCellAtSite:point withNodes:nodes] forKey:point.UUIDString];
    }
    return cells;
}

- (void)interpolateWeightsWithPoint:(DelaunayPoint *)point
{
    DelaunayTriangulation *testTriangulation = [self copy];//[[self copy] autorelease];
    BOOL added = [testTriangulation addPoint:point withColor:nil];
    // TODO(mrotondo): Special-case touches right on top of existing points here.
    if (added)
    {
        NSDictionary *voronoiCells = [self voronoiCells];
        // TODO(mrotondo): Interpolate by adding and removing a point instead of copying the whole triangulation
        NSDictionary *testVoronoiCells = [testTriangulation voronoiCells];
        float fractionSum = 0.0;
        NSMutableDictionary *fractions = [NSMutableDictionary dictionaryWithCapacity:[voronoiCells count]];
        for ( DelaunayPoint *point in [voronoiCells keyEnumerator] )
        {
            VoronoiCell *cell = [voronoiCells objectForKey:point.UUIDString];
            VoronoiCell *testCell = [testVoronoiCells objectForKey:point.UUIDString];
            float fractionalChange = 0.0;
            if ( [cell area] > 0.0 )
                fractionalChange = 1.0 - MAX(MIN([testCell area] / [cell area], 1.0), 0.0);
            fractionSum += fractionalChange;
            [fractions setObject:[NSNumber numberWithFloat:fractionalChange] forKey:point.UUIDString];
        }
        if (fractionSum > 0.0)
        {
            for ( DelaunayPoint *point in [voronoiCells keyEnumerator] )
            {
                VoronoiCell *cell = [voronoiCells objectForKey:point.UUIDString];
                NSNumber *fractionalChange = [fractions objectForKey:point.UUIDString];
                cell.site.contribution = [fractionalChange floatValue] / fractionSum;
            }
        }
    }
}

@end

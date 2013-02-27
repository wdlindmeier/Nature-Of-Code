//
//  VoronoiCell.m
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/21/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "VoronoiCell.h"
#import "DelaunayPoint.h"

@implementation VoronoiCell
@synthesize site;
@synthesize nodes;

+ (VoronoiCell *)voronoiCellAtSite:(DelaunayPoint *)site withNodes:(NSArray *)nodes
{
    VoronoiCell *cell = [[self alloc] init];
    
    cell.site = site;
    cell.nodes = nodes;
    
    return cell;
}


- (void)drawInContext:(CGContextRef)ctx
{
    NSValue *prevPoint = [self.nodes lastObject];
    CGPoint p = [prevPoint CGPointValue];
    CGContextMoveToPoint(ctx, p.x, p.y);
    for ( NSValue *point in self.nodes)
    {
        CGPoint p = [point CGPointValue];
        CGContextAddLineToPoint(ctx, p.x, p.y);        
    }
}

- (float)area
{
    float xys = 0.0;
    float yxs = 0.0;
    
    NSValue *prevPoint = [self.nodes objectAtIndex:0];
    CGPoint prevP = [prevPoint CGPointValue];
    for ( NSValue *point in [self.nodes reverseObjectEnumerator])
    {
        CGPoint p = [point CGPointValue];
        xys += prevP.x * p.y;
        yxs += prevP.y * p.x;
        prevP = p;
    }
    
    return (xys - yxs) * 0.5;
}

@end

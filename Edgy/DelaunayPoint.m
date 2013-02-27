//
//  DelaunayPoint.m
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/17/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "DelaunayPoint.h"
#import "DelaunayEdge.h"
#import "DelaunayTriangle.h"

@implementation DelaunayPoint
@synthesize x, y;
@synthesize UUIDString;
@synthesize contribution;
@synthesize value;
@synthesize color;

+ (DelaunayPoint *)pointAtX:(float)newX andY:(float)newY
{
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef stringRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    NSString *UUIDString = (__bridge NSString *)stringRef;
    CFRelease(UUIDRef);
    DelaunayPoint *point = [DelaunayPoint pointAtX:newX andY:newY withUUID:UUIDString];
    return point;
}

+ (DelaunayPoint *)pointAtX:(float)newX andY:(float)newY withUUID:(NSString *)UUIDString
{
    DelaunayPoint *point = [[self alloc] init];
    point.x = newX;
    point.y = newY;
    point.UUIDString = UUIDString;
    point.contribution = 0.0;
    point.color = [UIColor colorWithRed:(float)rand() / RAND_MAX
                                  green:(float)rand() / RAND_MAX
                                   blue:(float)rand() / RAND_MAX
                                  alpha:1.0];
    return point;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        nonretainingEdges = CFSetCreateMutable(NULL, 2, NULL);
    }
    return self;
}

- (void)dealloc
{
    CFRelease(nonretainingEdges);
}

- (id)copyWithZone:(NSZone *)zone
{
    DelaunayPoint *copy = [DelaunayPoint pointAtX:self.x andY:self.y withUUID:self.UUIDString];
    copy.contribution = self.contribution;
    copy.value = self.value;
    return copy;
}

- (void)printRecursive:(BOOL)recursive
{
    NSLog(@"Point %@ (%p) at %f, %f", self.UUIDString, self, self.x, self.y);
    if (recursive)
    {
        NSLog(@"I'm connected to these points in counter-clockwise order:");
        DelaunayPoint *otherPoint;
        for (DelaunayEdge *edge in [self counterClockwiseEdges])
        {
            otherPoint = [edge otherPoint:self];
            [otherPoint printRecursive:NO];
        }
    }
}

- (NSMutableSet *)edges
{
    return (__bridge NSMutableSet *)nonretainingEdges;
}

- (NSArray *)counterClockwiseEdges
{
    return [[self.edges allObjects] sortedArrayUsingComparator:^(id obj1, id obj2) {
        DelaunayEdge *e1 = obj1;
        DelaunayEdge *e2 = obj2;
        
        DelaunayPoint *p1 = [e1 otherPoint:self];
        DelaunayPoint *p2 = [e2 otherPoint:self];
        
        float angle1 = atan2(p1.y - self.y, p1.x - self.x);
        float angle2 = atan2(p2.y - self.y, p2.x - self.x);
        if ( angle1 > angle2 )
            return NSOrderedAscending;
        else if ( angle1 < angle2 )
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
}

@end

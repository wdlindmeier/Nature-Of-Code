//
//  DelaunayPoint.h
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/17/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DelaunayPoint : NSObject// <NSCopying>
{

    CFMutableSetRef nonretainingEdges;
    float contribution;
    UIColor *color;
}
@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic, strong) NSString *UUIDString;
@property (nonatomic, readonly) NSMutableSet *edges;
@property float contribution;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) UIColor *color;

+ (DelaunayPoint *) pointAtX:(float)x andY:(float)y;
+ (DelaunayPoint *)pointAtX:(float)newX andY:(float)newY withUUID:(NSString *)uuid;
- (NSArray *)counterClockwiseEdges;

//- (BOOL)isEqual:(id)object;
//- (NSUInteger)hash;

- (void)printRecursive:(BOOL)recursive;

@end

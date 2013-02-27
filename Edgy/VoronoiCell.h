//
//  VoronoiCell.h
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/21/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DelaunayPoint.h"

@interface VoronoiCell : NSObject {
    
    DelaunayPoint *site;
    NSArray *nodes;
}

@property (nonatomic, strong) DelaunayPoint *site;
@property (nonatomic, strong) NSArray *nodes;

+ (VoronoiCell *)voronoiCellAtSite:(DelaunayPoint *)site withNodes:(NSArray *)nodes;
- (void)drawInContext:(CGContextRef)ctx;
- (float)area;

@end

//
//  NOCFollower.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/31/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCBeing.h"
#import "NOCSharedFollowerTrail.h"

@interface NOCShapeFollower : NOCBeing

- (void)updateFitnessWithDistanceToShapeSurface:(float)dist;

@end

//
//  NOCFollower.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/31/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCBeing.h"
#import "NOCSharedFollowerTrail.h"

@interface NOCFollower : NOCBeing

@property (nonatomic, assign) FollowerGridPosition gridPosition;
@property (nonatomic, strong) NOCSharedFollowerTrail *sharedTrail;

- (void)updateFitnessWithTrailValue:(int)globalTrailValue;

@end

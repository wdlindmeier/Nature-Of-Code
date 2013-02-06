//
//  NOCMover.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOCParticle.h"

@interface NOCMover : NOCParticle

@property (nonatomic, assign) GLKVector2 velocity;
@property (nonatomic, assign) GLKVector2 acceleration;
@property (nonatomic, assign) float maxVelocity;

- (void)stepInRect:(CGRect)rect;

@end

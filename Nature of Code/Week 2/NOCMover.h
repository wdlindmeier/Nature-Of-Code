//
//  NOCMover.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOCParticle.h"
#import "NOCPositionedMass.h"

@interface NOCMover : NOCParticle <NOCPositionedMass>

@property (nonatomic, assign) GLKVector2 velocity;
@property (nonatomic, assign) GLKVector2 acceleration;
@property (nonatomic, assign) float mass;
@property (nonatomic, assign) float maxVelocity;

- (id)initWithSize:(CGSize)size position:(GLKVector2)position mass:(float)mass;
- (void)stepInRect:(CGRect)rect shouldWrap:(BOOL)shouldWrap;
- (void)applyForce:(GLKVector2)vecForce;

@end

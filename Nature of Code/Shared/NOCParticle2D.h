//
//  NOCParticle2D.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOCParticle.h"

@interface NOCParticle2D : NOCParticle

@property (nonatomic, assign) GLKVector2 velocity;
@property (nonatomic, assign) GLKVector2 acceleration;
@property (nonatomic, assign) GLKVector2 position;
@property (nonatomic, assign) GLKVector2 size;
@property (nonatomic, assign) float maxVelocity;

- (id)initWithSize:(GLKVector2)size position:(GLKVector2)position;
- (void)applyForce:(GLKVector2)vecForce;

@end


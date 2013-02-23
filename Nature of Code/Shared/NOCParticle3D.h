//
//  NOCParticle3D.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOCParticle.h"

@interface NOCParticle3D : NOCParticle

@property (nonatomic, assign) GLKVector3 position;
@property (nonatomic, assign) GLKVector3 velocity;
@property (nonatomic, assign) GLKVector3 acceleration;
@property (nonatomic, assign) GLKVector3 size;
@property (nonatomic, assign) float maxVelocity;

- (id)initWithSize:(GLKVector3)size position:(GLKVector3)position;
- (void)applyForce:(GLKVector3)vecForce;

@end

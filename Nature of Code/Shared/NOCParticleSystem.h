//
//  NOCParticleSystem.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOCParticle.h"

@interface NOCParticleSystem : NSObject

@property (nonatomic, assign) GLKVector3 position;

// Position is in 3D.
// If this is a 2D particle system, z should be 0.
- (id)initWithPosition:(GLKVector3)position capacity:(int)capacity;
- (id)initWithPosition:(GLKVector3)position;

- (GLKMatrix4)modelMatrix;

- (void)addParticle:(NOCParticle *)particle;

- (void)applyForce3D:(GLKVector3)force;
- (void)applyForce2D:(GLKVector2)force;

- (void)step;

- (void)render:(void(^)(GLKMatrix4 particleMatrix, NOCParticle *p))renderBlock;

@end

//
//  NOCFlame.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCParticleSystem.h"

@interface NOCFlame : NOCParticleSystem

@property (nonatomic, assign) GLKVector3 velocity;

- (id)initWithPosition:(GLKVector3)position flameTexture:(GLKTextureInfo *)texture;
- (void)stepWithLift:(GLKVector2)vecUp;
- (void)renderInMatrix:(GLKMatrix4)projectionMatrix;
- (BOOL)isDead;
- (void)kill;

@end

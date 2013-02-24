//
//  NOCParticleSystem.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCParticleSystem.h"
#import "NOCParticle2D.h"
#import "NOCParticle3D.h"

@implementation NOCParticleSystem
{
    NSMutableArray *_particles;
}

#pragma mark - Init

- (id)initWithPosition:(GLKVector3)position capacity:(int)capacity
{
    self = [super init];
    if(self){
        self.position = position;
        _particles = [NSMutableArray arrayWithCapacity:capacity];
    }
    return self;
}

- (id)initWithPosition:(GLKVector3)position
{
    return [self initWithPosition:position capacity:100];
}

#pragma mark - Accessors

- (GLKMatrix4)modelMatrix
{
    GLKMatrix4 modelMat = GLKMatrix4Identity;
    
    modelMat = GLKMatrix4Translate(modelMat,
                                   self.position.x,
                                   self.position.y,
                                   self.position.z);
    
    return modelMat;
}

#pragma mark - Particle management

- (void)addParticle:(NOCParticle *)particle
{
    // This draws the newest particles behind the oldest particles.
    [_particles insertObject:particle atIndex:0];

    // This draws newest in front of oldest.
    // [_particles addObject:particle];
}

#pragma mark - Movement

- (void)applyForce3D:(GLKVector3)force
{
    for(NOCParticle3D *p in _particles){
        if([p isKindOfClass:[NOCParticle3D class]]){
            [p applyForce:force];
        }else{
            NSLog(@"ERROR: Can not apply 3D force to class: %@", [p class]);
        }
    }
}

- (void)applyForce2D:(GLKVector2)force
{
    for(NOCParticle2D *p in _particles){
        if([p isKindOfClass:[NOCParticle2D class]]){
            [p applyForce:force];
        }else{
            NSLog(@"ERROR: Can not apply 2D force to class: %@", [p class]);
        }
    }
}

#pragma mark - Update

- (void)step
{
    // NOTE: We have to create a separate collection of dead particles
    // so we dont modify the _particles collection when we iterate over it.
    NSMutableArray *deadParticles = [NSMutableArray arrayWithCapacity:_particles.count];
    
    for(NOCParticle *p in _particles){
        [p step];
        if([p isDead]){
            [deadParticles addObject:p];
        }
    }
    
    for(NOCParticle*p in deadParticles){
        [_particles removeObject:p];
    }
    
}

#pragma mark - Draw

- (void)render:(void(^)(GLKMatrix4 particleMatrix, NOCParticle *p))renderBlock
{
    GLKMatrix4 systemMatrix = [self modelMatrix];
    for(NOCParticle*p in _particles){
        GLKMatrix4 pMatrix = [p modelMatrix];
        GLKMatrix4 pSystemMatrix = GLKMatrix4Multiply(systemMatrix, pMatrix);
        // This informs the caller what the specific particl matrix is
        // so it can be passed into a shader.
        renderBlock(pSystemMatrix, p);
        [p render];
    }
}

@end

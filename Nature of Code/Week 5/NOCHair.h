//
//  NOCHair.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/8/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NOCParticle2D;
@class NOCSpring2D;

@interface NOCHair : NSObject

- (id)initWithAnchor:(GLKVector2)anchor numParticles:(int)numParticles ofLength:(float)distBetweenParticles;
- (void)applyForce:(GLKVector2)force;
- (void)applyPointForce:(GLKVector2)fPos withMagnitude:(float(^)(float distToParticle))forceBlock;
- (void)update;
- (NSArray *)particles;
- (void)renderParticles:(void(^)(GLKMatrix4 particleMatrix, NOCParticle2D *p))pRenderBlock
             andSprings:(void(^)(GLKMatrix4 springMatrix, NOCSpring2D *s))sRenderBlock;

@property (nonatomic, assign) GLKVector2 anchor;
@property (nonatomic, assign) float maxVelocity;
@property (nonatomic, assign) float amtStretch;
@property (nonatomic, assign) float dampening;
@property (nonatomic, assign) float growthRate;
@property (nonatomic, readonly) float lastSegmentLength;
@property (nonatomic, readonly) int numParticles;
@property (nonatomic, assign) int maxNumParticles;

@end

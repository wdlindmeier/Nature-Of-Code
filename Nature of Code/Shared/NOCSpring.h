//
//  NOCSpring.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOCParticle.h"

@interface NOCSpring : NSObject
{
    BOOL _hasAnchor;
}

@property (nonatomic, assign) float minLength;
@property (nonatomic, assign) float restLength;
@property (nonatomic, assign) float maxLength;
@property (nonatomic, assign) float springiness;
@property (nonatomic, assign) float dampening; // Dampening should be less than 0 (e.g. -0.05)
@property (nonatomic, assign) NOCParticle *particleA;
@property (nonatomic, assign) NOCParticle *particleB;

- (id)initWithParicleA:(NOCParticle *)pA particleB:(NOCParticle *)pB restLength:(float)restLength;
- (void)applyForceToParticles;
- (void)constrainParticles;
- (void)render;
- (BOOL)hasAnchor;

@end

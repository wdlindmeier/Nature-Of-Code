//
//  NOCSpring.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSpring.h"

@implementation NOCSpring

- (id)initWithParicleA:(NOCParticle *)pA particleB:(NOCParticle *)pB restLength:(float)restLength
{
    self = [super init];
    if(self){
        self.minLength = 0;
        self.maxLength = MAXFLOAT;
        self.springiness = 0.1f;
        self.restLength = restLength;
        self.particleA = pA;
        self.particleB = pB;
        self.dampening = 0.0f;
        _hasAnchor = NO;
    }
    return self;
}

- (BOOL)hasAnchor
{
    return _hasAnchor;
}

- (void)applyForceToParticles
{
    // Implementation needs to be done in the subclass since they deal in 2/3 Dimension
}

- (void)constrainParticles
{
    //...
}

- (void)render
{
    //...
}

@end

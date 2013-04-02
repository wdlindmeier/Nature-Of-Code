//
//  NOCFollower.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/31/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCShapeFollower.h"

@implementation NOCShapeFollower
{
    float _distanceFitness;
}

- (id)initWithRadius:(float)radius position:(GLKVector3)position mass:(float)mass
{
    self = [super initWithRadius:radius position:position mass:mass];
    if(self){
        _distanceFitness = 0;
        self.fitness = 0;
    }
    return self;
}

- (void)glColor:(GLfloat *)components
{
    const CGFloat *myColor = CGColorGetComponents(self.color.CGColor);
    if(CGColorGetNumberOfComponents(self.color.CGColor) < 3){
        myColor = CGColorGetComponents([UIColor whiteColor].CGColor);
    }
    components[0] = myColor[0];
    components[1] = myColor[1];
    components[2] = myColor[2];
    components[3] = myColor[3];
}

- (void)step
{
    [super step];
}

- (void)updateFitnessWithDistanceToShapeSurface:(float)dist
{
    // Reward closeness to surface
    _distanceFitness -= dist * dist;
}

- (float)fitness
{
     // Weigh the distance to surface more then amt travelled
    float fitness = _distanceFitness;// + self.distTravelled;
    self.fitness = fitness;
    return fitness;
}

@end

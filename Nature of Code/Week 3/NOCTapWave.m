//
//  NOCTapWave.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/16/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTapWave.h"

@implementation NOCTapWave

- (id)init
{
    self = [super init];
    if(self){
        self.decayPerSecond = 0;
        self.amplitude = 1;
        self.frequency = 0.1;
    }
    return self;
}

- (id)initWithAmplitude:(float)amplitude
              frequency:(float)frequency
          timeTriggered:(NSTimeInterval)tiTriggered
               position:(GLKVector3)position
{
    self = [super init];
    if(self){
        self.position = position;
        self.amplitude = amplitude;
        self.frequency = frequency;
        self.timeTriggered = tiTriggered;
        self.decayPerSecond = 0.999; // Default
    }
    return self;
}

- (float)valueAtTime:(NSTimeInterval)time
{
    // We'll say Frequency is hz (period / sec),
    // and decay is per-second.
    double seconds = time - self.timeTriggered;
    double amtDecay = self.decayPerSecond * seconds;
    BOOL isDead = amtDecay > 0.999999;
    
    if(seconds < 0 || isDead){
        // The wave hasn't "hit" yet
        // or it's already dead.
        return 0;
    }
    
    double timeAmp = self.amplitude * (1.0 - amtDecay);
    return sin(seconds * self.frequency) * timeAmp;
}

- (BOOL)isDeadAtTime:(NSTimeInterval)time
{
    double seconds = time - self.timeTriggered;
    double amtDecay = self.decayPerSecond * seconds;
    return amtDecay > 0.999999;
}

@end

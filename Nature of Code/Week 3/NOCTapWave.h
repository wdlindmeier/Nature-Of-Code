//
//  NOCTapWave.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/16/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface NOCTapWave : NSObject

@property (nonatomic, assign) NSTimeInterval timeTriggered;
@property (nonatomic, assign) float amplitude;
@property (nonatomic, assign) float frequency;
@property (nonatomic, assign) float decayPerSecond;
@property (nonatomic, assign) GLKVector3 position;

- (id)initWithAmplitude:(float)amplitude
              frequency:(float)frequency
          timeTriggered:(NSTimeInterval)tiTriggered
               position:(GLKVector3)position;

- (float)valueAtTime:(NSTimeInterval)timeOffset;
- (BOOL)isDeadAtTime:(NSTimeInterval)time;

@end

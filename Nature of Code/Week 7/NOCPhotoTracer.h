//
//  NOCPhotoTracer.h
//  Nature of Code
//
//  Created by William Lindmeier on 4/4/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTracer2D.h"

typedef enum PhotoSampleTypes {
    PhotoSampleTypeHue,
    PhotoSampleTypeSaturation,
    PhotoSampleTypeValue,
    PhotoSampleTypeAll
} PhotoSampleType;

@interface NOCPhotoTracer : NOCTracer2D

- (GLKVector2)previousPosition;
- (void)updateFitnessWithContrastHue:(float)hueCtrst sat:(float)satCtrst val:(float)valCtrst;

@property (nonatomic, assign) float sampleOffset;
@property (nonatomic, assign) PhotoSampleType sampleType;

@end

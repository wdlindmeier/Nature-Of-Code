//
//  NOCPhotoTracer.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/4/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCPhotoTracer.h"

@implementation NOCPhotoTracer
{
    float _contrastFitness;
}

- (id)initWithDNALength:(int)DNALength
{
    self = [super initWithDNALength:DNALength];
    if(self){
        [self initPhotoTracer];
    }
    return self;
}

- (id)initWithLifeSpan:(int)lifespan
{
    self = [super initWithLifeSpan:lifespan];
    if(self){
        [self initPhotoTracer];
    }
    return self;
}

- (void)initPhotoTracer
{
    _contrastFitness = 0;
    self.sampleOffset = 0.01;
    self.sampleType = PhotoSampleTypeValue;
}

- (GLKVector2)previousPosition
{
    return [self positionAtFrame:self.framesAlive-1];
}

- (float)evaluateFitness
{
    return _contrastFitness;
}

- (void)updateFitnessWithContrastHue:(float)hueCtrst sat:(float)satCtrst val:(float)valCtrst
{
    float fitness;
    switch (self.sampleType) {
        case PhotoSampleTypeHue:
            fitness = hueCtrst;
            break;
        case PhotoSampleTypeSaturation:
            fitness = satCtrst;
            break;
        case PhotoSampleTypeValue:
            fitness = valCtrst;
            break;
        case PhotoSampleTypeAll:
            fitness = hueCtrst + satCtrst + valCtrst;
            break;
    }
    _contrastFitness += fitness * fitness;
}

- (float)fitness
{
    return _contrastFitness;
}

- (void)expressDNA
{
    [super expressDNA];
    
    /*
    // This is the index after the positions and color
    int idx = self.lifespan * 2 + 3;
    
    // Position
    float x = f([self DNA][idx+0]) * 2 - 1.0f;
    float y = f([self DNA][idx+1]) * 2 - 1.0f;
    //float z = f([self DNA][idx+2]) * 2 - 1.0f;
    self.position = GLKVector2Make(x, y);
    */

}


@end

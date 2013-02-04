//
//  NOCPerlinWalker.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/4/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCPerlinWalker.h"
#import "perlin.h"
#import "NOCGeometryHelpers.h"
#import "CGGeometry.h"

static const int NumSavedPositions = 5;

@implementation NOCPerlinWalker
{
    float _curTime;
    float _rads;
}

- (id)initWithSize:(CGSize)size position:(CGPoint)position
{
    self = [super initWithSize:size position:position];
    if(self){
        _curTime = 0.0f;
        self.timeStep = 0.1f;
        self.perlinAlpha = 1.5f;
        self.perlinBeta = 1.5f;
        self.perlinNumOctaves = 12;
    }
    return self;
}

- (void)stepInRect:(CGRect)rect
{
    _curTime += self.timeStep;
    
    double perlinVal = PerlinNoise1D(_curTime,
                                     self.perlinAlpha,
                                     self.perlinBeta,
                                     self.perlinNumOctaves);
    
    _rads = _rads + perlinVal;
    
    CGPoint moveDir = RadiansToVector(_rads);
    
    // Rounding will keep the walker on the pixel bounds.
    // But it looks nicer as a smooth line IMO.
    float moveX = moveDir.x; // round(moveDir.x);
    float moveY = moveDir.y; // round(moveDir.y);

    float x = self.position.x + moveX;
    float y = self.position.y + moveY;
    
    // Account for the scale
    float minX = rect.origin.x / self.size.width;
    float maxX = (rect.origin.x + rect.size.width) / self.size.width;
    float minY = rect.origin.y / self.size.height;
    float maxY = (rect.origin.y + rect.size.height) / self.size.height;
    
    if(x<minX || x>maxX || y<minY || y>maxY){
        // If we're outside the bounds, turn in a random direction
        // Maybe this should just be -180 deg
        float addRads = RAND_SCALAR * M_PI * 2;
        double newRads = fmod(_rads + addRads, M_PI * 2);
        _rads = newRads;
    }
    
    // Dont let the walker move outside of the rect.
    x = CONSTRAIN(x,minX,maxX);
    y = CONSTRAIN(y,minY,maxY);
    
    self.position = CGPointMake(x,y);
}

@end

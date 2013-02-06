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

@implementation NOCPerlinWalker
{
    float _curTimeX;
    float _curTimeY;
}

- (id)initWithSize:(CGSize)size position:(GLKVector2)position
{
    self = [super initWithSize:size position:position];
    if(self){

        self.timeStep = 0.01f;
        self.perlinAlpha = 1.5f;
        self.perlinBeta = 1.5f;
        self.perlinNumOctaves = 5;

        _curTimeX = 0;
        _curTimeY = 0;

    }
    return self;
}

- (void)stepInRect:(CGRect)rect
{
    
    // Get the bounds for the current scale
    float minX = rect.origin.x / self.size.width;
    float maxX = (rect.origin.x + rect.size.width) / self.size.width;
    float minY = rect.origin.y / self.size.height;
    float maxY = (rect.origin.y + rect.size.height) / self.size.height;
    
    // Increment the time
    _curTimeX += self.timeStep;
    _curTimeY += self.timeStep;
    
    float randX = PerlinNoise2D(_curTimeX, 0,
                                self.perlinAlpha,
                                self.perlinBeta,
                                self.perlinNumOctaves);
    
    float randY = PerlinNoise2D(0, _curTimeY,
                                self.perlinAlpha,
                                self.perlinBeta,
                                self.perlinNumOctaves);
    
    CGPoint normalRandXY = CGPointNormalize(CGPointMake(randX, randY));
    
    float x = self.position.x + normalRandXY.x;
    float y = self.position.y + normalRandXY.y;
    
    // Dont let the walker move outside of the rect.
    x = CONSTRAIN(x,minX,maxX);
    y = CONSTRAIN(y,minY,maxY);
    
    self.position = GLKVector2Make(x,y);
}

@end

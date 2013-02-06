//
//  NOCPerlinWalker.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/4/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCWalker.h"

@interface NOCPerlinWalker : NOCWalker

- (void)stepInRect:(CGRect)rect;

@property (nonatomic, assign) float timeStep;
@property (nonatomic, assign) double perlinAlpha;
@property (nonatomic, assign) double perlinBeta;
@property (nonatomic, assign) int perlinNumOctaves;

@end

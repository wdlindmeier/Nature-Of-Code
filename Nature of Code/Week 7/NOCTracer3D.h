//
//  NOCTracer3D.h
//  Nature of Code
//
//  Created by William Lindmeier on 4/3/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTracer.h"

@interface NOCTracer3D : NOCTracer

- (NOCTracer3D *)crossover:(NOCTracer3D *)mate;
- (float)overallFitnessForCircleOfRadius:(float)radius;

@end

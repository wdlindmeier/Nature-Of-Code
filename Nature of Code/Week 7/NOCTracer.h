//
//  NOCTracer.h
//  Nature of Code
//
//  Created by William Lindmeier on 4/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOCBreeder.h"

@interface NOCTracer : NOCBreeder

@property (nonatomic, assign) int lifespan;

- (id)initWithLifeSpan:(int)lifespan;
- (NOCTracer *)crossover:(NOCTracer *)mate;
- (void)expressDNA;

- (void)step;

- (void)glColor:(GLfloat *)components;
- (void)render:(BOOL)colored;

- (float)overallFitnessForCircleOfRadius:(float)radius;

@end

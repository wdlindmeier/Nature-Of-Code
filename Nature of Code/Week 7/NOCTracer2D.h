//
//  NOCTracer2D.h
//  Nature of Code
//
//  Created by William Lindmeier on 4/3/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTracer.h"

@interface NOCTracer2D : NOCTracer

@property (nonatomic, assign) GLKVector2 position;
@property (nonatomic, assign) BOOL didHitObstruction;
@property (nonatomic, assign) BOOL didHitTarget;
@property (nonatomic, readonly) float fitness;

- (float)evaluateFitness;
- (void)checkTarget:(GLKVector2)target radius:(float)targetRadius;
- (void)stepInRect:(CGRect)rect;
- (GLKVector2)positionAtFrame:(int)frame;

@end

//
//  CGGeometry.h
//  Branching
//
//  Created by Jon Olson on 11/30/09.
//  Copyright 2009 Ballistic Pigeon, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RAND_SCALAR ((double)(arc4random() % 100000) * 0.00001)

extern CGPoint CGPointScale(CGPoint A, double b);
extern CGPoint CGPointAdd(CGPoint a, CGPoint b);
extern CGPoint CGPointSubtract(CGPoint a, CGPoint b);
extern double CGPointCross(CGPoint a, CGPoint b);
extern double CGPointDot(CGPoint a, CGPoint b);
extern double CGPointMagnitude(CGPoint pt);
extern CGPoint CGPointNormalize(CGPoint pt);

extern BOOL BPLineSegmentsIntersect(CGPoint a1, CGPoint a2, CGPoint b1, CGPoint b2, CGPoint *intersection);

static inline float DegreesToRadians(float degrees) { return degrees * M_PI / 180; }
static inline float RadiansToDegrees(float rads) { return rads * (180 / M_PI); }
extern CGPoint DegreesToVector(float deg);
extern CGPoint RadiansToVector(float rads);
extern float CGPointDistance(CGPoint a, CGPoint b);

extern float RadiansBetweenPoints(CGPoint a, CGPoint b);
extern float RadiansFromVector(CGPoint vec);
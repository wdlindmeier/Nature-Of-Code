//
//  CGGeometry.m
//  Branching
//
//  Created by William Lindmeier on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CGGeometry.h"

/*
 *  BPGeometry.m
 *
 *  Created by Jon Olson on 11/30/09.
 *  Copyright 2009 Ballistic Pigeon, LLC. All rights reserved.
 *
 */


/**
 * Calculate the vector-scalar product A*b
 */
CGPoint CGPointScale(CGPoint A, double b) {
	return CGPointMake(A.x*b, A.y*b);
}

/**
 * Calculate the vector-vector sum a+b
 */
CGPoint CGPointAdd(CGPoint a, CGPoint b) {
	return CGPointMake(a.x + b.x, a.y + b.y);
}

/**
 * Calculate the vector-vector difference a-b
 */
CGPoint CGPointSubtract(CGPoint a, CGPoint b) {
	return CGPointMake(a.x - b.x, a.y - b.y);
}

/**
 * Calculate the cross product for two 2D vectors by treating them as 3D
 * vectors with zero for the third component. As the direction of the
 * resulting vector is always directly up the z-axis, this returns a scalar
 * equal to |a|*|b|*sin(alpha) where alpha is the angle in the plane between
 * a and b.
 */
double CGPointCross(CGPoint a, CGPoint b) {
	return a.x*b.y - b.x*a.y;
}

/**
 * Calculate the dot-product of two 2D vectors a dot b
 */
double CGPointDot(CGPoint a, CGPoint b) {
	return a.x*b.x + a.y*b.y;
}

/**
 * Calculate the magnitude of a 2D vector
 */
double CGPointMagnitude(CGPoint pt) {
	return sqrt(CGPointDot(pt, pt));
}

/**
 * Normalize a 2D vector
 */
CGPoint CGPointNormalize(CGPoint pt) {
	return CGPointScale(pt, 1.0 / CGPointMagnitude(pt));
}

/**
 * Determining whether two line segments intersect is harder than you'd think.
 *
 * There is an obvious way to do it, but it requires many special cases and doesn't look pretty.
 */
// From http://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect/565282#565282
BOOL BPLineSegmentsIntersect(CGPoint a1, CGPoint a2, CGPoint b1, CGPoint b2, CGPoint *intersection) {
	if (CGPointEqualToPoint(a1, a2))
		return NO;
	if (CGPointEqualToPoint(b1, b2))
		return NO;
    
	CGPoint r = CGPointSubtract(a2, a1);
	CGPoint s = CGPointSubtract(b2, b1);
    
	double cross = CGPointCross(r, s);
	if (cross == 0.0)
		return NO;
    
	CGPoint v = CGPointSubtract(b1, a1);
    
	double t = CGPointCross(v, s) / cross;
	double u = CGPointCross(v, r) / cross;
	BOOL intersect = (0.0 <= t) && (t <= 1.0) && (0.0 <= u) && (u <= 1.0);
    
    if(intersect){
        *intersection = CGPointAdd(a1, CGPointScale(CGPointSubtract(a2, a1), t));
    }
    
//	if (intersect)
//		DebugLog(@"intersect:%@ (cross:%f t:%f u:%f)", NSStringFromCGPoint(CGPointAdd(a1, CGPointScale(CGPointSubtract(a2, a1), t))), cross, t, u);
    
	return intersect;
}



/* 
 Convert degree to vector
 */

CGPoint DegreesToVector(float deg)
{
    return RadiansToVector(deg*(M_PI/180.0f));
}

CGPoint RadiansToVector(float rads)
{
    CGPoint vec;
    vec.x=sin(rads);
    vec.y=cos(rads);
    return vec;
}

float CGPointDistance(CGPoint a, CGPoint b)
{
    float xDelta = fabs(a.x - b.x);
    float yDelta = fabs(a.y - b.y);
    return sqrt((xDelta * xDelta) + (yDelta * yDelta));
}


extern float RadiansBetweenPoints(CGPoint a, CGPoint b)
{
    float dx = b.x-a.x;
    float dy = b.y-a.y;
    return RadiansFromVector(CGPointMake(dx, dy));
}

extern float RadiansFromVector(CGPoint vec)
{    
    return atan2f(vec.y , vec.x);
}
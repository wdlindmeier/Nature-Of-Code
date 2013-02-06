//
//  NOCOpenGLHelpers.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "CGGeometry.h"

#ifndef Nature_of_Code_NOCOpenGLHelpers_h
#define Nature_of_Code_NOCOpenGLHelpers_h

#define CONSTRAIN(n,min,max)    MIN(MAX(n,min),max)

static inline float map(float n, float minIn, float maxIn, float minOut, float maxOut)
{
    float inRange = maxIn - minIn;
    float outRange = maxOut - minOut;
    float scalarN = (n-minIn) / inRange;
    return minOut + (outRange * scalarN);
}

#define GLKVector2Zero  GLKVector2Make(0, 0)

static inline GLKVector2 GLKVector2Random()
{
    float x = (RAND_SCALAR * 2) - 1.0f;
    float y = (RAND_SCALAR * 2) - 1.0f;
    return GLKVector2Normalize(GLKVector2Make(x,y));
}

static inline GLKVector2 GLKVector2Limit(GLKVector2 vec, float max)
{
    float vecLength = GLKVector2Length(vec);
    if(vecLength > max){
        float ratio = max / vecLength;
        return GLKVector2Multiply(vec, GLKVector2Make(ratio,ratio));
    }
    return vec;
}

#endif

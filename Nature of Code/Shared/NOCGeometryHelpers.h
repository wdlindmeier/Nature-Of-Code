//
//  NOCOpenGLHelpers.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "CGGeometry.h"
#import "NOCOpenGLHelpers.h"

#define f(n)    [n floatValue]

#ifndef Nature_of_Code_NOCOpenGLHelpers_h
#define Nature_of_Code_NOCOpenGLHelpers_h

#define CONSTRAIN(n,min,max)    MIN(MAX(n,min),max)

// NOTE: What's the right way of defining this variable
// so I don't get "Unused" compiler warnings?
static float __unused kGravity = 0.4f;

// A cube for 3D rendering.
// This is geometry and normals.
static const GLfloat kCubeVertexData[216] =
{
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,          1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
};

// A flat square.
static const GLfloat kSquare3DBillboardVertexData[12] =
{
    -0.5f, -0.5f, 0.0f,
    0.5f, -0.5f, 0.0f,
    -0.5f, 0.5f, 0.0f,
    0.5f, 0.5f, 0.0f,
};

// A flat square covering the screen minus the aspect
static const GLfloat kFullSquare3DBillboardVertexData[12] =
{
    -1.f, -1.f, 0.0f,
    1.f, -1.f, 0.0f,
    -1.f, 1.f, 0.0f,
    1.f, 1.f, 0.0f,
};

// 2D Texture coords for billboard rendering.
static const GLfloat kSquare3DTexCoords[8] =
{
    0.f, 1.f,
    1.f, 1.f,
    0.f, 0.f,
    1.f, 0.f
};

// Same as CubeVertexData w/out normals
static const GLfloat kCubeFilledVertexData[108] =
{
    0.5f, -0.5f, -0.5f,
    0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    0.5f, 0.5f, 0.5f,
    
    0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
    0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    -0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    
    -0.5f, 0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, 0.5f,
    
    -0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    
    0.5f, 0.5f, 0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    
    0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    0.5f, 0.5f, -0.5f,
    0.5f, 0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
};

// Cube geometry for stroked lines, not triangle fill
static const GLfloat kCubeStrokedVertexData[48] =
{
    -0.5, 0.5, -0.5,
    0.5, 0.5, -0.5,
    0.5, -0.5, -0.5,
    -0.5, -0.5, -0.5,
    -0.5, 0.5, -0.5,
    -0.5, 0.5, 0.5,
    0.5, 0.5, 0.5,
    0.5, -0.5, 0.5,
    -0.5, -0.5, 0.5,
    -0.5, 0.5, 0.5,
    -0.5, -0.5, 0.5,
    -0.5, -0.5, -0.5,
    0.5, -0.5, -0.5,
    0.5, -0.5, 0.5,
    0.5, 0.5, 0.5,
    0.5, 0.5, -0.5
};

static inline float map(float n, float minIn, float maxIn, float minOut, float maxOut)
{
    float inRange = maxIn - minIn;
    float outRange = maxOut - minOut;
    float scalarN = (n-minIn) / inRange;
    float ret = minOut + (outRange * scalarN);
    if(isinf(ret) || isnan(ret)){
        ret = maxOut;
    }else{
        ret = CONSTRAIN(ret, minOut, maxOut);
    }
    return ret;
}

#define GLKVector2Zero  GLKVector2Make(0, 0)
#define GLKVector3Zero  GLKVector3Make(0, 0, 0)

static inline GLKVector2 GLKVector2Random()
{
    float x = (RAND_SCALAR * 2) - 1.0f;
    float y = (RAND_SCALAR * 2) - 1.0f;
    return GLKVector2Normalize(GLKVector2Make(x,y));
}

static inline GLKVector3 GLKVector3Random()
{
    float x = (RAND_SCALAR * 2) - 1.0f;
    float y = (RAND_SCALAR * 2) - 1.0f;
    float z = (RAND_SCALAR * 2) - 1.0f;
    return GLKVector3Normalize(GLKVector3Make(x,y,z));
}

static inline GLKVector2 GLKVector2Normal(GLKVector2 vec)
{
    return GLKVector2Make(vec.y * -1, vec.x);
}

static inline GLKVector2 GLKVector2Limit(GLKVector2 vec, float max)
{
    float vecLength = GLKVector2Length(vec);
    if(vecLength > max){
        float ratio = max / vecLength;
        return GLKVector2MultiplyScalar(vec, ratio);
    }
    return vec;
}

static inline GLKVector3 GLKVector3Limit(GLKVector3 vec, float max)
{
    float vecLength = GLKVector3Length(vec);
    if(vecLength > max){
        float ratio = max / vecLength;
        return GLKVector3MultiplyScalar(vec, ratio);
    }
    return vec;
}

static inline BOOL GLKVector2Equal(GLKVector2 vecA, GLKVector2 vecB)
{
    return vecA.x == vecB.x && vecA.y == vecB.y;
}

static inline BOOL GLKVector3Equal(GLKVector3 vecA, GLKVector3 vecB)
{
    return vecA.x == vecB.x && vecA.y == vecB.y && vecA.z == vecB.z;
}

static inline NOCBox3D NOCBox3DMake(float originX, float originY, float originZ,
                                    float width, float height, float depth)
{
    NOCBox3D box;
    box.origin = GLKVector3Make(originX, originY, originZ);
    box.size = GLKVector3Make(width, height, depth);
    return box;
}

#endif

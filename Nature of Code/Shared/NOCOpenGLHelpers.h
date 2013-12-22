//
//  NOCOpenGLHelpers.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

typedef struct {
    GLKVector3 size;
    GLKVector3 origin;
} NOCBox3D;


static GLKTextureInfo * NOCLoadGLTextureWithImage(UIImage *texImage);
static GLKTextureInfo * NOCLoadGLTextureWithName(NSString *texName);
static inline void NOCPrintGLError();

static inline GLKTextureInfo * NOCLoadGLTextureWithImage(UIImage *texImage)
{
    // Clear the error in case there's anything in the pipes.
    glGetError();
    NSError *texError = nil;
    GLKTextureInfo *tex = [GLKTextureLoader textureWithCGImage:texImage.CGImage
                                                       options:nil
                                                         error:&texError];
    if(texError){
        NSLog(@"ERROR: Could not load the texture: %@", texError);
        NOCPrintGLError();
        return nil;
    }
    return tex;
};

static inline GLKTextureInfo * NOCLoadGLTextureWithName(NSString *texName)
{
    return NOCLoadGLTextureWithImage([UIImage imageNamed:texName]);
};

static inline void NOCPrintGLError()
{
    GLenum error = glGetError();
    switch (error) {
        case GL_NO_ERROR:
            NSLog(@"GL_NO_ERROR");
            break;
        case GL_INVALID_ENUM:
            NSLog(@"GL_INVALID_ENUM");
            break;
        case GL_INVALID_VALUE:
            NSLog(@"GL_INVALID_VALUE");
            break;
        case GL_INVALID_OPERATION:
            NSLog(@"GL_INVALID_OPERATION");
            break;
        case GL_INVALID_FRAMEBUFFER_OPERATION:
            NSLog(@"GL_INVALID_FRAMEBUFFER_OPERATION");
            break;
        case GL_OUT_OF_MEMORY:
            NSLog(@"GL_OUT_OF_MEMORY");
            break;
        case GL_STACK_UNDERFLOW:
            NSLog(@"GL_STACK_UNDERFLOW");
            break;
        case GL_STACK_OVERFLOW:
            NSLog(@"GL_STACK_OVERFLOW");
            break;
    }
};

static inline GLKVector2 NOCGLPositionInWorldFrameFromCGPointInRect(CGRect worldFrame, CGPoint screenPoint, CGRect viewRect);

// Assumes that the GL world coords are -1..1 1..-1 / aspect
static inline GLKVector2 NOCGLPositionFromCGPointInRect(CGPoint screenPoint, CGRect viewRect)
{
    float aspect = viewRect.size.width / viewRect.size.height;
    // NOTE: The GL Y axis is opposite from the screen Y axis
    return NOCGLPositionInWorldFrameFromCGPointInRect(CGRectMake(-1, 1/aspect,
                                                                 2, (2/aspect*-1)),
                                                                 screenPoint,
                                                                 viewRect);
}

static inline GLKVector2 NOCGLPositionInWorldFrameFromCGPointInRect(CGRect worldFrame, CGPoint screenPoint, CGRect viewRect)
{
    CGSize sizeView = viewRect.size;
    float scalarX = (screenPoint.x - viewRect.origin.x) / sizeView.width;
    float scalarY = 1.0 - ((screenPoint.y - viewRect.origin.y) / sizeView.height);
    float widthWorld = worldFrame.size.width;
    float heightWorld = worldFrame.size.height;
    float glX = worldFrame.origin.x + (scalarX * widthWorld);
    float glY = worldFrame.origin.y + (scalarY * heightWorld);
    return GLKVector2Make(glX, glY);
}

static inline GLKVector2 NOCGLKVector2Normal(GLKVector2 vec)
{
    GLKVector2 nVec = GLKVector2Normalize(vec);
    return GLKVector2Make(nVec.y * -1, nVec.x);
}

static inline void NOCSetGLVertCoordsForRect(GLfloat *glCoords, CGRect rect)
{
    float x1 = rect.origin.x;
    float x2 = rect.origin.x + rect.size.width;
    float y1 = rect.origin.y;
    float y2 = rect.origin.y + rect.size.height;
    
    glCoords[0] = x1;
    glCoords[1] = y1;
    glCoords[2] = 0;
    
    glCoords[3] = x2;
    glCoords[4] = y1;
    glCoords[5] = 0;
    
    glCoords[6] = x1;
    glCoords[7] = y2;
    glCoords[8] = 0;
    
    glCoords[9] = x2;
    glCoords[10] = y2;
    glCoords[11] = 0;
    
}

static inline GLKVector3 NOCSurfaceNormalForTriangle(GLKVector3 ptA, GLKVector3 ptB, GLKVector3 ptC)
{
    GLKVector3 vector1 = GLKVector3Subtract(ptB,ptA);
    GLKVector3 vector2 = GLKVector3Subtract(ptC,ptA);
    GLKVector3Normalize(GLKVector3CrossProduct(vector1, vector2));
    return GLKVector3Normalize(GLKVector3CrossProduct(vector1, vector2));
}

typedef enum WallSides {
    WallSideNone = 0,
    WallSideBack,
    WallSideFront,
    WallSideLeft,
    WallSideRight,
    WallSideTop,
    WallSideBottom
} WallSide;

static inline BOOL NOCBox3DContainsPoint(NOCBox3D box, GLKVector3 point)
{
    return point.x >= box.origin.x &&
    point.y >= box.origin.y &&
    point.z >= box.origin.z &&
    point.x <= box.origin.x + box.size.x &&
    point.y <= box.origin.y + box.size.y &&
    point.z <= box.origin.z + box.size.z;
}

static inline GLKVector3 NOCVecModBox3D(GLKVector3 point, NOCBox3D box)
{
    float x = point.x;
    float y = point.y;
    float z = point.z;
    
    float maxX = box.origin.x + box.size.x;
    if(x < box.origin.x) x = maxX + fmod(x - box.origin.x, box.size.x * -1);
    else if(x > maxX) x = box.origin.x + fmod(x - maxX, box.size.x);
    
    float maxY = box.origin.y + box.size.y;
    if(y < box.origin.y) y = maxY + fmod(y - box.origin.y, box.size.y * -1);
    else if(y > maxY) y = box.origin.y + fmod(y - maxY, box.size.y);
    
    float maxZ = box.origin.z + box.size.z;
    if(z < box.origin.z) z = maxZ + fmod(z - box.origin.z, box.size.z * -1);
    else if(z > maxZ) z = box.origin.z + fmod(z - maxZ, box.size.z);
    
    return GLKVector3Make(x, y, z);
    
}

static inline GLKMatrix4 GLKMatrix4AlignWithVector3Heading(GLKMatrix4 mat, GLKVector3 vecHeading)
{
    GLKVector3 zAxis = GLKVector3Make(0, 0, -1);
    GLKVector3 vecAlign = GLKVector3Make(vecHeading.x, vecHeading.y, vecHeading.z * -1);
    float rotRads = acos(GLKVector3DotProduct(vecAlign, zAxis));
    if( fabs(rotRads) > 0.00001 )
    {
        GLKVector3 rotAxis = GLKVector3Normalize(GLKVector3CrossProduct(vecAlign, zAxis));
        GLKQuaternion quat = GLKQuaternionMakeWithAngleAndAxis(rotRads, rotAxis.x, rotAxis.y, rotAxis.z);
        GLKMatrix4 matRot = GLKMatrix4MakeWithQuaternion(quat);
        mat = GLKMatrix4Multiply(mat, matRot);
    }
    return mat;
}

static inline GLKMatrix4 GLKMatrix4Lerp(GLKMatrix4 matLeft, GLKMatrix4 matRight, float amount)
{
    GLKMatrix4 matDelta = GLKMatrix4Subtract(matLeft, matRight);
    GLKMatrix4 matBlend = matLeft;
    for(int i=0;i<16;i++){
        matBlend.m[i] -= matDelta.m[i] * amount;
    }
    return matBlend;
}

static inline GLKMatrix4 GLKMatrix4Divide(GLKMatrix4 mat, float divisor)
{
    GLKMatrix4 m;
    
    m.m[0] = mat.m[0] / divisor;
    m.m[1] = mat.m[1] / divisor;
    m.m[2] = mat.m[2] / divisor;
    m.m[3] = mat.m[3] / divisor;
    
    m.m[4] = mat.m[4] / divisor;
    m.m[5] = mat.m[5] / divisor;
    m.m[6] = mat.m[6] / divisor;
    m.m[7] = mat.m[7] / divisor;
    
    m.m[8] = mat.m[8] / divisor;
    m.m[9] = mat.m[9] / divisor;
    m.m[10] = mat.m[10] / divisor;
    m.m[11] = mat.m[11] / divisor;
    
    m.m[12] = mat.m[12] / divisor;
    m.m[13] = mat.m[13] / divisor;
    m.m[14] = mat.m[14] / divisor;
    m.m[15] = mat.m[15] / divisor;
    
    return m;
}
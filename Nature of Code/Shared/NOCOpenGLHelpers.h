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


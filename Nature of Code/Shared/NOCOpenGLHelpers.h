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
}


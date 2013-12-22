//
//  NOCFrameBuffer.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFrameBuffer.h"
#import "NOCUIKitHelpers.h"
#import "NOCOpenGLHelpers.h"

@implementation NOCFrameBuffer
{
    GLuint _locFramebuffer;
    GLuint _locRenderbuffer;
    GLuint _locRenderTexture;
}

@synthesize size = _size;
@synthesize locFramebuffer = _locFramebuffer;
@synthesize locRenderbuffer = _locRenderbuffer;
@synthesize locRenderTexture = _locRenderTexture;

#pragma mark - Init

- (id)initWithPixelWidth:(int)width pixelHeight:(int)height
{
    self = [super init];
    
    if(self){
        
        _size = CGSizeMake(width, height);
        
        // Offscreen position framebuffer object
        glGenFramebuffers(1, &_locFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _locFramebuffer);
        
        glGenRenderbuffers(1, &_locRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _locRenderbuffer);
        
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, _size.width, _size.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _locRenderbuffer);
        
        // Offscreen position framebuffer texture target
        glGenTextures(1, &_locRenderTexture);
        glBindTexture(GL_TEXTURE_2D, _locRenderTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _size.width, _size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        glBindTexture(GL_TEXTURE_2D, 0);

        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _locRenderTexture, 0);
        
        // Always check that our framebuffer is ok
        if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE){
            NSLog(@"ERROR: Could not create framebuffer");
            NOCPrintGLError();
        }
        
    }
    
    return self;
    
}

#pragma mark - Binding

- (void)bind
{
    glBindFramebuffer(GL_FRAMEBUFFER, _locFramebuffer);
    glViewport(0, 0, _size.width, _size.height);
}

- (GLuint)bindTexture:(int)texLoc
{
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(texLoc);
    glBindTexture(GL_TEXTURE_2D, self.locRenderTexture);
    return self.locRenderTexture;
}

#pragma mark - Accessing Data

- (void)pixelValuesInRect:(CGRect)cropRect buffer:(GLubyte *)pixelBuffer
{
    GLint width = cropRect.size.width;
    GLint height = cropRect.size.height;
    glReadPixels(cropRect.origin.x, cropRect.origin.y,
                 width, height,
                 GL_RGBA, GL_UNSIGNED_BYTE, pixelBuffer);
}

- (UIImage *)imageAtRect:(CGRect)cropRect
{
    GLint width = cropRect.size.width;
    GLint height = cropRect.size.height;

    NSInteger myDataLength = width * height * 4;
    
    // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    
    [self pixelValuesInRect:cropRect buffer:buffer];
    
    return [UIImage imageWithBuffer:buffer ofSize:cropRect.size];
}

@end
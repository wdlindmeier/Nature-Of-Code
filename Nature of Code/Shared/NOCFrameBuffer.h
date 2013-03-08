//
//  NOCFrameBuffer.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NOCFrameBuffer : NSObject

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) GLuint locFramebuffer;
@property (nonatomic, readonly) GLuint locRenderbuffer;
@property (nonatomic, readonly) GLuint locRenderTexture;

- (id)initWithPixelWidth:(int)width pixelHeight:(int)height;

- (void)bind;
- (GLuint)bindTexture:(int)texLoc;
- (UIImage *)imageAtRect:(CGRect)cropRect;
- (void)pixelValuesInRect:(CGRect)cropRect buffer:(GLubyte *)pixelBuffer;

@end

//
//  NOCOpenGLTypes.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef struct {
    CGPoint geometryVertex;
    CGPoint textureVertex;
} GLTexturedVertex;

typedef struct {
    GLTexturedVertex bl;
    GLTexturedVertex br;
    GLTexturedVertex tl;
    GLTexturedVertex tr;
} GLTexturedQuad;
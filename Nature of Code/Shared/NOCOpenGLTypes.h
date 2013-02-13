//
//  NOCOpenGLTypes.h
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

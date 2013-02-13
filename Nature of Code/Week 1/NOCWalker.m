//
//  NOCWalker.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCWalker.h"
#import "NOCGeometryHelpers.h"
#import <GLKit/GLKit.h>

// Walker Shape
GLfloat walkerVertexData[12] =
{
    // positionX, positionY, positionZ
    -0.5f, -0.5f, 0.0f,
    0.5f, -0.5f, 0.0f,
    -0.5f, 0.5f, 0.0f,
    0.5f, 0.5f, 0.0f,
    
};

// Walker Color
// The alpha is only relevant if blending is enabled w/ glEnable(GL_BLEND)
GLfloat walkerColorData[16] =
{
    // r, g, b, alpha
    1.0f, 1.0, 1.0, 0.5f,
    1.0f, 1.0, 1.0, 0.5f,
    1.0f, 1.0, 1.0, 0.5f,
    1.0f, 1.0, 1.0, 0.5f,
    
};

@implementation NOCWalker


- (void)render
{
    // Draw a colored square
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &walkerVertexData);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &walkerColorData);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

}

@end

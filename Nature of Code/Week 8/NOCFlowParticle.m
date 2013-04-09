//
//  NOCFlowParticle.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFlowParticle.h"

@implementation NOCFlowParticle
{
    float _angle;
}

- (id)initWithSize:(GLKVector2)size position:(GLKVector2)position
{
    self = [super initWithSize:size position:position];
    if(self){
        _angle = 0;
    }
    return self;
}

- (GLKMatrix4)modelMatrix
{
    GLKMatrix4 modelMat = [super modelMatrix];
    return GLKMatrix4Rotate(modelMat, _angle, 0, 0, 1);
}

- (void)step
{
    GLKVector2 prevPos = self.position;
    [super step];
    GLKVector2 posDelta = GLKVector2Subtract(prevPos, self.position);
    _angle = RadiansFromVector(CGPointMake(posDelta.x, posDelta.y)) - (M_PI * 0.5);
}

// Basic draw textured square
/*
- (void)render
{
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    GLfloat color[16];
    for(int i=0;i<4;i++){
        color[i*4+0] = 1.0;
        color[i*4+1] = 0.0;
        color[i*4+2] = 0.0;
        color[i*4+3] = 1.0;
    };
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &Square3DBillboardVertexData);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &color);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}
*/

@end

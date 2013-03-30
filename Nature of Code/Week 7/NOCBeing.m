//
//  NOCBeing.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCBeing.h"

@implementation NOCBeing

- (id)initWithRadius:(float)radius position:(GLKVector3)position mass:(float)mass
{
    // We'll use the dimension to create a size, but it won't be strictly accurate
    float dimension = radius * 2;
    self = [super initWithSize:GLKVector3Make(dimension, dimension, dimension)
                      position:position
                          mass:mass];
    if(self){
        self.radius = radius;
    }
    return self;
}

- (void)step
{
    [super step];
    const float friction = -0.01;
    self.velocity = GLKVector3MultiplyScalar(self.velocity, 1.0 + friction);
}

// Ported from Cinder gl::drawSphere
- (void)render
{
    // NOTE: This could be determined by the distance from camera.
    const static int segments = 32;
    
    // TODO: This geometry should be cached for better performance
    
    float verts[(segments+1)*2*3];
    float normals[(segments+1)*2*3];
    float texCoords[(segments+1)*2*2];
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &verts);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, &normals);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &texCoords);

    for( int j = 0; j < segments / 2; j++ ) {
        float theta1 = j * 2 * 3.14159f / segments - ( 3.14159f / 2.0f );
        float theta2 = (j + 1) * 2 * 3.14159f / segments - ( 3.14159f / 2.0f );
        
        for( int i = 0; i <= segments; i++ ) {

            GLKVector3 e, p;
            
            float theta3 = i * 2 * 3.14159f / segments;

            e.x = cos( theta1 ) * cos( theta3 );
            e.y = sin( theta1 );
            e.z = cos( theta1 ) * sin( theta3 );
            
            p = GLKVector3MultiplyScalar(e, 0.5);
            
            normals[i*3*2+0] = e.x; normals[i*3*2+1] = e.y; normals[i*3*2+2] = e.z;
            texCoords[i*2*2+0] = 0.999f - i / (float)segments; texCoords[i*2*2+1] = 0.999f - 2 * j / (float)segments;
            verts[i*3*2+0] = p.x; verts[i*3*2+1] = p.y; verts[i*3*2+2] = p.z;
            
            e.x = cos( theta2 ) * cos( theta3 );
            e.y = sin( theta2 );
            e.z = cos( theta2 ) * sin( theta3 );
            
            p = GLKVector3MultiplyScalar(e, 0.5);
            
            normals[i*3*2+3] = e.x; normals[i*3*2+4] = e.y; normals[i*3*2+5] = e.z;
            texCoords[i*2*2+2] = 0.999f - i / (float)segments; texCoords[i*2*2+3] = 0.999f - 2 * ( j + 1 ) / (float)segments;
            verts[i*3*2+3] = p.x; verts[i*3*2+4] = p.y; verts[i*3*2+5] = p.z;
        }
        glDrawArrays( GL_TRIANGLE_STRIP, 0, (segments + 1)*2 );
    }
}

@end

//
//  NOCMover.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCMover.h"

// Mover Shape
GLfloat moverVertexData[12] =
{
    // positionX, positionY, positionZ
    -0.5f, -0.5f, 0.0f,
    0.5f, -0.5f, 0.0f,
    -0.5f, 0.5f, 0.0f,
    0.5f, 0.5f, 0.0f,
    
};

// Mover Color
// The alpha is only relevant if blending is enabled w/ glEnable(GL_BLEND)
GLfloat moverTexCoords[8] =
{
    0.f, 1.f,
    1.f, 1.f,
    0.f, 0.f,
    1.f, 0.f
    
};

@implementation NOCMover

- (id)initWithSize:(CGSize)size position:(GLKVector2)position
{
    self = [super initWithSize:size position:position];
    if(self){
        self.velocity = GLKVector2Zero;
        self.acceleration = GLKVector2Zero;
        self.maxVelocity = 5.0f;
    }
    return self;
}

- (void)stepInRect:(CGRect)rect
{
    // Accelleration is handled in the sketch
    
    // Add accel to velocity
    self.velocity = GLKVector2Add(self.velocity, self.acceleration);
    
    // Add velocity to location
    self.position = GLKVector2Add(self.position, self.velocity);
    
    // Limit the velocity
    self.velocity = GLKVector2Limit(self.velocity, self.maxVelocity);

    // Wrap the mover around the rect
    float x = self.position.x;
    float y = self.position.y;
    
    float minX = rect.origin.x / self.size.width;
    float maxX = (rect.origin.x + rect.size.width) / self.size.width;
    if(x < minX) x = maxX + (x - minX);
    else if(x > maxX) x = minX + (x - maxX);
    
    float minY = rect.origin.y / self.size.height;
    float maxY = (rect.origin.y + rect.size.height) / self.size.height;
    if(y < minY) y = maxY + (y - minY);
    else if(y > maxY) y = minY + (y - maxY);
    
    self.position = GLKVector2Make(x, y);
}

- (void)render
{
    // Draw a colored square
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &moverVertexData);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &moverTexCoords);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);   
}

@end

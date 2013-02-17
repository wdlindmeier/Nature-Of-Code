//
//  NOCMover.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCMover2D.h"
#import "NOCGeometryHelpers.h"

// Mover Shape
// A simple square
GLfloat mover2DVertexData[12] =
{
    // positionX, positionY, positionZ
    -0.5f, -0.5f, 0.0f,
    0.5f, -0.5f, 0.0f,
    -0.5f, 0.5f, 0.0f,
    0.5f, 0.5f, 0.0f,
    
};

// Mover Texture coords
// A square texture
GLfloat mover2DTexCoords[8] =
{
    0.f, 1.f,
    1.f, 1.f,
    0.f, 0.f,
    1.f, 0.f    
};

@implementation NOCMover2D

- (id)initWithSize:(GLKVector2)size position:(GLKVector2)position mass:(float)mass
{
    self = [super initWithSize:size position:position];
    if(self){
        self.velocity = GLKVector2Zero;
        self.acceleration = GLKVector2Zero;
        self.maxVelocity = 5.0f;
        self.mass = mass;
    }
    return self;
}

#pragma mark - Force

- (void)applyForce:(GLKVector2)vecForce
{
    self.acceleration = GLKVector2Add(self.acceleration, vecForce);
}

- (GLKVector2)forceOnPositionedMass:(id<NOCPositionedMass2D>)positionedMass
{
    GLKVector2 vecDir = GLKVector2Subtract(positionedMass.position, self.position);
    float magnitude = GLKVector2Length(vecDir);
    vecDir = GLKVector2Normalize(vecDir);
    float forceMagnitude = (Gravity * self.mass * positionedMass.mass) / (magnitude * magnitude);
    GLKVector2 vecForce = GLKVector2MultiplyScalar(vecDir, forceMagnitude);
    return vecForce;
}

#pragma mark - Update

- (void)stepInRect:(CGRect)rect shouldWrap:(BOOL)shouldWrap
{    
    // Add accel to velocity
    self.velocity = GLKVector2Add(self.velocity, self.acceleration);
    
    // Add velocity to location
    GLKVector2 projectedPosition = GLKVector2Add(self.position, self.velocity);
    float x = projectedPosition.x;
    float y = projectedPosition.y;
    
    // Limit the velocity
    self.velocity = GLKVector2Limit(self.velocity, self.maxVelocity);
    
    float minX = rect.origin.x;
    float maxX = (rect.origin.x + rect.size.width);
    float minY = rect.origin.y;
    float maxY = (rect.origin.y + rect.size.height);

    if(shouldWrap){
        // Wrap the mover around the rect
        if(x < minX) x = maxX + (x - minX);
        else if(x > maxX) x = minX + (x - maxX);
        
        if(y < minY) y = maxY + (y - minY);
        else if(y > maxY) y = minY + (y - maxY);
    }else{
        // Constrain
        // Dont let the walker move outside of the rect.
        x = CONSTRAIN(x, minX, maxX);
        y = CONSTRAIN(y, minY, maxY);
    }
    
    self.position = GLKVector2Make(x, y);
    
    // Reset the acceleration
    self.acceleration = GLKVector2Zero;
}

#pragma mark - Draw

- (void)render
{
    
    // Draw a colored square
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &mover2DVertexData);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &mover2DTexCoords);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);   
}

@end

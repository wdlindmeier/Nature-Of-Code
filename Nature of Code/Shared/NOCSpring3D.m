//
//  NOCSpring3D.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/17/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSpring3D.h"
#import "NOCMover3D.h"

@implementation NOCSpring3D
{
    GLKVector3 _lastMoverPosition;
}

- (id)initWithAnchor:(GLKVector3)anchor restLength:(float)restLength
{
    self = [super init];
    if(self){
        self.minLength = 0;
        self.maxLength = MAXFLOAT;
        self.springiness = 0.1f;
        self.restLength = restLength;
        self.anchor = anchor;
        self.dampening = 0.0f;
    }
    return self;
}

- (void)applySpringToMover:(NOCMover3D *)mover
{
    // Vector pointing from anchor to bob location
    GLKVector3 vecDir = GLKVector3Subtract(mover.position, self.anchor);
    float distance = GLKVector3Length(vecDir);
    
    GLKVector3 springForce = GLKVector3Zero;
    
    if(distance > 0){
    
        // Stretch is difference between current distance and rest length
        float stretch = distance - self.restLength;
        
        // Calculate force according to Hooke's Law
        // F = k * stretch    
        vecDir = GLKVector3Normalize(vecDir);
        
        springForce = GLKVector3MultiplyScalar(vecDir, -1 * self.springiness * stretch);

        // Dampen
        if(self.dampening != 0){
            GLKVector3 vecDampen = GLKVector3MultiplyScalar(mover.velocity, self.dampening);
            springForce = GLKVector3Add(springForce, vecDampen);
        }

    }
    
    [mover applyForce:springForce];
    
}

- (void)constrainMover:(NOCMover3D *)mover
{
    GLKVector3 vecDir = GLKVector3Subtract(mover.position, self.anchor);
    float distance = GLKVector3Length(vecDir);

    BOOL didConstrain = NO;
    
    if (distance < self.minLength) {

        vecDir = GLKVector3Normalize(vecDir);
        vecDir = GLKVector3MultiplyScalar(vecDir, self.minLength);
        didConstrain = YES;

    }else if (distance > self.maxLength) {
        
        vecDir = GLKVector3Normalize(vecDir);
        vecDir = GLKVector3MultiplyScalar(vecDir, self.maxLength);
        didConstrain = YES;
        
    }
    
    if(didConstrain){
        GLKVector3 posMover = GLKVector3Add(self.anchor, vecDir);
        mover.position = posMover;
        mover.velocity = GLKVector3Zero;
    }

}

- (void)renderToMover:(NOCMover3D *)mover
{
    GLfloat line[6] = {
        self.anchor.x, self.anchor.y, self.anchor.z,
        mover.position.x, mover.position.y, mover.position.z
    };
    
    // Draw a stroked line
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &line);
    int numCoords = sizeof(line) / sizeof(GLfloat) / 3;
    glDrawArrays(GL_LINE_LOOP, 0, numCoords);

}

@end

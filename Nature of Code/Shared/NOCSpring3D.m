//
//  NOCSpring3D.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSpring3D.h"
#import "NOCParticle3D.h"

@implementation NOCSpring3D

- (id)initWithParicle:(NOCParticle *)p anchor:(GLKVector3)anchor restLength:(float)restLength
{
    self = [super initWithParicleA:nil particleB:p restLength:restLength];
    if(self){
        self.anchor = anchor;
        _hasAnchor = YES;
    }
    return self;
}

// A helper to deal w/ anchor vs particle
- (void)getPosA:(GLKVector3 *)posA posB:(GLKVector3 *)posB
{
    NOCParticle3D*pA = (NOCParticle3D*)self.particleA;
    NOCParticle3D*pB = (NOCParticle3D*)self.particleB;
    
    *posB = pB.position;
    if([self hasAnchor]){
        *posA = self.anchor;
    }else{
        *posA = pA.position;
    }
}

- (void)applyForceToParticles
{
    [super applyForceToParticles];
    
    // Vector pointing from anchor to bob location
    NOCParticle3D*pA = (NOCParticle3D*)self.particleA;
    NOCParticle3D*pB = (NOCParticle3D*)self.particleB;
    
    GLKVector3 posA, posB;
    [self getPosA:&posA posB:&posB];
    
    GLKVector3 vecDir = GLKVector3Subtract(posB, posA);
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
            
            // This just applied forecs in the opposite direction of the vector
            GLKVector3 vecDampenA = GLKVector3MultiplyScalar(pA.velocity, self.dampening);
            GLKVector3 springForceA = GLKVector3Add(springForce, vecDampenA);
            [pA applyForce:springForceA];
            
            GLKVector3 vecDampenB = GLKVector3MultiplyScalar(pB.velocity, self.dampening);
            GLKVector3 springForceB = GLKVector3Add(springForce, vecDampenB);
            [pB applyForce:springForceB];
            
        }else{
            
            [pA applyForce:springForce];
            
            [pB applyForce:springForce];
            
        }
        
    }
    
    
}

- (void)constrainParticles
{
    // Vector pointing from anchor to bob location
    NOCParticle3D*pA = (NOCParticle3D*)self.particleA;
    NOCParticle3D*pB = (NOCParticle3D*)self.particleB;
    
    GLKVector3 posA, posB;
    [self getPosA:&posA posB:&posB];
    
    GLKVector3 vecDir = GLKVector3Subtract(posB, posA);
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
        
        // Take all of the constraint out on particleB
        GLKVector3 posParticle = GLKVector3Add(posA, vecDir);
        pB.position = posParticle;
        
        pB.velocity = GLKVector3Zero;
        pA.velocity = GLKVector3Zero;
        
    }
    
}

- (void)render
{
    GLKVector3 posA, posB;
    [self getPosA:&posA posB:&posB];
    
    GLfloat line[6] = {
        posA.x, posA.y, posA.z,
        posB.x, posB.y, posB.z,
    };
    
    // Draw a stroked line
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &line);
    int numCoords = sizeof(line) / sizeof(GLfloat) / 3;
    glDrawArrays(GL_LINE_LOOP, 0, numCoords);
    
}

@end

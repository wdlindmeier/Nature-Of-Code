//
//  NOCSpring2D.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSpring2D.h"
#import "NOCParticle2D.h"

@implementation NOCSpring2D

- (id)initWithParicle:(NOCParticle *)p anchor:(GLKVector2)anchor restLength:(float)restLength
{
    self = [super initWithParicleA:nil particleB:p restLength:restLength];
    if(self){
        self.anchor = anchor;
        _hasAnchor = YES;
    }
    return self;
}

// A helper to deal w/ anchor vs particle
- (void)getPosA:(GLKVector2 *)posA posB:(GLKVector2 *)posB
{
    NOCParticle2D*pA = (NOCParticle2D*)self.particleA;
    NOCParticle2D*pB = (NOCParticle2D*)self.particleB;
    
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
    NOCParticle2D*pA = (NOCParticle2D*)self.particleA;
    NOCParticle2D*pB = (NOCParticle2D*)self.particleB;
    
    GLKVector2 posA, posB;
    [self getPosA:&posA posB:&posB];
    
    GLKVector2 vecDir = GLKVector2Subtract(posB, posA);
    float distance = GLKVector2Length(vecDir);
    
    GLKVector2 springForce = GLKVector2Zero;
    
    if(distance > 0){
        
        // Stretch is difference between current distance and rest length
        float stretch = distance - self.restLength;
        
        // Calculate force according to Hooke's Law
        // F = k * stretch
        vecDir = GLKVector2Normalize(vecDir);
        
        springForce = GLKVector2MultiplyScalar(vecDir, -1 * self.springiness * stretch);
        
        // Dampen
        if(self.dampening != 0){
            
            // This just applied forecs in the opposite direction of the vector
            GLKVector2 vecDampenA = GLKVector2MultiplyScalar(pA.velocity, self.dampening);
            GLKVector2 springForceA = GLKVector2Add(springForce, vecDampenA);
            [pA applyForce:springForceA];
            
            GLKVector2 vecDampenB = GLKVector2MultiplyScalar(pB.velocity, self.dampening);
            GLKVector2 springForceB = GLKVector2Add(springForce, vecDampenB);
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
    NOCParticle2D*pA = (NOCParticle2D*)self.particleA;
    NOCParticle2D*pB = (NOCParticle2D*)self.particleB;
    
    GLKVector2 posA, posB;
    [self getPosA:&posA posB:&posB];
    
    GLKVector2 vecDir = GLKVector2Subtract(posB, posA);
    float distance = GLKVector2Length(vecDir);
    
    BOOL didConstrain = NO;
    
    if (distance < self.minLength) {
        
        vecDir = GLKVector2Normalize(vecDir);
        vecDir = GLKVector2MultiplyScalar(vecDir, self.minLength);
        didConstrain = YES;
        
    }else if (distance > self.maxLength) {
        
        vecDir = GLKVector2Normalize(vecDir);
        vecDir = GLKVector2MultiplyScalar(vecDir, self.maxLength);
        didConstrain = YES;
    }
    
    if(didConstrain){

        // Take all of the constraint out on particleB
        GLKVector2 posParticle = GLKVector2Add(posA, vecDir);
        pB.position = posParticle;

        pB.velocity = GLKVector2Zero;
        pA.velocity = GLKVector2Zero;
        
    }
    
}

- (void)render
{
    GLKVector2 posA, posB;
    [self getPosA:&posA posB:&posB];
    
    GLfloat line[6] = {
        posA.x, posA.y, 0,
        posB.x, posB.y, 0,
    };
    
    // Draw a stroked line
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &line);
    int numCoords = sizeof(line) / sizeof(GLfloat) / 3;
    glDrawArrays(GL_LINE_LOOP, 0, numCoords);
    
}

@end

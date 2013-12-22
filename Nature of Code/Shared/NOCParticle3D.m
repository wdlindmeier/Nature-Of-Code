//
//  NOCParticle3D.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCParticle3D.h"
#import "NOCOpenGLHelpers.h"
#import "NOCGeometryHelpers.h"

@implementation NOCParticle3D

#pragma mark - Init

- (id)initWithSize:(GLKVector3)size position:(GLKVector3)position
{
    self = [super init];
    if(self){
        self.size = size;
        self.position = position;
        self.maxVelocity = 0;
    }
    return self;
}

#pragma mark - Accessors

- (GLKMatrix4)modelMatrix
{
    GLKMatrix4 modelMat = GLKMatrix4Identity;
    
    float scaleX = self.size.x;
    float scaleY = self.size.y;
    float scaleZ = self.size.z;
    
    // NOTE:
    // This assumes the model geometry is on a 1.0 unit scale
    
    modelMat = GLKMatrix4Scale(modelMat,
                               scaleX,
                               scaleY,
                               scaleZ);
    
    modelMat = GLKMatrix4Translate(modelMat,
                                   self.position.x / scaleX,
                                   self.position.y / scaleY,
                                   self.position.z / scaleZ);
    
    return modelMat;
}

#pragma mark - Movement / Update

- (void)applyForce:(GLKVector3)vecForce
{
    if(!self.isLocked){
        
        self.acceleration = GLKVector3Add(self.acceleration, vecForce);
        
    }else{
        
        self.acceleration = GLKVector3Zero;
        
    }
}

- (void)step
{
    [super step];
    
    if(!self.isLocked){
    
        // Add accel to velocity
        self.velocity = GLKVector3Add(self.velocity, self.acceleration);
        
        // Limit the velocity
        if(self.maxVelocity > 0){
            self.velocity = GLKVector3Limit(self.velocity, self.maxVelocity);
        }
        
        // Add velocity to location
        self.position = GLKVector3Add(self.position, self.velocity);
        
    }else{
        
        self.velocity = GLKVector3Zero;
        
    }
    
    // Reset the acceleration
    self.acceleration = GLKVector3Zero;
}

@end

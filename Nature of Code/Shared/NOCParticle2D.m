//
//  NOCParticle2D.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCParticle2D.h"
#import "NOCGeometryHelpers.h"

@implementation NOCParticle2D

#pragma mark - Init

- (id)initWithSize:(GLKVector2)size position:(GLKVector2)position
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
    
    // NOTE:
    // This assumes the model geometry is on a 1.0 unit scale
    
    modelMat = GLKMatrix4Scale(modelMat,
                               scaleX,
                               scaleY,
                               1.0);
    
    modelMat = GLKMatrix4Translate(modelMat,
                                   self.position.x / scaleX,
                                   self.position.y / scaleY,
                                   1.0);
    
    return modelMat;
}

#pragma mark - Movement / Update

- (void)applyForce:(GLKVector2)vecForce
{
    if(!self.isLocked){
        self.acceleration = GLKVector2Add(self.acceleration, vecForce);
    }else{
        self.acceleration = GLKVector2Zero;
    }
}

- (void)step
{
    [super step];
    
    if(!self.isLocked){
        
        // Add accel to velocity
        self.velocity = GLKVector2Add(self.velocity, self.acceleration);
        
        // Limit the velocity
        if(self.maxVelocity > 0){
            self.velocity = GLKVector2Limit(self.velocity, self.maxVelocity);
        }

        // Add velocity to location
        self.position = GLKVector2Add(self.position, self.velocity);
        
    }else{
        
        self.velocity = GLKVector2Zero;
        
    }

    // Reset the acceleration
    self.acceleration = GLKVector2Zero;    
}


@end

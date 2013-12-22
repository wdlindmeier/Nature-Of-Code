//
//  NOCMover3D.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCMover3D.h"

@implementation NOCMover3D

- (id)initWithSize:(GLKVector3)size position:(GLKVector3)position mass:(float)mass
{
    self = [super initWithSize:size position:position];
    if(self){
        self.velocity = GLKVector3Zero;
        self.acceleration = GLKVector3Zero;
        self.maxVelocity = 5.0f;
        self.mass = mass;
    }
    return self;
}

#pragma mark - Accessors

- (GLKVector3)forceOnPositionedMass:(id<NOCPositionedMass3D>)positionedMass
{
    GLKVector3 vecDir = GLKVector3Subtract(positionedMass.position, self.position);
    float magnitude = GLKVector3Length(vecDir);
    vecDir = GLKVector3Normalize(vecDir);
    float forceMagnitude = (kGravity * self.mass * positionedMass.mass) / (magnitude * magnitude);
    GLKVector3 vecForce = GLKVector3MultiplyScalar(vecDir, forceMagnitude);
    return vecForce;
}

#pragma mark - Movement / Update

- (void)stepInBox:(NOCBox3D)box shouldWrap:(BOOL)shouldWrap
{
    [self step];
    
    float x = self.position.x;
    float y = self.position.y;
    float z = self.position.z;

    float minX = box.origin.x;
    float maxX = (box.origin.x + box.size.x);
    float minY = box.origin.y;
    float maxY = (box.origin.y + box.size.y);
    float minZ = box.origin.z;
    float maxZ = (box.origin.z + box.size.z);
    
    if(shouldWrap){
        // Wrap the mover around the rect
        if(x < minX) x = maxX + (x - minX);
        else if(x > maxX) x = minX + (x - maxX);
        
        if(y < minY) y = maxY + (y - minY);
        else if(y > maxY) y = minY + (y - maxY);

        if(z < minZ) z = maxZ + (z - minZ);
        else if(z > maxZ) z = minZ + (z - maxZ);
    }else{
        // Constrain
        // Dont let the walker move outside of the rect.
        x = CONSTRAIN(x, minX, maxX);
        y = CONSTRAIN(y, minY, maxY);
        z = CONSTRAIN(z, minZ, maxZ);
    }
    
    self.position = GLKVector3Make(x, y, z);
}

@end
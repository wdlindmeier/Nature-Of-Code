//
//  NOCParticle3D.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCParticle3D.h"

@implementation NOCParticle3D

- (id)initWithSize:(GLKVector3)size position:(GLKVector3)position
{
    self = [super init];
    if(self){
        self.size = size;
        self.position = position;
    }
    return self;
}


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

- (void)render
{
    // Override in subclass
}

@end

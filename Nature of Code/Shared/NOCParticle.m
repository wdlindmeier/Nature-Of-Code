//
//  NOCParticle.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCParticle.h"

@implementation NOCParticle

- (id)initWithSize:(CGSize)size position:(GLKVector2)position
{
    self = [super init];
    if(self){
        self.size = size;
        self.position = position;
    }
    return self;
}

- (GLKMatrix4)modelMatrixForPixelUnit:(float)pxUnit
{
    GLKMatrix4 modelMat = GLKMatrix4Identity;
    
    modelMat = GLKMatrix4Scale(modelMat,
                               self.size.width * pxUnit,
                               self.size.height * pxUnit,
                               1.0);
    
    modelMat = GLKMatrix4Translate(modelMat,
                                   self.position.x,
                                   self.position.y,
                                   1.0);
    
    return modelMat;
}

- (void)render
{
    // Override in subclass
}

@end

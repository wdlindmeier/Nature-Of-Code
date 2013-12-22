//
//  NOCParticle_.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCParticle.h"
#import "NOCGeometryHelpers.h"

@implementation NOCParticle

- (id)init
{
    self = [super init];
    if(self){
        self.stepLimit = -1;
        self.isLocked = NO;
    }
    return self;
}

- (GLKMatrix4)modelMatrix
{
    // This is handled by the subclass
    return GLKMatrix4Identity;
}

- (void)step
{
    self.stepCount++;
}

- (BOOL)isDead
{
    return self.stepLimit > 0 && self.stepCount >= self.stepLimit;
}

#pragma mark - Draw

// Basic draw textured square
- (void)render
{
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &kSquare3DBillboardVertexData);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &kSquare3DTexCoords);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


@end

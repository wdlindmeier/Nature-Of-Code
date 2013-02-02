//
//  NOCWalker.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCWalker.h"
#import "NOCGeometryHelpers.h"
#import <GLKit/GLKit.h>

GLfloat walkerVertexData[12] =
{
    // positionX, positionY, positionZ
    -0.5f, -0.5f, 0.0f,
    0.5f, -0.5f, 0.0f,
    -0.5f, 0.5f, 0.0f,
    0.5f, 0.5f, 0.0f,
    
};

GLfloat walkerColorData[16] =
{
    1.0f, 1.0, 1.0, 0.5f,
    1.0f, 1.0, 1.0, 0.5f,
    1.0f, 1.0, 1.0, 0.5f,
    1.0f, 1.0, 1.0, 0.5f,
    
};

@implementation NOCWalker

- (id)initWithSize:(CGSize)size position:(CGPoint)position
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

- (void)stepInRect:(CGRect)rect
{
    int moveX = (arc4random() % 3) - 1;
    int moveY = (arc4random() % 3) - 1;
    
    float x = self.position.x + moveX;
    float y = self.position.y + moveY;
    
    // Dont let the walker move outside of the rect.
    // Also scale the rect to the size of the pixel.
    x = CONSTRAIN(x,
                  rect.origin.x / self.size.width,
                  (rect.origin.x + rect.size.width) / self.size.width);
    y = CONSTRAIN(y,
                  rect.origin.y / self.size.height,
                  (rect.origin.y + rect.size.height) / self.size.height);
    
    self.position = CGPointMake(round(x),round(y));
}

- (void)render
{
    // Just draw a square
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &walkerVertexData);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &walkerColorData);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

}

@end

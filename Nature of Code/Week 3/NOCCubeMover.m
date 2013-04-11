//
//  NOCCubeMover.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/17/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCCubeMover.h"


@implementation NOCCubeMover
{
    void *_kvoContextColor;
    GLfloat moverColorData[144];
}

- (id)initWithSize:(GLKVector3)size position:(GLKVector3)position mass:(float)mass
{
    self = [super initWithSize:size position:position mass:mass];
    if(self){
        [self addObserver:self forKeyPath:@"color" options:NSKeyValueObservingOptionNew context:&_kvoContextColor];
        // Initialize the color array
        self.color = [UIColor redColor];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"color"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context == &_kvoContextColor){
        [self updateColorData];
    }
}

- (void)updateColorData
{

    int numComponents = CGColorGetNumberOfComponents(self.color.CGColor);
    
    if (numComponents == 4)
    {
        const CGFloat *components = CGColorGetComponents(self.color.CGColor);
        CGFloat red = components[0];
        CGFloat green = components[1];
        CGFloat blue = components[2];
        CGFloat alpha = components[3];
        for(int i=0;i<36;i++){
            moverColorData[i*4+0] = red;
            moverColorData[i*4+1] = green;
            moverColorData[i*4+2] = blue;
            moverColorData[i*4+3] = alpha;
        }
    }else{
        NSLog(@"ERROR: Could not get 4 color components for Cube Mover");
    }
}

#pragma mark - Draw

- (void)render
{
    // Draw a colored square
    glEnableVertexAttribArray(GLKVertexAttribPosition);    
    glEnableVertexAttribArray(GLKVertexAttribNormal);

    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &moverColorData);
        
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, &CubeVertexData);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, &CubeVertexData[3]);
    glDrawArrays(GL_TRIANGLES, 0, 36);
}

@end

//
//  NOCCubeMover.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/17/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCCubeMover.h"
#import "NOCColorHelpers.h"

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

    CGFloat myColor[4];
    NOCColorComponentsForColor(myColor, self.color);

    for(int i=0;i<36;i++){
        moverColorData[i*4+0] = myColor[0];
        moverColorData[i*4+1] = myColor[1];
        moverColorData[i*4+2] = myColor[2];
        moverColorData[i*4+3] = myColor[3];
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
        
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, &kCubeVertexData);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, &kCubeVertexData[3]);
    glDrawArrays(GL_TRIANGLES, 0, 36);
}

@end

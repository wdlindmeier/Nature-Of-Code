//
//  NOCSceneBox.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSceneBox.h"

@implementation NOCSceneBox
{
    GLfloat _sceneBoxVertexData[48];
    GLfloat _sceneBoxColors[64];
    void *_kvoContextColor;
}

- (id)initWithAspect:(float)aspect
{
    self = [super init];
    if(self){
        [self resizeWithAspect:aspect];
        [self addObserver:self
               forKeyPath:@"color"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextColor];
        self.color = [UIColor whiteColor];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"color"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if(context == &_kvoContextColor){
        [self generateColorArray];
    }
}

- (void)generateColorArray
{
    const CGFloat *myColor = CGColorGetComponents(self.color.CGColor);
    int numColorComponents = CGColorGetNumberOfComponents(self.color.CGColor);
    if(numColorComponents != 4){
        NSLog(@"ERROR: Could not find 4 color components. Found %i", numColorComponents);
    }
    for(int i=0;i<16;i++){
        if(numColorComponents == 4){
            _sceneBoxColors[i*4+0] = myColor[0];
            _sceneBoxColors[i*4+1] = myColor[1];
            _sceneBoxColors[i*4+2] = myColor[2];
            _sceneBoxColors[i*4+3] = myColor[3];
            
        }else{
            _sceneBoxColors[i*4+0] = 1.0f;
            _sceneBoxColors[i*4+1] = 1.0f;
            _sceneBoxColors[i*4+2] = 1.0f;
            _sceneBoxColors[i*4+3] = 1.0f;
        }
    }
}

#pragma mark - Drawing

- (void)resizeWithAspect:(float)aspect
{    
    for(int i =0;i<48;i++){
        float val = CubeStrokedVertexData[i];
        val = val * 2;
        if(i%3==1){
            // This is Y. Scale by the aspect.
            val = val / aspect;
        }
        _sceneBoxVertexData[i] = val;
    }
}

- (void)render
{
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_sceneBoxVertexData);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &_sceneBoxColors);
    
    int numCoords = sizeof(_sceneBoxVertexData) / sizeof(GLfloat) / 3;
    glDrawArrays(GL_LINE_LOOP, 0, numCoords);
    
}

@end

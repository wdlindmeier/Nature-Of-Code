//
//  NOCRandomWalkerSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCRandomWalkerSketchViewController.h"
#import "NOCRandomWalker.h"

@interface NOCRandomWalkerSketchViewController ()
{
    NOCShaderProgram *_shader;
    NOCRandomWalker *_walker;
}

@end

static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * NOCShaderNameRandomWalker = @"RandomWalker";

@implementation NOCRandomWalkerSketchViewController

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiRandomWalker";
}

#pragma mark - Draw Loop

- (void)setup
{
     
    // Setup the shader
    _shader = [[NOCShaderProgram alloc] initWithName:NOCShaderNameRandomWalker];
    
    _shader.attributes = @{
        @"position" : @(GLKVertexAttribPosition),
        @"color" : @(GLKVertexAttribColor)
    };
    
    _shader.uniformNames = @[
        UniformMVProjectionMatrix,
    ];
    
    self.shaders = @{ NOCShaderNameRandomWalker : _shader };
    
    // Setup the Walker    
    _walker = [[NOCRandomWalker alloc] initWithSize:CGSizeMake(10, 10)
                                           position:CGPointMake(0, 0)];
    
}

- (void)resize
{
    [super resize];
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)update
{
    [super update];

    // Update the walker size according to the slider.
    float walkerSize = self.sliderPixelSize.value;
    _walker.size = CGSizeMake(walkerSize, walkerSize);

    // Step w/in the bounds
    CGSize sizeView = self.view.frame.size;
    [_walker stepInRect:CGRectMake(sizeView.width * -0.5,
                                   sizeView.height * -0.5,
                                   sizeView.width,
                                   sizeView.height)];
}

- (void)draw
{
    // NOTE: iPad uses a "double buffer" which causes a flickering effect
    // when you don't clear. If we wanted to leave the trail (like the processing sketch)
    // we could save the previous render buffer into a texture buffer and render that.
    // However, that complicates the sketch a little more than we want.
    
    if(self.switchClearBuffer.on){
        // Clear to gray
        glClearColor(0.2, 0.2, 0.2, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
        
    [_shader use];
    
    // Create the Model View Projection matrix for the shader
    NSNumber *projMatLoc = _shader.uniformLocations[UniformMVProjectionMatrix];
    
    // Get the model matrix
    GLKMatrix4 modelMat = [_walker modelMatrixForPixelUnit:_pxUnit];

    // Multiply by the projection matrix
    GLKMatrix4 mvProjMat = GLKMatrix4Multiply(_projectionMatrix2D, modelMat);
    
    // Pass mvp into shader
    glUniformMatrix4fv([projMatLoc intValue], 1, 0, mvProjMat.m);

    [_walker render];
    
}

- (void)teardown
{
    //...
}

@end

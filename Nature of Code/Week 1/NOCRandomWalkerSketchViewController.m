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
static NSString * ShaderNameRandomWalker = @"RandomWalker";

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
    _shader = [[NOCShaderProgram alloc] initWithName:ShaderNameRandomWalker];
    
    _shader.attributes = @{
        @"position" : @(GLKVertexAttribPosition),
        @"color" : @(GLKVertexAttribColor)
    };
    
    _shader.uniformNames = @[
        UniformMVProjectionMatrix,
    ];
    
    self.shaders = @{ ShaderNameRandomWalker : _shader };
    
    // Setup the Walker    
    _walker = [[NOCRandomWalker alloc] initWithSize:GLKVector2Make(0.01, 0.01)
                                           position:GLKVector2Make(0, 0)];
    
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
    _walker.size = GLKVector2Make(walkerSize, walkerSize);

    // Step w/in the bounds
    CGRect walkerBounds = CGRectMake(-1, -1 / _viewAspect,
                                     2, 2 / _viewAspect);
    [_walker stepInRect:walkerBounds];

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
    GLKMatrix4 modelMat = [_walker modelMatrix];

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

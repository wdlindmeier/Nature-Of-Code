//
//  NOCPerlinWalkerSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/4/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCPerlinWalkerSketchViewController.h"
#import "NOCPerlinWalker.h"

@interface NOCPerlinWalkerSketchViewController ()
{
    NOCShaderProgram *_shader;
    NOCPerlinWalker *_walker;
}

@end

static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * ShaderNamePerlinWalker = @"RandomWalker"; // We'll use the same shader

@implementation NOCPerlinWalkerSketchViewController

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiPerlinWalker";
}

- (IBAction)buttonClearPressed:(id)sender
{
    [self clear];
}

- (IBAction)buttonResetPressed:(id)sender
{
    [self clear];
    _walker.position = GLKVector2Make(0, 0);
}

#pragma mark - Draw Loop

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setup
{
    
    // Setup the shader
    _shader = [[NOCShaderProgram alloc] initWithName:ShaderNamePerlinWalker];
    
    _shader.attributes = @{
        @"position" : @(GLKVertexAttribPosition),
        @"color" : @(GLKVertexAttribColor)
    };
    
    _shader.uniformNames = @[
        UniformMVProjectionMatrix,
    ];
    
    self.shaders = @{ ShaderNamePerlinWalker : _shader };
    
    // Setup the Walker
    _walker = [[NOCPerlinWalker alloc] initWithSize:GLKVector2Make(0.01, 0.01)
                                           position:GLKVector2Make(0,0)];

    // Clear out the values so it takes on the slider values
    _walker.perlinAlpha = 0;
    _walker.perlinBeta = 0;
    _walker.perlinNumOctaves = 0;
    _walker.timeStep = 0;
    
}

- (void)update
{
    [super update];
    
    if(_walker.timeStep != self.sliderTimestep.value){
        _walker.timeStep = self.sliderTimestep.value;
        self.labelTimestep.text = [NSString stringWithFormat:@"%0.3f", _walker.timeStep];
    }
    if(_walker.perlinAlpha != self.sliderAlpha.value){
        _walker.perlinAlpha = self.sliderAlpha.value;
        self.labelAlpha.text = [NSString stringWithFormat:@"%0.3f", _walker.perlinAlpha];
    }
    if(_walker.perlinBeta != self.sliderBeta.value){
        _walker.perlinBeta = self.sliderBeta.value;
        self.labelBeta.text = [NSString stringWithFormat:@"%0.3f", _walker.perlinBeta];
    }
    int octaves = round(self.sliderNumOctaves.value);
    if(_walker.perlinNumOctaves != octaves){
        _walker.perlinNumOctaves = octaves;
        // Make it snap
        self.sliderNumOctaves.value = octaves;
        self.labelNumOctaves.text = [NSString stringWithFormat:@"%i", _walker.perlinNumOctaves];
    }
    
    // Step w/in the bounds
    CGSize sizeView = self.view.frame.size;
    float aspect = sizeView.width / sizeView.height;
    CGRect walkerBounds = CGRectMake(-1, -1 / aspect,
                                     2, 2 / aspect);
    
    [_walker stepInRect:walkerBounds];
    
}

- (void)resize
{
    [super resize];
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)draw
{
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
    //..
}

@end

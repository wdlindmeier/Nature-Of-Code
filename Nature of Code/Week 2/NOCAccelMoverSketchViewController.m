//
//  NOCAccelMoverSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCAccelMoverSketchViewController.h"
#import "NOCShaderProgram.h"
#import "NOCMover2D.h"
#import "NOCGeometryHelpers.h"

@implementation NOCAccelMoverSketchViewController
{
    NOCShaderProgram *_shader;
    NOCMover2D *_mover;
    GLKTextureInfo *_textureMover;
}

static NSString * ShaderNameAccelMover = @"Mover";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformMoverTexture = @"texture";

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiAccelMover";
}

- (IBAction)switchRandomChanged:(id)sender
{
    BOOL isRandom = self.switchRandom.on;
    self.sliderAccelX.enabled = !isRandom;
    self.sliderAccelY.enabled = !isRandom;
}

#pragma mark - Draw Loop

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setup
{
    // Trigger the correct view state
    [self switchRandomChanged:nil];
    
    _textureMover = NOCLoadGLTextureWithName(@"mover");
        
    // Setup the shader
    _shader = [[NOCShaderProgram alloc] initWithName:ShaderNameAccelMover];
    
    _shader.attributes = @{
        @"position" : @(GLKVertexAttribPosition),
        @"texCoord" : @(GLKVertexAttribTexCoord0)
    };
    
    _shader.uniformNames = @[
        UniformMVProjectionMatrix,
        UniformMoverTexture
    ];
    
    [self addShader:_shader named:ShaderNameAccelMover];

    // Setup the Mover
    _mover = [[NOCMover2D alloc] initWithSize:GLKVector2Make(0.1, 0.1)
                                     position:GLKVector2Zero
                                         mass:1.0f];
    
}

- (void)update
{
    [super update];

    _mover.maxVelocity = self.sliderMaxRandomAccel.value;
    
    if(self.switchRandom.on){
        GLKVector2 randVec = GLKVector2Random();
        // Tamp down the jitteriness a bit.
        // I'm just eyeballing 0.005 because it feels right,
        // but this could be another slider.
        randVec = GLKVector2Multiply(randVec, GLKVector2Make(0.005, 0.005));
        _mover.acceleration = randVec;
    }else{
        _mover.acceleration = GLKVector2Make(self.sliderAccelX.value,
                                             self.sliderAccelY.value);
    }
    
    CGRect moverBounds = CGRectMake(-1, -1 / _viewAspect,
                                    2, 2 / _viewAspect);

    [_mover stepInRect:moverBounds shouldWrap:YES];
    
}

- (void)resize
{
    [super resize];
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)draw
{
    
    [self clear];
    
    [_shader use];
    
    // Enable alpha blending for the transparent png
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Bind the texture
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, _textureMover.name);
    
    // Attach the texture to the shader
    NSNumber *samplerLoc = _shader.uniformLocations[UniformMoverTexture];
    glUniform1i([samplerLoc intValue], 0);
    
    // Create the Model View Projection matrix for the shader
    NSNumber *projMatLoc = _shader.uniformLocations[UniformMVProjectionMatrix];
    
    // Get the model matrix
    GLKMatrix4 modelMat = [_mover modelMatrix];
    
    // Multiply by the projection matrix
    GLKMatrix4 mvProjMat = GLKMatrix4Multiply(_projectionMatrix2D, modelMat);
    
    // Pass mvp into shader
    glUniformMatrix4fv([projMatLoc intValue], 1, 0, mvProjMat.m);

    [_mover render];
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
}

- (void)teardown
{
    //..
}

@end

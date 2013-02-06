//
//  NOCTESTSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTESTSketchViewController.h"
#import "NOCGeometryHelpers.h"
#import "NOCRandomWalker.h"
#import <QuartzCore/QuartzCore.h>

// NOTE
// This controller is used for experimentation

@implementation NOCTESTSketchViewController
{
    NOCRandomWalker *_walker;
}

static NSString * UniformFBOTexture = @"texture";
static NSString * BackgroundShaderName = @"BackgroundTexture";
static NSString * WalkerShaderName = @"RandomWalker";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";

- (void)setup
{
    // Setup the sample shader
    NOCShaderProgram *texShader = [[NOCShaderProgram alloc] initWithName:BackgroundShaderName];
    
    texShader.attributes = @{
     @"position" : @(GLKVertexAttribPosition),
     @"texCoord" : @(GLKVertexAttribTexCoord0)
    };
     
    texShader.uniformNames = @[
     UniformFBOTexture,
     UniformMVProjectionMatrix
    ];
    

    // Setup the walker shader
    NOCShaderProgram *walkerShader = [[NOCShaderProgram alloc] initWithName:WalkerShaderName];
    
    walkerShader.attributes = @{
        @"position" : @(GLKVertexAttribPosition),
        @"color" : @(GLKVertexAttribColor)
    };
    
    walkerShader.uniformNames = @[
        UniformMVProjectionMatrix,
    ];
    
    self.shaders = @{ BackgroundShaderName : texShader,
                      WalkerShaderName : walkerShader };
    
    _walker = [[NOCRandomWalker alloc] initWithSize:CGSizeMake(10, 10) position:CGPointMake(0, 0)];

}

static int frameNum = 0;

- (void)update
{
    frameNum++;
    
    [super update];    
    
    CGSize sizeView = self.view.frame.size;
    [_walker stepInRect:CGRectMake(sizeView.width * -0.5,
                                   sizeView.height * -0.5,
                                   sizeView.width,
                                   sizeView.height)];
}

- (void)draw
{
	//glClearColor(0.2, 0.2, 0.2, 1.0f);
	//glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [self renderWalker];
    
 
}

- (void)renderWalker
{
    // Draw the walker
    NOCShaderProgram *walkerShader = self.shaders[WalkerShaderName];
    [walkerShader use];
    
    // Create the Model View Projection matrix for the shader
    NSNumber *projMatLoc = walkerShader.uniformLocations[UniformMVProjectionMatrix];
    
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

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

GLfloat ScreenQuadVerts[20] = {
    -1,-1,1.0,
    0,1,
    
    1,-1,1.0,
    1,1,
    
    -1,1,1.0,
    0,0,
    
    1,1,1.0,
    1,0
};

@implementation NOCTESTSketchViewController
{
    GLsizei _cxFBO;
    GLsizei _cyFBO;
    GLuint _frameBufferID;
//    GLuint _colorRenderBuffer;
    GLuint _depthRenderBuffer;
    GLuint _fboTextureID;
    
    NOCRandomWalker *_walker;
}

static NSString * UniformFBOTexture = @"texture";
static NSString * FBOShaderName = @"BackgroundFBO";
static NSString * WalkerShaderName = @"RandomWalker";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";

- (void)setup
{
    // Setup the sample shader

    NOCShaderProgram *texShader = [[NOCShaderProgram alloc] initWithName:FBOShaderName];
    
    texShader.attributes = @{
     @"position" : @(GLKVertexAttribPosition),
     @"texCoord" : @(GLKVertexAttribTexCoord0)
    };
     
    texShader.uniformNames = @[
     UniformFBOTexture,
     UniformMVProjectionMatrix
    ];
    

    // Setup the shader
    NOCShaderProgram *walkerShader = [[NOCShaderProgram alloc] initWithName:WalkerShaderName];
    
    walkerShader.attributes = @{
        @"position" : @(GLKVertexAttribPosition),
        @"color" : @(GLKVertexAttribColor)
    };
    
    walkerShader.uniformNames = @[
        UniformMVProjectionMatrix,
    ];
    
    self.shaders = @{ FBOShaderName : texShader, WalkerShaderName : walkerShader };
    
    // TODO: This should be done in update / resize
    CGSize sizeView = self.view.frame.size;
    float scale = [UIScreen mainScreen].scale;
	//float aspect = (GLfloat) sizeView.width / sizeView.height;
	_cxFBO = sizeView.width * scale;
	_cyFBO = sizeView.height * scale;
    
    _walker = [[NOCRandomWalker alloc] initWithSize:CGSizeMake(10, 10) position:CGPointMake(0, 0)];

}

static int frameNum = 0;

- (void)update
{
    frameNum++;
    
    [super update];
    
    /*
    
    //if(frameNum % 10 == 0){
        
        double randx = randomNormal();
        CGSize sizeView = self.view.frame.size;
        float x = randx * sizeView.width;
        // Randomly scatter across the width
        // Center vertically
        CGPoint vp = CGPointMake((sizeView.width * 0.5) + x,
                    sizeView.height * 0.5);
        
        // Add views into the screen
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(vp.x - 5, vp.y - 5, 10, 10)];
        v.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.25];
        [self.view addSubview:v];
        
    //}
     */
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

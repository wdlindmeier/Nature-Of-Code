//
//  NOCTankSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTankSketchViewController.h"
#import "NOCSceneBox.h"
#import "NOCShaderProgram.h"

@interface NOCTankSketchViewController ()
{
    NOCSceneBox *_sceneBox;
}
@end

@implementation NOCTankSketchViewController

static NSString * ShaderNameBeings = @"ColoredVerts";
static NSString * ShaderNameSceneBox = @"SceneBox";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";

- (void)setup
{
    NOCShaderProgram *shaderBeings = [[NOCShaderProgram alloc] initWithName:ShaderNameBeings];
    shaderBeings.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                             @"color" : @(GLKVertexAttribColor) };
    shaderBeings.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shaderBeings named:ShaderNameBeings];


    NOCShaderProgram *shaderSceneBox = [[NOCShaderProgram alloc] initWithName:ShaderNameSceneBox];
    shaderSceneBox.attributes = @{ @"position" : @(GLKVertexAttribPosition) };
    shaderSceneBox.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shaderSceneBox named:ShaderNameSceneBox];
    
    _sceneBox = [[NOCSceneBox alloc] initWithAspect:_viewAspect];
    
    self.isArcballEnabled = NO;
    self.isGestureNavigationEnabled = YES;
}

- (void)resize
{
    [super resize];
    [_sceneBox resizeWithAspect:_viewAspect];
}

- (void)update
{
    [super update];
}

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)draw
{
    [self clear];
    
    GLKMatrix4 matCam = GLKMatrix4MakeTranslation(0, 0, self.cameraDepth);
    GLKMatrix4 matScene = GLKMatrix4Multiply(_projectionMatrix3D, matCam);
    
    matScene = [self rotateMatrixWithArcBall:matScene];

    // Draw the scene box
    NOCShaderProgram *shaderScene = [self shaderNamed:ShaderNameSceneBox];
    [shaderScene use];
    [shaderScene setMatrix:matScene
                forUniform:UniformMVProjectionMatrix];
    [_sceneBox render];    

}

- (void)teardown
{
    //...
}

@end

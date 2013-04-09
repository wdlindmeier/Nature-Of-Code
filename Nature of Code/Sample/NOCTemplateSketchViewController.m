//
//  NOCTemplateSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTemplateSketchViewController.h"

@interface NOCTemplateSketchViewController ()

@end

@implementation NOCTemplateSketchViewController

// Some sample variables
/*
static NSString * ShaderName = @"SampleShader";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformNormalMatrix = @"normalMatrix";
*/

- (void)setup
{
    [super setup];
    
    // Setup the shader
    /*
     NOCShaderProgram *shader = [[NOCShaderProgram alloc] initWithName:ShaderName];
     
     shader.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                            @"normal" : @(GLKVertexAttribNormal) };
     
     shader.uniformNames = @[ UniformMVProjectionMatrix, UniformNormalMatrix ];
     
     [self addShader:shader named:ShaderName];
     */
}

- (void)update
{
    [super update];
}

- (void)draw
{
    //...
}

- (void)teardown
{
    [super teardown];
}

@end

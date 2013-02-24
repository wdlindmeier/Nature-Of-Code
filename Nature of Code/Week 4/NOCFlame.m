//
//  NOCFlame.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFlame.h"
#import "NOCFlameParticle.h"
#import "NOCShaderProgram.h"

static NSString * NOCParticleShaderName = @"FlameParticle";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformParticleTexture = @"texture";
static NSString * UniformParticleAge = @"scalarAge";

@implementation NOCFlame
{
    NOCShaderProgram *_shader;
    GLKTextureInfo *_texture;
}

- (id)initWithPosition:(GLKVector3)position flameTexture:(GLKTextureInfo *)texture
{
    self = [super initWithPosition:position capacity:100];
    
    if(self){

        _texture = texture;

        _shader = [[NOCShaderProgram alloc] initWithName:NOCParticleShaderName];
        
        _shader.attributes = @{@"position" : @(GLKVertexAttribPosition),
                               @"texCoord" : @(GLKVertexAttribTexCoord0)};
        
        _shader.uniformNames = @[ UniformMVProjectionMatrix,
                                         UniformParticleTexture,
                                         UniformParticleAge];
        
        [_shader load];

    }
    return self;
}

- (void)stepWithLift:(GLKVector2)vecUp
{
    // Always add another particle
    float pDimesion = 0.2 + (0.2 * RAND_SCALAR);
    NOCFlameParticle *p = [[NOCFlameParticle alloc] initWithSize:GLKVector2Make(pDimesion, pDimesion)
                                                        position:GLKVector2Make(0.05 * RAND_SCALAR,
                                                                                0.05 * RAND_SCALAR)];
    p.stepLimit = 75;
    p.texture = _texture;
    [self addParticle:p];
    
    // Apply forces
    [self applyForce2D:vecUp];
    
    // Update
    [self step];
}

- (void)renderInMatrix:(GLKMatrix4)projectionMatrix
{
    [_shader use];
    
    // Enable alpha blending for the transparent png
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
    
    // Bind the texture
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    
    // Attach the texture to the shader
    [_shader setInt:0 forUniform:UniformParticleTexture];
    
    [self render:^(GLKMatrix4 particleMatrix, NOCParticle *p){
        
        // Multiply by the projection matrix
        GLKMatrix4 mvProjMat = GLKMatrix4Multiply(projectionMatrix, particleMatrix);
        
        // Pass mvp into shader
        [_shader setMatrix:mvProjMat forUniform:UniformMVProjectionMatrix];
        
        float age = p.stepCount / (float)p.stepLimit;
        float maxBrightness = 0.1;
        if(age < maxBrightness){
            age = 1.0 - (age / maxBrightness);
        }else{
            age = (age-maxBrightness) / (1.0-maxBrightness);
        }
        
        const static float dampenBrightness = 0.1;
        age=(1.0-dampenBrightness)+(age*dampenBrightness);
        
        [_shader setFloat:age forUniform:UniformParticleAge];

        
    }];
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
}

@end

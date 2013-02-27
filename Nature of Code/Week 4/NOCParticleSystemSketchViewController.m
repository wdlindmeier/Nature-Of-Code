//
//  NOCParticleSystemSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCParticleSystemSketchViewController.h"
#import "NOCFlameParticle.h"
#import "NOCParticleSystem.h"

@interface NOCParticleSystemSketchViewController ()
{
    NSArray *_textures;
    NOCParticleSystem *_particleSystem;
    GLKVector2 _vecWind;
    GLKVector2 _vecLift;
}

@end

@implementation NOCParticleSystemSketchViewController

static NSString * ParticleShaderName = @"FlameParticle";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformParticleTexture = @"texture";
static NSString * UniformParticleAge = @"scalarAge";

#pragma mark - Accessors

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiParticleSystem";
}

- (int)dstBlendFactorForIndex:(int)index
{
    switch (index) {
        case 0:
            return GL_ZERO;
        case 1:
            return GL_ONE;
        case 2:
            return GL_SRC_COLOR;
        case 3:
            return GL_ONE_MINUS_SRC_COLOR;
        case 4:
            return GL_SRC_ALPHA;
        case 5:
            return GL_ONE_MINUS_SRC_ALPHA;
        case 6:
            return GL_DST_ALPHA;
        case 7:
            return GL_ONE_MINUS_DST_ALPHA;
    }
    return 0;
}

- (int)srcBlendFactorForIndex:(int)index
{
    switch (index) {
        case 0:
            return GL_ZERO;
        case 1:
            return GL_ONE;
        case 2:
            return GL_DST_COLOR;
        case 3:
            return GL_ONE_MINUS_DST_COLOR;
        case 4:
            return GL_SRC_ALPHA_SATURATE;
        case 5:
            return GL_SRC_ALPHA;
        case 6:
            return GL_ONE_MINUS_SRC_ALPHA;
        case 7:
            return GL_DST_ALPHA;
        case 8:
            return GL_ONE_MINUS_DST_ALPHA;
    }
    return 0;
}

#pragma mark - Sketch

- (void)setup
{
    // Shaders
    NOCShaderProgram *particleShader = [[NOCShaderProgram alloc] initWithName:ParticleShaderName];

    particleShader.attributes = @{@"position" : @(GLKVertexAttribPosition),
                                  @"texCoord" : @(GLKVertexAttribTexCoord0)};

    particleShader.uniformNames = @[ UniformMVProjectionMatrix,
                                     UniformParticleTexture,
                                     UniformParticleAge];

    self.shaders = @{ ParticleShaderName : particleShader };
    
    // Textures
    NSArray *texNames = @[@"flame_red", @"flame_green", @"flame_magenta", @"flame_blue"];
    NSMutableArray *textures = [NSMutableArray arrayWithCapacity:texNames.count];
    for(NSString *texName in texNames){
        [textures addObject:NOCLoadGLTextureWithName(texName)];
    }
    _textures = [NSArray arrayWithArray:textures];
    
    _particleSystem = [[NOCParticleSystem alloc] initWithPosition:GLKVector3Zero
                                                         capacity:100];
    
    // Flame always raises a little
    _vecLift = GLKVector2Make(0, 0.0005);
    
}

- (void)update
{
    // We don't want the particle system to
    // have to know about the specific particle
    // subclasses and constructors, so we'll pass
    // particles in, rather than creating them
    // in the system.
    
    // NOTE: The particle position is relative to the
    // system position.
    float pDimesion = 0.5 * RAND_SCALAR;
    NOCFlameParticle *p = [[NOCFlameParticle alloc] initWithSize:GLKVector2Make(pDimesion, pDimesion)
                                                        position:GLKVector2Make(0.025 * RAND_SCALAR,
                                                                                0.025 * RAND_SCALAR)];
    p.stepLimit = 100;
    p.texture = _textures[arc4random() % _textures.count];

    [_particleSystem addParticle:p];
    
    [_particleSystem applyForce2D:_vecLift];
    [_particleSystem applyForce2D:_vecWind];
    _vecWind = GLKVector2Zero;
    [_particleSystem step];
    
}

- (void)draw
{
    
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    NOCShaderProgram *particleShader = self.shaders[ParticleShaderName];
    [particleShader use];
    
    // Enable alpha blending for the transparent png
    glEnable(GL_BLEND);
    int srcMode = [self srcBlendFactorForIndex:self.segmentedControlSrcBlend.selectedSegmentIndex];
    int dstMode = [self dstBlendFactorForIndex:self.segmentedControlDstBlend.selectedSegmentIndex];
    glBlendFunc(srcMode, dstMode);
    
    // Bind the texture
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);

    // Attach the texture to the shader
    [particleShader setInt:0 forUniform:UniformParticleTexture];
    
    // NOTE: Particle system is calling render on each of the
    // particles, but we need to use a block to set shader values
    // like the matrix and age.
    
    [_particleSystem render:^(GLKMatrix4 particleMatrix, NOCParticle *p){
        
        // Multiply by the projection matrix
        GLKMatrix4 mvProjMat = GLKMatrix4Multiply(_projectionMatrix2D, particleMatrix);
        
        // Pass mvp into shader
        [particleShader setMatrix:mvProjMat forUniform:UniformMVProjectionMatrix];
        
        // Pass the age into the shader.
        // Age will determine the alpha, but we don't want the
        // texture to be brightest right when it appears,
        // so we'll also give it a little fade in.
        
        float age = p.stepCount / (float)p.stepLimit;
        // We'll calculate the alpha curve here because "if" statements are
        // expensive on the shader.
        float maxBrightness = 0.1;
        if(age < maxBrightness){
            age = 1.0 - (age / maxBrightness);
        }else{
            age = (age-maxBrightness) / (1.0-maxBrightness);
        }
        [particleShader setFloat:age forUniform:UniformParticleAge];

    }];
    
    glBindTexture(GL_TEXTURE_2D, 0);

}

- (void)teardown
{
    //...
}

#pragma mark - Touch

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){

        CGPoint posTouch = [t locationInView:self.view];
        CGSize sizeView = self.view.frame.size;
        float aspect = sizeView.width / sizeView.height;
        
        float scalarX = posTouch.x / sizeView.width;
        float scalarY = posTouch.y / sizeView.height;
        
        float glX = (scalarX * 2.0f) - 1.0f;
        float glY = (scalarY * (2.0f / aspect)) - (1.0 / aspect);
        
        _vecWind = GLKVector2Make(_particleSystem.position.x - glX,
                                  glY - _particleSystem.position.y);
        _vecWind = GLKVector2MultiplyScalar(_vecWind, 0.0015);
    }
}

@end

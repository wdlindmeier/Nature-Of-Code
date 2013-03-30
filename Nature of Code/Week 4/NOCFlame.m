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
#import "NOCGeometryHelpers.h"

static NSString * NOCParticleShaderName = @"FlameParticle";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformParticleTexture = @"texture";
static NSString * UniformParticleAge = @"scalarAge";

const static int NumDistHistory = 5;

@implementation NOCFlame
{
    NOCShaderProgram *_shader;
    GLKTextureInfo *_texture;
    BOOL _isDead;
    float _brightness;
    GLKVector3 _distances[NumDistHistory];
    int _idxDist;
}

#pragma mark - Init

- (id)initWithPosition:(GLKVector3)position flameTexture:(GLKTextureInfo *)texture
{
    self = [super initWithPosition:position capacity:100];
    
    if(self){
        
        _idxDist = 0;
        for(int i=0;i<NumDistHistory;i++){
            _distances[i] = GLKVector3Zero;
        }
        
        _isDead = NO;
        
        _brightness = 1.0f;

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

#pragma mark - Accessors

- (BOOL)isDead
{
    if(!_isDead){
        _isDead = _brightness < 0.01;
    }
    return _isDead;
}

- (void)kill
{
    _isDead = YES;
}

#pragma mark - Update

- (void)stepWithLift:(GLKVector2)vecUp
{
    // Always add another particle
    float pDimesion = (0.2 + (0.2 * RAND_SCALAR)) * _brightness; // Make them smaller if the flame is dimmer
    NOCFlameParticle *p = [[NOCFlameParticle alloc] initWithSize:GLKVector2Make(pDimesion, pDimesion)
                                                        position:GLKVector2Make(-0.025 + (0.05 * RAND_SCALAR),
                                                                                -0.025 + (0.05 * RAND_SCALAR))];
    p.stepLimit = 75; // this is the life span
    p.texture = _texture;
    [self addParticle:p];
    
    // Apply forces
    [self applyForce2D:vecUp];
    
    // Update the position w/ the velocity
    self.position = GLKVector3Add(self.position, self.velocity);
    
    // Store the position in the history.
    // We're just using a carousel of points.
    _distances[_idxDist] = self.position;
    int nextIdx = (_idxDist+1)%NumDistHistory;
    GLKVector3 firstPosition = _distances[nextIdx];
    _idxDist = nextIdx;
    
    // Calculate the brightness by how fast the flame is moving.
    // We're comparing this to 5 frames ago, because looking at the
    // last frame can be deceiving if it's jumping back and forth
    // between a couple of positions.
    if(!GLKVector3Equal(firstPosition, GLKVector3Zero)){
        
        // This is a valid distance. Let's compare.
        double dist = GLKVector3Distance(self.position, firstPosition);
        const static double UnitMovementBrightness = 0.035f;
        float newBrightness = dist / UnitMovementBrightness;
        _brightness = (_brightness + newBrightness) / 2.0f; // average them
        
    }else{
        
        // Start the flame w/ a brightness of 1
        _brightness = 1.0f;
        
    }
    
    // Update
    [self step];
}

#pragma mark - Draw

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
        [_shader setMatrix4:mvProjMat forUniform:UniformMVProjectionMatrix];
        
        float age = p.stepCount / (float)p.stepLimit;
        float maxBrightness = 0.1;
        if(age < maxBrightness){
            age = 1.0 - (age / maxBrightness);
        }else{
            age = (age-maxBrightness) / (1.0-maxBrightness);
        }
        
        const static float dampenBrightness = 0.1;
        age=(1.0-dampenBrightness)+(age*dampenBrightness);
        
        [_shader setFloat:age
               forUniform:UniformParticleAge];

        
    }];
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
}

@end

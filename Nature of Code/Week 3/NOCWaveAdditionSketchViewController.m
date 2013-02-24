//
//  NOCWaveAdditionSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/16/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCWaveAdditionSketchViewController.h"
#import "NOCMover2D.h"

static const int NumMovers = 100;
static const float MaxFrequency = 1.f;
static const int NumWaves = 2;

@interface NOCWaveAdditionSketchViewController ()
{
    NOCShaderProgram *_shader;
    NSArray *_movers;
    GLKTextureInfo *_textureMover;
    float _timeStep;
    
    float _waveMagnitudes[NumWaves];
    float _waveFrequencies[NumWaves];
}

@end

@implementation NOCWaveAdditionSketchViewController

static NSString * NOCShaderNameWaveAddition = @"Mover";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformMoverTexture = @"texture";

#pragma mark - Draw Loop

- (void)clear
{
    glClearColor(0.95, 0.95, 0.95, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setup
{
    
    _waveMagnitudes[0] = 0.4;
    _waveFrequencies[0] = MaxFrequency / 10;
    
    _waveMagnitudes[1] = 0.2;
    _waveFrequencies[1] = MaxFrequency / 20;

    _timeStep = 0;
    
    // Texture
    _textureMover = NOCLoadGLTextureWithName(@"brushed_sphere");

    // Setup the shader
    _shader = [[NOCShaderProgram alloc] initWithName:NOCShaderNameWaveAddition];
    
    _shader.attributes = @{
                           @"position" : @(GLKVertexAttribPosition),
                           @"texCoord" : @(GLKVertexAttribTexCoord0)
                           };
    
    _shader.uniformNames = @[
                             UniformMVProjectionMatrix,
                             UniformMoverTexture
                             ];
    
    self.shaders = @{ NOCShaderNameWaveAddition : _shader };
    
    // Create a line of little movers
    NSMutableArray *movers = [NSMutableArray arrayWithCapacity:NumMovers];
    float moverSize = 2.0f / (NumMovers-1) * 2;
    for(int i=0;i<NumMovers;i++){
        float x = (i * (moverSize * 0.5)) - 1.0f;// + (moverSize * 0.5);
        NOCMover2D *mover = [[NOCMover2D alloc] initWithSize:GLKVector2Make(moverSize, moverSize)
                                                    position:GLKVector2Make(x, 0)
                                                        mass:0.1f];
        [movers addObject:mover];
    }
    _movers = [NSArray arrayWithArray:movers];
    
}

- (void)update
{
    [super update];
    
    _timeStep += 0.1;

    
    float fSteps[NumWaves];
    for(int i=0;i<NumWaves;i++){
        fSteps[i] = 0.0f;
    }
    
    for(NOCMover2D *mover in _movers){
        // Set the location based on the location X
        
        GLKVector2 pos = mover.position;
        
        float y=0;
        for(int i=0;i<NumWaves;i++){
            y+= sin(fSteps[i]+_timeStep) * _waveMagnitudes[i];
        }
        pos.y = y;
        
        mover.position = pos;
        
        for(int i=0;i<NumWaves;i++){
            fSteps[i] += _waveFrequencies[i];
        }
    }
    
}

- (void)resize
{
    [super resize];
    [self clear];    
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
    
    // Render each mover
    for(NOCMover2D *mover in _movers){
        // Get the model matrix
        GLKMatrix4 modelMat = [mover modelMatrix];
        // Multiply by the projection matrix
        GLKMatrix4 mvProjMat = GLKMatrix4Multiply(_projectionMatrix2D, modelMat);
        // Pass mvp into shader
        glUniformMatrix4fv([projMatLoc intValue], 1, 0, mvProjMat.m);
        
        [mover render];
        
    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
}

- (void)teardown
{
    //..
}

#pragma mark - Touch

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        CGPoint posTouch = [t locationInView:self.view];
        CGSize sizeView = self.view.frame.size;
        float scalarY = posTouch.y / sizeView.height;
        float scalarX = posTouch.x / sizeView.width;
        
        _waveMagnitudes[1] = scalarY;
        _waveFrequencies[1] = MaxFrequency * scalarX;
        
    }
}

@end

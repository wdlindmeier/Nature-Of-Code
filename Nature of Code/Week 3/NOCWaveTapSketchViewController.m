//
//  NOCWaveTapViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/16/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCWaveTapSketchViewController.h"
#import "NOCMover2D.h"
#import "NOCTapWave.h"

static const int NumMovers = 100;
static const float MaxFrequency = 100.f;
// How long it takes for a wave to cross the screen.
// This is arbitrary.
static const NSTimeInterval UnitTimeInterval = 1.0f;

@interface NOCWaveTapSketchViewController ()
{
    NSMutableArray *_tapWaves;
    NOCShaderProgram *_shader;
    NSArray *_movers;
    GLKTextureInfo *_textureMover;
    float _timeStep;
}
@end

@implementation NOCWaveTapSketchViewController

static NSString * ShaderNameWaveTap = @"Mover";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformMoverTexture = @"texture";

#pragma mark - GUI

#pragma mark - Draw Loop

- (void)clear
{
    glClearColor(0.95, 0.95, 0.95, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setup
{
    _tapWaves = [NSMutableArray arrayWithCapacity:100];
    _timeStep = 0;
    
    // Texture
    _textureMover = NOCLoadGLTextureWithName(@"brushed_sphere");
    
    // Setup the shader
    _shader = [[NOCShaderProgram alloc] initWithName:ShaderNameWaveTap];
    
    _shader.attributes = @{
                           @"position" : @(GLKVertexAttribPosition),
                           @"texCoord" : @(GLKVertexAttribTexCoord0)
                           };
    
    _shader.uniformNames = @[
                             UniformMVProjectionMatrix,
                             UniformMoverTexture
                             ];
    
    self.shaders = @{ ShaderNameWaveTap : _shader };
    
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
    
    int numWaves = _tapWaves.count;

    NSTimeInterval ti = [NSDate timeIntervalSinceReferenceDate];

    for(NOCMover2D *mover in _movers){
        
        // Set the location based on the location X
        GLKVector2 posMover = mover.position;
        
        float y=0;
        
        for(int i=0;i<numWaves;i++){
            
            NOCTapWave *wave = _tapWaves[i];
            
            // Ignore the Y distance in this sketch
            double distFromWave = fabs(wave.position.x - posMover.x);
            
            // The screen is 2 units wide and the
            // unit time interval measures the time it takes to
            // cross the width of the screen.
            float scalarDistance = distFromWave / 2.0f;

            // The position of the tap is "now," so movers further
            // away are operating on waves from the past.
            NSTimeInterval tiMover = ti - (UnitTimeInterval * scalarDistance);

            float waveY = [wave valueAtTime:tiMover];
            y += waveY;
            
        }
        
        posMover.y = y;
        mover.position = posMover;
        
    }
    
    [self pruneDeadWavesForTimeInterval:ti];
}

- (void)pruneDeadWavesForTimeInterval:(NSTimeInterval)ti
{
    // Remove any "dead" waves
    NSTimeInterval lastTime = ti - UnitTimeInterval;
    NSMutableSet *removeWaves = [NSMutableSet set];
    for(NOCTapWave *wave in _tapWaves){
        if([wave isDeadAtTime:lastTime]){
            [removeWaves addObject:wave];
        }
    }
    for(NOCTapWave *wave in removeWaves){
        [_tapWaves removeObject:wave];
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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        
        CGPoint posTouch = [t locationInView:self.view];
        CGSize sizeView = self.view.frame.size;
        float aspect = sizeView.width / sizeView.height;
        
        float scalarX = posTouch.x / sizeView.width;
        float scalarY = posTouch.y / sizeView.height;
        
        float glX = (scalarX * 2.0f) - 1.0f;
        float glY = (scalarY * (2.0f / aspect)) - (1.0 / aspect);
        
        GLKVector3 tapPosition = GLKVector3Make(glX, glY, 0);
        
        NSTimeInterval tiNow = [NSDate timeIntervalSinceReferenceDate];
        
        NOCTapWave *wave = [[NOCTapWave alloc] initWithAmplitude:scalarY
                                                       frequency:MaxFrequency * scalarX
                                                   timeTriggered:tiNow
                                                        position:tapPosition];
        
        [_tapWaves addObject:wave];
    }
}

@end

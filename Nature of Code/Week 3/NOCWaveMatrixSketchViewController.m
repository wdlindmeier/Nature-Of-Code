//
//  NOCWaveMatrixSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/17/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCWaveMatrixSketchViewController.h"
#import "NOCSceneBox.h"
#import "NOCMover3D.h"
#import "NOCTapWave.h"
#import "NOCSpring3D.h"

// Change USE_TEXTURE to 1 if you want the Movers to render as metal balls
#define USE_TEXTURE 0

#if !USE_TEXTURE

#import "NOCCubeMover.h"

#endif

static const float MaxFrequency = 100.f;
// How long it takes for a wave to cross the screen.
// This is arbitrary.
// This should be the MAXIMUM amount of time a wave is on the screen.
static const NSTimeInterval UnitTimeInterval = 1.0f;

@interface NOCWaveMatrixSketchViewController ()
{
    NSArray *_movers;
    NSArray *_springs;
    NOCSceneBox *_sceneBox;
    NSMutableArray *_tapWaves;
    
#if USE_TEXTURE
    
    GLKTextureInfo *_textureMover;
    
#endif
    
}

@end

#if USE_TEXTURE
    static NSString * NOCShaderNameWaveMatrixMover = @"MoverDepthShading";
    static NSString * UniformMoverTexture = @"texture";
#else
    static NSString * NOCShaderNameWaveMatrixMover = @"MoverTapMatrix";
    static NSString * UniformNormalMatrix = @"normalMatrix";
#endif

static NSString * NOCShaderNameSceneBox = @"SceneBox";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";

@implementation NOCWaveMatrixSketchViewController

#pragma mark - Interface Orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - Draw Loop

- (void)clear
{
    glClearColor(0.25, 0.25, 0.25, 1.0);

#if USE_TEXTURE
    glClear(GL_COLOR_BUFFER_BIT);
#else
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
#endif
    
}

- (void)setup
{
    
    _tapWaves = [NSMutableArray arrayWithCapacity:100];


    // Setup the shaders
    NOCShaderProgram *shaderMovers = [[NOCShaderProgram alloc] initWithName:NOCShaderNameWaveMatrixMover];
    
#if USE_TEXTURE
    
    shaderMovers.attributes = @{@"position" : @(GLKVertexAttribPosition),
                                @"texCoord" : @(GLKVertexAttribTexCoord0)};

    shaderMovers.uniformNames = @[ UniformMVProjectionMatrix, UniformMoverTexture ];

#else
    
    shaderMovers.attributes = @{@"position" : @(GLKVertexAttribPosition),
                                   @"color" : @(GLKVertexAttribColor),
                                  @"normal" : @(GLKVertexAttribNormal)};

    shaderMovers.uniformNames = @[ UniformMVProjectionMatrix, UniformNormalMatrix ];
    
#endif
    
    NOCShaderProgram *shaderScene = [[NOCShaderProgram alloc] initWithName:NOCShaderNameSceneBox];
    shaderScene.attributes = @{ @"position" : @(GLKVertexAttribPosition) };
    shaderScene.uniformNames = @[ UniformMVProjectionMatrix ];
    
    self.shaders = @{NOCShaderNameWaveMatrixMover : shaderMovers,
                     NOCShaderNameSceneBox : shaderScene};
    
    CGSize sizeView = self.view.frame.size;
    float aspect = sizeView.width / sizeView.height;

    _sceneBox = [[NOCSceneBox alloc] initWithAspect:aspect];
    
    // Add the movers.
    // Just a flat 2D grid for now.
    int numMoversWide = floor(sizeView.width / 75.0);
    int numMoversHigh = round((numMoversWide / aspect));
    int numMoversDeep = numMoversWide;
    int numMovers = numMoversWide * numMoversHigh * numMoversDeep;
    
    // Setup the Movers
    NSMutableArray *movers = [NSMutableArray arrayWithCapacity:numMovers];
    NSMutableArray *springs = [NSMutableArray arrayWithCapacity:numMovers];
    
    float plotWidth = 2.0f / numMoversWide;
    float plotHeight = (2.0f / aspect) / numMoversHigh;
    float plotDepth = plotWidth;
    
    // NOTE: Adding movers from front-to-back so we don't
    // have to do any depth sorting
    
    for(int plotZ=0;plotZ<numMoversDeep;plotZ++){
        for(int plotX=0;plotX<numMoversWide;plotX++){
            for(int plotY=0;plotY<numMoversHigh;plotY++){

                float x = ((plotWidth * 0.5) + (plotWidth * plotX)) - 1.0f;
                float y = (plotHeight * 0.5) + (plotHeight * plotY) - (1.0f / aspect);
                float z = ((plotDepth * 0.5) + (plotDepth * plotZ)) - 1.0f;
                
                GLKVector3 anchor = GLKVector3Make(x, y, z);
                        
                float mass = 1.0f;
                float dimension = (2.0f / numMoversWide) * 0.3;
                
                Class MoverClass;
#if USE_TEXTURE
                MoverClass = [NOCMover3D class];
#else 
                MoverClass = [NOCCubeMover class];
#endif
                NOCMover3D *mover = [[MoverClass alloc] initWithSize:GLKVector3Make(dimension,
                                                                                    dimension,
                                                                                    dimension)
                                                            position:anchor
                                                                mass:mass];
#if !USE_TEXTURE
                // Set the color based on the x, y, z

                float scalarX = (float)plotX / numMoversWide;
                float scalarY = (float)plotY / numMoversHigh;
                float scalarZ = (float)plotZ / numMoversDeep;

                float red = scalarY;
                float green = scalarX;
                float blue = 1.0 - scalarZ;

                UIColor *colorCube = [UIColor colorWithRed:red
                                                     green:green
                                                      blue:blue
                                                     alpha:1.0f];
                
                [(NOCCubeMover *)mover setColor:colorCube];
#endif

                [movers addObject:mover];
                
                // NOTE:
                // Maybe we should create a mover property in the spring
                // so we're not assuming that the array order is correct.
                // However, this limits the flexibility of the spring to
                // act on any mover.
                NOCSpring3D *spring = [[NOCSpring3D alloc] initWithAnchor:anchor
                                                               restLength:0];
                spring.maxLength = 0.5;
                spring.dampening = -0.05;
                [springs addObject:spring];
                
            }
        }        
    }
    
    _movers = [NSArray arrayWithArray:movers];
    _springs = [NSArray arrayWithArray:springs];
    
#if USE_TEXTURE
    
    // Texture
    _textureMover = [self loadTextureWithName:@"brushed_sphere"];
    
#endif
    
    
}

- (void)resize
{
    [super resize];
    
    [self clear];
    
    // Create the box vertecies
    CGSize sizeView = self.view.frame.size;
    float aspect = sizeView.width / sizeView.height;
    [_sceneBox resizeWithAspect:aspect];
    
}

- (void)update
{
    [super update];
    
    NSTimeInterval ti = [NSDate timeIntervalSinceReferenceDate];
    
    for(int i=0;i<_movers.count;i++){
        
        NOCMover3D *mover = _movers[i];
        NOCSpring3D *spring = _springs[i];
        
        GLKVector3 moverForce = GLKVector3Zero;
     
        for(NOCTapWave *wave in _tapWaves){

            GLKVector3 vecDir = GLKVector3Subtract(mover.position, wave.position); // Which is first?
            double distFromWave = GLKVector3Length(vecDir);
            vecDir = GLKVector3Normalize(vecDir);

            // The screen is 2 units wide and the
            // unit time interval measures the time it takes to
            // cross the width of the screen.
            float scalarDistance = distFromWave / 2.0f;
            
            // The position of the tap is "now," so movers further
            // away are operating on waves from the past.
            NSTimeInterval tiMover = ti - (UnitTimeInterval * scalarDistance);
            
            float waveMag = [wave valueAtTime:tiMover];

            GLKVector3 vecWave = GLKVector3MultiplyScalar(vecDir, waveMag);
            
            moverForce = GLKVector3Add(moverForce, vecWave);
            
        }
        
        [mover applyForce:moverForce];
        [spring applySpringToMover:mover];
        [spring constrainMover:mover];
        
        [mover step];

    }

    
    [self pruneDeadWavesForTimeInterval:ti];
        
}


- (void)pruneDeadWavesForTimeInterval:(NSTimeInterval)ti
{
    // Remove any "dead" waves
    // The unit time interval is the maximum amount of time on the screen
    // so we know that the waves are no longer visible.
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

- (void)draw
{
    
    [self clear];
    
    // Making the cube flush with the screen so we don't have to worry
    // about translating the 2D position of the touch into 3D space.
    static const float CamDepth = -3.09f;
    GLKMatrix4 matCam = GLKMatrix4MakeTranslation(0, 0, CamDepth);
    GLKMatrix4 matScene = GLKMatrix4Multiply(_projectionMatrix3D, matCam);
    
    NSNumber *projMatLoc = nil;
    
    // Draw the scene box
    NOCShaderProgram *shaderScene = self.shaders[NOCShaderNameSceneBox];
    [shaderScene use];
    // Create the Model View Projection matrix for the shader
    projMatLoc = shaderScene.uniformLocations[UniformMVProjectionMatrix];
    // Pass mvp into shader
    glUniformMatrix4fv([projMatLoc intValue], 1, 0, matScene.m);
    
//    [_sceneBox render];
    
    // We'll use the same shader and matrix to draw the springs.
    // A simple white line.
    for(int i=0;i<_springs.count;i++){
        NOCSpring3D *spring = _springs[i];
        NOCMover3D *mover = _movers[i];
        [spring renderToMover:mover];
    }
    
    // Draw the movers
    
    NOCShaderProgram *shaderMovers = self.shaders[NOCShaderNameWaveMatrixMover];
    [shaderMovers use];

    // Create the Model View Projection matrix for the shader
    projMatLoc = shaderMovers.uniformLocations[UniformMVProjectionMatrix];
    
#if USE_TEXTURE
    
    // Enable alpha blending for the transparent png
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Bind the texture
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, _textureMover.name);
    
    // Attach the texture to the shader
    NSNumber *samplerLoc = shaderMovers.uniformLocations[UniformMoverTexture];
    glUniform1i([samplerLoc intValue], 0);

#else
    
    glEnable(GL_DEPTH_TEST);
    
    // Create the Model View Projection matrix for the shader
    NSNumber *normalMatLoc = shaderMovers.uniformLocations[UniformNormalMatrix];
    
#endif
    
    // Render each mover
    for(NOCMover3D *mover in _movers){
        
        // Get the model matrix
        GLKMatrix4 modelMat = [mover modelMatrix];

        // Multiply by the projection matrix
        GLKMatrix4 mvProjMat = GLKMatrix4Multiply(matScene, modelMat);
        
        // Pass mvp into shader
        glUniformMatrix4fv([projMatLoc intValue], 1, 0, mvProjMat.m);
        
#if USE_TEXTURE
        
        [mover render];
        
#else
        
        // Generate a normal matrix
        GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelMat), NULL);
        
        // Pass in the normal matrix
        glUniformMatrix3fv([normalMatLoc intValue], 1, 0, normalMatrix.m);
        
        [mover render];
        
#endif
        
    }

    
#if USE_TEXTURE
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisable(GL_BLEND);
    glDisable(GL_TEXTURE_2D);

#else
    
    glDisable(GL_DEPTH_TEST);
    
#endif
    
}

- (void)teardown
{
    //..
}


#pragma mark - Touch

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        
        if(t.tapCount > 0){
        
            CGPoint posTouch = [t locationInView:self.view];
            CGSize sizeView = self.view.frame.size;
            float aspect = sizeView.width / sizeView.height;
            
            float scalarX = posTouch.x / sizeView.width;
            float scalarY = posTouch.y / sizeView.height;
            
            float glX = (scalarX * 2.0f) - 1.0f;
            float glY = (scalarY * (-2.0f / aspect)) + (1.0f / aspect);
            float glZ = 1.0f; // Start the waves at the front of the cube
            
            GLKVector3 tapPosition = GLKVector3Make(glX, glY, glZ);
            
            // NOTE: There's a slign perceptual lag as the wave ramps up,
            // so we'll pretend like the wave was triggered .15 seconds earlier.
            NSTimeInterval tiNow = [NSDate timeIntervalSinceReferenceDate] - 0.15;
            
            NOCTapWave *wave = [[NOCTapWave alloc] initWithAmplitude:0.02
                                                           frequency:MaxFrequency * 0.04
                                                       timeTriggered:tiNow
                                                            position:tapPosition];
            [_tapWaves addObject:wave];
            
        }
    }
}

@end

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

static const float MaxFrequency = 100.f;
// How long it takes for a wave to cross the screen.
// This is arbitrary.
// This should be the MAXIMUM amount of time a wave is on the screen.
static const NSTimeInterval UnitTimeInterval = 1.0f;

@interface NOCWaveMatrixSketchViewController ()
{
    NSArray *_movers;
    NSArray *_springs;
    GLKTextureInfo *_moverTexture;
    NOCSceneBox *_sceneBox;
    NSMutableArray *_tapWaves;
}

@end

static const int NumMoversWide = 10; //20;

static NSString * NOCShaderNameWaveMatrixMover = @"Mover";
static NSString * NOCShaderNameSceneBox = @"SceneBox";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformMoverTexture = @"texture";

@implementation NOCWaveMatrixSketchViewController

#pragma mark - Draw Loop

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setup
{
    
    _tapWaves = [NSMutableArray arrayWithCapacity:100];
    
    // Load the mover texture.
    UIImage *moverTexImage = [UIImage imageNamed:@"brushed_sphere"];
    NSError *texError = nil;
    _moverTexture = [GLKTextureLoader textureWithCGImage:moverTexImage.CGImage
                                                 options:nil
                                                   error:&texError];
    if(texError){
        NSLog(@"ERROR: Could not load the texture: %@", texError);
    }
    
    // Setup the shaders
    NOCShaderProgram *shaderMovers = [[NOCShaderProgram alloc] initWithName:NOCShaderNameWaveMatrixMover];
    shaderMovers.attributes = @{@"position" : @(GLKVertexAttribPosition),
                                @"texCoord" : @(GLKVertexAttribTexCoord0)};
    shaderMovers.uniformNames = @[ UniformMVProjectionMatrix, UniformMoverTexture ];
    
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
    int numMoversHigh = round((NumMoversWide / aspect));
    int numMoversDeep = NumMoversWide;
    int numMovers = NumMoversWide * numMoversHigh * numMoversDeep;
    
    // Setup the Movers
    NSMutableArray *movers = [NSMutableArray arrayWithCapacity:numMovers];
    NSMutableArray *springs = [NSMutableArray arrayWithCapacity:numMovers];
    
    float plotWidth = 2.0f / NumMoversWide;
    float plotHeight = (2.0f / aspect) / numMoversHigh;
    float plotDepth = plotWidth;
    
    for(int plotX=0;plotX<NumMoversWide;plotX++){
        for(int plotY=0;plotY<numMoversHigh;plotY++){
            for(int plotZ=0;plotZ<numMoversDeep;plotZ++){

                float x = ((plotWidth * 0.5) + (plotWidth * plotX)) - 1.0f;
                float y = (plotHeight * 0.5) + (plotHeight * plotY) - (1.0f / aspect);
                float z = ((plotDepth * 0.5) + (plotDepth * plotZ)) - 1.0f;
                
                GLKVector3 anchor = GLKVector3Make(x, y, z);
                        
                float mass = 1.0f;
                float dimension = (2.0f / NumMoversWide) * 0.3;
                
                NOCMover3D *mover = [[NOCMover3D alloc] initWithSize:GLKVector3Make(dimension,
                                                                                    dimension,
                                                                                    dimension)
                                                            position:anchor
                                                                mass:mass];
                [movers addObject:mover];
                
                // NOTE:
                // Maybe we should create a mover property in the spring
                // so we're not assuming that the array order is correct.
                // However, this limits the flexibility of the spring to
                // act on any mover.
                NOCSpring3D *spring = [[NOCSpring3D alloc] initWithAnchor:anchor
                                                               restLength:0];
                spring.maxLength = 0.2;
                spring.dampening = -0.05;
                [springs addObject:spring];
                
            }
        }        
    }
    
    _movers = [NSArray arrayWithArray:movers];
    _springs = [NSArray arrayWithArray:springs];
    
}

- (void)resize
{
    [super resize];
    
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Create the box vertecies
    CGSize sizeView = self.view.frame.size;
    float aspect = sizeView.width / sizeView.height;
    [_sceneBox resizeWithAspect:aspect];
    
}

- (void)update
{
    [super update];
    
    NSTimeInterval ti = [NSDate timeIntervalSinceReferenceDate];
    
    //for(NOCMover3D *mover in _movers){
    for(int i=0;i<_movers.count;i++){
        
        NOCMover3D *mover = _movers[i];
        NOCSpring3D *spring = _springs[i];
        
        GLKVector3 moverForce = GLKVector3Zero;
     
        //for(int i=0;i<numWaves;i++){
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
    [_sceneBox render];
    
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
    
    // Enable alpha blending for the transparent png
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Bind the texture
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, _moverTexture.name);
    
    // Attach the texture to the shader
    NSNumber *samplerLoc = shaderMovers.uniformLocations[UniformMoverTexture];
    glUniform1i([samplerLoc intValue], 0);
    
    // Create the Model View Projection matrix for the shader
    projMatLoc = shaderMovers.uniformLocations[UniformMVProjectionMatrix];
    
    // Render each mover
    for(NOCMover3D *mover in _movers){
        
        // Get the model matrix
        GLKMatrix4 modelMat = [mover modelMatrix];
        
        // Multiply by the projection matrix
        GLKMatrix4 mvProjMat = GLKMatrix4Multiply(matScene, modelMat);
        
        // Pass mvp into shader
        glUniformMatrix4fv([projMatLoc intValue], 1, 0, mvProjMat.m);
        
        [mover render];
        
    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisable(GL_BLEND);
    glDisable(GL_TEXTURE_2D);
    
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
        float glY = (scalarY * (-2.0f / aspect)) + (1.0f / aspect);
        float glZ = 1.0f; // Start the waves at the front of the cube
        
        GLKVector3 tapPosition = GLKVector3Make(glX, glY, glZ);
        
        NSTimeInterval tiNow = [NSDate timeIntervalSinceReferenceDate];
        
        NOCTapWave *wave = [[NOCTapWave alloc] initWithAmplitude:0.02 // TMP
                                                       frequency:MaxFrequency * 0.04 // TMP
                                                   timeTriggered:tiNow
                                                        position:tapPosition];
        [_tapWaves addObject:wave];
    }
}

@end

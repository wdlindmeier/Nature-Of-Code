//
//  NOCFlockSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/10/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFlockSketchViewController.h"
#import "NOCFlocker.h"
#import "NOCSceneBox.h"
#import "NOCOBJ.h"

@interface NOCFlockSketchViewController ()
{
    NSArray *_flockers;
    NOCSceneBox *_sceneBox;
    NOCOBJ *_objCone;
}

@end

@implementation NOCFlockSketchViewController

static const int NumFlockers = 100;

static NSString * ShaderNameFlockers = @"Being";
static NSString * ShaderNameSceneBox = @"SceneBox";
static NSString * ShaderNameTrails = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformNormalMatrix = @"normalMatrix";
static NSString * UniformColor = @"color";

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiFlocking";
}

#pragma mark - Setup

- (void)setup
{

    _objCone = [[NOCOBJ alloc] initWithFilename:@"cone"];
    //_objCone = [[NOCOBJ alloc] initWithFilename:@"sharp_sphere"];

    self.isArcballEnabled = NO;
    self.isGestureNavigationEnabled = YES;

    NOCShaderProgram *shaderFlockers = [[NOCShaderProgram alloc] initWithName:ShaderNameFlockers];
    shaderFlockers.attributes = @{@"position" : @(GLKVertexAttribPosition),
                                  @"normal" : @(GLKVertexAttribNormal)};
    shaderFlockers.uniformNames = @[ UniformMVProjectionMatrix, UniformNormalMatrix, UniformColor ];
    [self addShader:shaderFlockers named:ShaderNameFlockers];
    
    NOCShaderProgram *shaderScene = [[NOCShaderProgram alloc] initWithName:ShaderNameSceneBox];
    shaderScene.attributes = @{ @"position" : @(GLKVertexAttribPosition) };
    shaderScene.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shaderScene named:ShaderNameSceneBox];

    NOCShaderProgram *shaderTrails = [[NOCShaderProgram alloc] initWithName:ShaderNameTrails];
    shaderTrails.attributes = @{ @"position" : @(GLKVertexAttribPosition), @"color" : @(GLKVertexAttribColor) };
    shaderTrails.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shaderTrails named:ShaderNameTrails];

    _sceneBox = [[NOCSceneBox alloc] initWithAspect:_viewAspect];

    [self setupInitialFlockers];
        
    glEnable(GL_DEPTH_TEST);
    
}

- (void)setupInitialFlockers
{

    NSMutableArray *flockers = [NSMutableArray arrayWithCapacity:NumFlockers];
    
    for(int i=0;i<NumFlockers;i++){
        float dimension = 0.05;
        NOCFlocker *flocker = [[NOCFlocker alloc] initWithSize:GLKVector3Make(dimension, dimension, dimension)
                                                      position:GLKVector3Random()
                                                          mass:0.05
                                                          body:_objCone];
        flocker.maxVelocity = 0.035;
        flocker.color = [UIColor colorWithRed:RAND_SCALAR
                                        green:RAND_SCALAR
                                         blue:RAND_SCALAR
                                        alpha:1];
        [flockers addObject:flocker];
    }
    
    _flockers = [NSArray arrayWithArray:flockers];
}

- (void)resize
{
    [super resize];
    [_sceneBox resizeWithAspect:_viewAspect];
}

#pragma mark - Update

- (void)update
{
    [super update];

    for(NOCFlocker *flocker in _flockers){
        GLKVector3 force = [self worldForceOnFlocker:flocker];
        [flocker applyForce:force];
        [flocker step];
    }    
}

#pragma mark - Draw

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)draw
{
    
    [self clear];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Draw the scene box
    NOCShaderProgram *shaderScene = [self shaderNamed:ShaderNameSceneBox];
    [shaderScene use];
    [shaderScene setMatrix4:_projectionMatrix3D
                 forUniform:UniformMVProjectionMatrix];
    [_sceneBox render];

    
    // Draw the flocker trails
    NOCShaderProgram *shaderTrails = [self shaderNamed:ShaderNameTrails];
    [shaderTrails use];
    [shaderTrails setMatrix4:_projectionMatrix3D forUniform:UniformMVProjectionMatrix];
    for(NOCFlocker *flocker in _flockers){
        [flocker renderHistory];
    }

    // Draw the flockers
    NOCShaderProgram *shaderFlockers = [self shaderNamed:ShaderNameFlockers];
    [shaderFlockers use];
    for(NOCFlocker *flocker in _flockers){

        GLKMatrix4 modelMat = [flocker modelMatrix];
        GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelMat), NULL);
        GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(_projectionMatrix3D, modelMat);
        
        GLfloat flockerColor[4];
        [flocker glColor:flockerColor];
        [shaderFlockers set4DFloatArray:flockerColor
                        withNumElements:1
                             forUniform:UniformColor];
        
        [shaderFlockers setMatrix4:mvpMatrix forUniform:UniformMVProjectionMatrix];
        [shaderFlockers setMatrix3:normalMatrix forUniform:UniformNormalMatrix];
        
        [flocker render];
        
    }
    
}

- (void)teardown
{
    [super teardown];
}

#pragma mark - Mover Behavior

- (GLKVector3)worldForceOnFlocker:(NOCFlocker *)flocker
{

    // NOTE: Where does this come from?
    // Maybe these should be sliders too.
    float repulsionDistThreshold = self.sliderRepulsion.value;
    float alignDistThreshold = repulsionDistThreshold + self.sliderAlignment.value;
    float attractionDistThreshold = alignDistThreshold + self.sliderAttraction.value;
    
    float amtAlignment = 1.0;//self.sliderAlignment.value;
    float amtAttraction = 1.0;//self.sliderAttraction.value;
    float amtRepulsion = 1.0;//self.sliderRepulsion.value;
    
    // NOTE: Perhaps we should draw them towards the center to keep them in the scene
    
    GLKVector3 vecReaction = GLKVector3Zero;
    
    for(NOCFlocker *flockerOther in _flockers){
        
        if(flockerOther != flocker){
            
            GLKVector3 vecDir = GLKVector3Subtract(flocker.position, flockerOther.position);
            float distance = GLKVector3Length(vecDir);
            GLKVector3 vecNormal = GLKVector3Normalize(vecDir);
            
            if(distance < attractionDistThreshold){
                
                // If they share a position, make some nominal delta
                if( distance <= 0 ){
                    distance = 0.001;
                    vecNormal = GLKVector3Random();
                }
                
                if(distance < repulsionDistThreshold){
                    
                    float magnitudeRepulsion = 1.0 - map(distance, 0.0, repulsionDistThreshold, 0.0, 1.0);
                    
                    // Apply repulsion
                    float magRepulstion = magnitudeRepulsion * amtRepulsion;
                    GLKVector3 vecMoverRepulsion = GLKVector3MultiplyScalar(vecNormal, magRepulstion);
                    vecReaction = GLKVector3Add(vecReaction, vecMoverRepulsion);
                    
                }
                if(distance > repulsionDistThreshold && distance < alignDistThreshold){
                    
                    float magnitudeAlignment = map(distance, repulsionDistThreshold, alignDistThreshold, 0.0, 1.0);

                    // Apply alignment. This is based on velocity.
                    float magAlignment = magnitudeAlignment * amtAlignment;
                    // Now we can divide the unit vector by the distance and apply that to the plot
                    GLKVector3 vecDelta = GLKVector3Subtract(flocker.velocity, flockerOther.velocity);
                    GLKVector3 vecAlignment = GLKVector3MultiplyScalar(vecDelta, magAlignment);
                    vecReaction = GLKVector3Add(vecReaction, vecAlignment);

                }                
                if(distance > alignDistThreshold && distance < attractionDistThreshold){
                    
                    float magnitudeAttraction = map(distance, alignDistThreshold, attractionDistThreshold, 0.0, 1.0);

                    // Apply attraction
                    float magAttraction = magnitudeAttraction * amtAttraction;
                    GLKVector3 vecMoverAttraction = GLKVector3MultiplyScalar(vecNormal, magAttraction);
                    vecReaction = GLKVector3Subtract(vecReaction, vecMoverAttraction);
                    
                }
                
            }
            
        }
    }
    
    float movementScale = 0.01;
    vecReaction = GLKVector3MultiplyScalar(vecReaction, movementScale);
    return vecReaction;
}

#pragma mark - Touch

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        if(t.tapCount > 1){
            [self setupInitialFlockers];
        }
    }
}

@end
//
//  NOCMovers3DViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCMovers3DSketchViewController.h"
#import "NOCMover3D.h"
#import "NOCGeometryHelpers.h"
#import "NOCSceneBox.h"

@interface NOCMovers3DSketchViewController ()
{
    NSArray *_movers;
    GLKTextureInfo *_textureMover;
    float _repulsion;
    float _distThreshold;
    NOCSceneBox *_sceneBox;
}
@end

@implementation NOCMovers3DSketchViewController

static const int NumMovers = 20;

static NSString * ShaderNameMovers3DMover = @"Mover";
static NSString * ShaderNameSceneBox = @"SceneBox";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformMoverTexture = @"texture";

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiMover3D";
}

#pragma mark - Draw Loop

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setup
{
    
    // Texture
    _textureMover = NOCLoadGLTextureWithName(@"mover");
    
    // Setup the shaders
    NOCShaderProgram *shaderMovers = [[NOCShaderProgram alloc] initWithName:ShaderNameMovers3DMover];
    shaderMovers.attributes = @{@"position" : @(GLKVertexAttribPosition),
                                @"texCoord" : @(GLKVertexAttribTexCoord0)};
    shaderMovers.uniformNames = @[ UniformMVProjectionMatrix, UniformMoverTexture ];
    [self addShader:shaderMovers named:ShaderNameMovers3DMover];
    
    NOCShaderProgram *shaderScene = [[NOCShaderProgram alloc] initWithName:ShaderNameSceneBox];
    shaderScene.attributes = @{ @"position" : @(GLKVertexAttribPosition) };
    shaderScene.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shaderScene named:ShaderNameSceneBox];

    // Setup the Movers
    NSMutableArray *movers = [NSMutableArray arrayWithCapacity:NumMovers];
    
    for(int i=0;i<NumMovers;i++){
        float randX = (RAND_SCALAR * 2.0) - 1.0f;
        float randY = (RAND_SCALAR * 2.0) - 1.0f;
        float randZ = (RAND_SCALAR * 2.0) - 1.0f;
        // Make them the same size so depth is more apparent
        float randMass = 1.0f;//0.3 + RAND_SCALAR * 1.5;
        float dimension = 0.1;// * randMass;
        NOCMover3D *mover = [[NOCMover3D alloc] initWithSize:GLKVector3Make(dimension, dimension, dimension)
                                                    position:GLKVector3Make(randX, randY, randZ)
                                                        mass:randMass];
        [movers addObject:mover];
    }
    _movers = [NSArray arrayWithArray:movers];
    
    _sceneBox = [[NOCSceneBox alloc] initWithAspect:_viewAspect];
    
}

- (void)resize
{
    [super resize];

    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    [_sceneBox resizeWithAspect:_viewAspect];
    
}

- (void)update
{
    [super update];
    
    // Step w/in the bounds

    // These were sliders and now they're not
    kGravity = 0.4;
    _repulsion = 0.5;
    
    float sceneWidth = 2.0f;
    float sceneHeight = 2.0f/_viewAspect;
    float sceneDepth = 2.0f;
    
    // We'll use the size of the screen as the max
    float maxDistance = sqrt((sceneWidth * sceneWidth) + (sceneHeight * sceneHeight));
    _distThreshold = self.sliderDistThreshold.value * maxDistance;
    
    NOCBox3D moverBounds = NOCBox3DMake(-1, -1 / _viewAspect, -1,
                                        sceneWidth, sceneHeight, sceneDepth);
    
    for(NOCMover3D *mover in _movers){
        GLKVector3 force = [self worldForceOnMover:mover];
        [mover applyForce:force];
        [mover stepInBox:moverBounds shouldWrap:NO];
    }
    
}

- (void)draw
{
    
    [self clear];
    
    // Multiply matrix by the camera depth
    const static float camDepth = -3.1;
    GLKMatrix4 matCam = GLKMatrix4MakeTranslation(0, 0, camDepth);
    GLKMatrix4 matScene = GLKMatrix4Multiply(_projectionMatrix3D, matCam);
    
    NSNumber *projMatLoc = nil;
    
    // Draw the scene box
    NOCShaderProgram *shaderScene = [self shaderNamed:ShaderNameSceneBox];
    [shaderScene use];
    [shaderScene setMatrix4:matScene
                forUniform:UniformMVProjectionMatrix];
    [_sceneBox render];
    
    // Draw the movers    
    NOCShaderProgram *shaderMovers = [self shaderNamed:ShaderNameMovers3DMover];
    [shaderMovers use];
    
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

#pragma mark - Mover Behavior

- (GLKVector3)worldForceOnMover:(NOCMover3D *)mover
{
    
    // This iterates over every mover and gives us a cumulative
    // "reaction" vector based on the attraction and repulstion values.
    
    GLKVector3 vecReaction = GLKVector3Zero;
    
    for(NOCMover3D *moverOther in _movers){
        
        if(moverOther != mover){
            
            GLKVector3 vecDir = GLKVector3Subtract(mover.position, moverOther.position);
            float distance = GLKVector3Length(vecDir);
            GLKVector3 vecNormal = GLKVector3Normalize(vecDir);
            
            // If they share a position, make some nominal delta
            if(distance<=0){
                distance = 0.001;
                vecNormal = GLKVector3Random();
            }
            
            // The attraction or repulstion amount between the two
            float magnitudeMoverForce = map(distance, 0, _distThreshold, -1, 1);
            
            GLKVector3 vecMoverForce = GLKVector3MultiplyScalar(vecNormal, magnitudeMoverForce);
            vecReaction = GLKVector3Subtract(vecReaction, vecMoverForce);
            
        }
    }
    
    vecReaction = GLKVector3Normalize(vecReaction);

    float movementScale = 0.01;
    vecReaction = GLKVector3MultiplyScalar(vecReaction, movementScale);
    return vecReaction;
}


@end

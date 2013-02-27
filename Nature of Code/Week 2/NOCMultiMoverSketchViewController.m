//
//  NOCMultiMoverSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/7/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCMultiMoverSketchViewController.h"
#import "NOCMover2D.h"
#import "NOCGeometryHelpers.h"

@interface NOCMultiMoverSketchViewController ()
{
    NOCShaderProgram *_shader;
    NSArray *_movers;
    GLKTextureInfo *_textureMover;
    GLKVector2 _vectorTouch;
    float _repulsion;
    float _distThreshold;
}
@end

@implementation NOCMultiMoverSketchViewController

static const int NumMovers = 20;

static NSString * ShaderNameMultiMover = @"Mover";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformMoverTexture = @"texture";

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiMultiMover";
}

#pragma mark - Draw Loop

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setup
{

    // Texture.
    _textureMover = NOCLoadGLTextureWithName(@"mover");
    
    // Setup the shader
    _shader = [[NOCShaderProgram alloc] initWithName:ShaderNameMultiMover];
    
    _shader.attributes = @{
        @"position" : @(GLKVertexAttribPosition),
        @"texCoord" : @(GLKVertexAttribTexCoord0)
    };
    
    _shader.uniformNames = @[
                             UniformMVProjectionMatrix,
                             UniformMoverTexture
    ];
    
    self.shaders = @{ ShaderNameMultiMover : _shader };
    
    // Setup the Movers
    NSMutableArray *movers = [NSMutableArray arrayWithCapacity:NumMovers];

    for(int i=0;i<NumMovers;i++){
        float randX = (RAND_SCALAR * 2.0) - 1.0f;
        float randY = (RAND_SCALAR * 2.0) - 1.0f;
        float randMass = 0.3 + RAND_SCALAR * 1.5;
        float dimension = 0.1 * randMass;
        NOCMover2D *mover = [[NOCMover2D alloc] initWithSize:GLKVector2Make(dimension, dimension)
                                                    position:GLKVector2Make(randX, randY)
                                                        mass:randMass];
        [movers addObject:mover];
    }
    _movers = [NSArray arrayWithArray:movers];

}

- (void)update
{
    [super update];
    
    // Update the world variables based on the sliders
    Gravity = self.sliderGravity.value;
    _repulsion = self.sliderRepulsion.value * 2; // (0..2)
    
    float sceneWidth = 2.0f;
    float sceneHeight = 2.0f/_viewAspect;
    
    // We'll use the size of the screen as the max
    float maxDistance = sqrt((sceneWidth * sceneWidth) + (sceneHeight * sceneHeight));
    _distThreshold = self.sliderDistThreshold.value * maxDistance;

    CGRect moverBounds = CGRectMake(-1, -1 / _viewAspect,
                                     sceneWidth, sceneHeight);

    for(NOCMover2D *mover in _movers){
        GLKVector2 force = [self worldForceOnMover:mover];
        [mover applyForce:force];
        [mover stepInRect:moverBounds shouldWrap:NO];
    }
    
}

- (void)resize
{
    [super resize];
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
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

#pragma mark - Mover Behavior

- (GLKVector2)worldForceOnMover:(NOCMover2D *)mover
{
    
    // This iterates over every mover and gives us a cumulative
    // "reaction" vector based on the attraction and repulstion values.

    GLKVector2 vecReaction = GLKVector2Zero;
    
    if(GLKVector2Equal(_vectorTouch, GLKVector2Zero)){
        // There is no gesture.
        // Make them react to each other.

        for(NOCMover2D *moverOther in _movers){
            
            if(moverOther != mover){
                
                GLKVector2 vecDir = GLKVector2Subtract(mover.position, moverOther.position);
                float distance = GLKVector2Length(vecDir);
                GLKVector2 vecNormal = GLKVector2Normalize(vecDir);
                
                // If they share a position, make some nominal delta
                if(distance<=0){
                    distance = 0.001;
                    vecNormal = GLKVector2Random();
                }

                // The attraction or repulstion amount between the two
                float magnitudeMoverForce = map(distance, 0, _distThreshold, -1, 1);
                
                GLKVector2 vecMoverForce = GLKVector2MultiplyScalar(vecNormal, magnitudeMoverForce);
                vecReaction = GLKVector2Subtract(vecReaction, vecMoverForce);
                
            }
        }
        
        vecReaction = GLKVector2Normalize(vecReaction);
        
    }else{
        
        // There is a gesture.
        // Use the touch vector as the force        
        vecReaction = _vectorTouch;

    }
        
    float movementScale = self.sliderVectorScale.value;
    vecReaction = GLKVector2MultiplyScalar(vecReaction, movementScale);
    return vecReaction;
}

#pragma mark - Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //...
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        CGPoint touchPos = [t locationInView:self.view];
        CGPoint prevPos = [t previousLocationInView:self.view];
        // Convert to GL coords
        _vectorTouch = GLKVector2Make(touchPos.x - prevPos.x, prevPos.y - touchPos.y);
    }
    _vectorTouch = GLKVector2Normalize(_vectorTouch);
    _vectorTouch = GLKVector2MultiplyScalar(_vectorTouch, 0.2);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        [self endTouch:t];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        [self endTouch:t];
    }
}

- (void)endTouch:(UITouch *)t
{
    _vectorTouch = GLKVector2Zero;
}

@end

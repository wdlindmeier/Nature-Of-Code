//
//  NOCFlowFieldSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFlowFieldSketchViewController.h"
#import "NOCFlowField.h"
#import "NOCFlowParticle.h"

@interface NOCFlowFieldSketchViewController ()
{
    NOCFlowField *_flowField;
    float _alpha, _beta, _step;
    NSArray *_particles;
    GLKTextureInfo *_textureParticle;
    BOOL _isDrawingFlowField;
}

@end

@implementation NOCFlowFieldSketchViewController

static NSString * ShaderNameFlowField = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * ShaderNameParticles = @"Texture";
static NSString * UniformTexture = @"texture";

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiFlowField";
}

#pragma mark - View 

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sliderStep.value = 0.035;
}

#pragma maek - Sketch Loop

- (void)setup
{
    // Setup the shader
    [super setup];
    
    _isDrawingFlowField = YES;
    
    NOCShaderProgram *shaderFF = [[NOCShaderProgram alloc] initWithName:ShaderNameFlowField];
    
    shaderFF.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                             @"color" : @(GLKVertexAttribColor) };
    
    shaderFF.uniformNames = @[ UniformMVProjectionMatrix ];
    
    [self addShader:shaderFF
              named:ShaderNameFlowField];
    
    
    NOCShaderProgram *shaderParticles = [[NOCShaderProgram alloc] initWithName:ShaderNameParticles];
    
    shaderParticles.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                    @"texCoord" : @(GLKVertexAttribTexCoord0) };
    
    shaderParticles.uniformNames = @[ UniformMVProjectionMatrix, UniformTexture ];
    
    [self addShader:shaderParticles
              named:ShaderNameParticles];
    
    _textureParticle = NOCLoadGLTextureWithName(@"arrow");
    
    _flowField = [[NOCFlowField alloc] initWithWidth:35
                                              height:50];
    // Straighten out all of the vecs
    for(int i=0;i<35;i++){
        for(int j=0;j<50;j++){
            [_flowField setVector:GLKVector3Make(1, 0, 0) atX:i y:j];
        }
    }
    
    [self setupInitialParticles];
}

- (void)setupInitialParticles
{
    int numParticles = 100;
    NSMutableArray *particles = [NSMutableArray arrayWithCapacity:numParticles];
    for(int i=0;i<numParticles;i++){
        NOCFlowParticle *p = [[NOCFlowParticle alloc] initWithSize:GLKVector2Make(0.1, 0.1)
                                                          position:GLKVector2Make((RAND_SCALAR * 2) - 1,
                                                                                  (RAND_SCALAR * 2) - 1)];
        p.maxVelocity = 0.01;
        [particles addObject:p];
    }
    _particles = [NSArray arrayWithArray:particles];
}

- (void)update
{
    [self updateFromGUI];
    [_flowField advance];
    
    CGRect rectBounds = CGRectMake(-1.0, -1.0 / _viewAspect, 2.0, 2.0 / _viewAspect);
    
    for(NOCFlowParticle *p in _particles){
        
        // Get the plot position
        GLKVector2 pPos = p.position;
        float scalarX = (1.0 + pPos.x) / 2.0;
        float scalarY = (((1.0 / _viewAspect) + pPos.y) / (2.0 / _viewAspect));
        int plotX = round(scalarX * _flowField.dimensions.width);
        int plotY = round(scalarY * _flowField.dimensions.height);
        
        // Get the vec at their position
        GLKVector3 vecInfluence = [_flowField vectorAtX:plotX y:plotY];
        GLKVector2 vecApply = GLKVector2Make(vecInfluence.x, vecInfluence.y);
        
        // Apply as a force
        // These are all unit vectors. Scale them down.
        static const float FlowFieldMulti = 0.1;
        vecApply = GLKVector2MultiplyScalar(vecApply, FlowFieldMulti);
        [p applyForce:vecApply];
        
        GLKVector2 worldForce = [self worldForceOnParticle:p];
        [p applyForce:worldForce];
        
        // Step
        [p stepInRect:rectBounds shouldWrap:YES];
        
    }
    
}

- (GLKVector2)worldForceOnParticle:(NOCFlowParticle *)particle
{
    
    // This iterates over every mover and gives us a cumulative
    // "reaction" vector based on the attraction and repulstion values.
    
    GLKVector2 vecReaction = GLKVector2Zero;
    
    float distThreshold = 0.15;
    
    for(NOCFlowParticle *particleOther in _particles){
        
        if(particleOther != particle){
            
            GLKVector2 vecDir = GLKVector2Subtract(particle.position, particleOther.position);
            float distance = GLKVector2Length(vecDir);
            
            if(distance < distThreshold){
                // Repulse
                GLKVector2 vecNormal = GLKVector2Normalize(vecDir);
                
                // If they share a position, make some nominal delta
                if(distance<=0){
                    distance = 0.001;
                    vecNormal = GLKVector2Random();
                }
                
                // The attraction or repulstion amount between the two
                float magnitudeMoverForce = map(distance, 0, distThreshold, -1, 0);
                
                GLKVector2 vecMoverForce = GLKVector2MultiplyScalar(vecNormal, magnitudeMoverForce);
                vecReaction = GLKVector2Subtract(vecReaction, vecMoverForce);
                
            }
        }
    }
    
    float movementScale = 0.01;
    vecReaction = GLKVector2MultiplyScalar(vecReaction, movementScale);
    return vecReaction;
}

- (void)updateFromGUI
{
    BOOL didChange = NO;
    float alpha = self.sliderAlpha.value;
    if(alpha != _alpha){
        didChange = YES;
        _alpha = alpha;
        NSLog(@"_alpha %f", _alpha);
    }
    float beta = self.sliderBeta.value;
    if(beta != _beta){
        didChange = YES;
        _beta = beta;
        NSLog(@"_beta %f", _beta);
    }
    float step = self.sliderStep.value;
    if(step != _step){
        didChange = YES;
        _step = step;
        NSLog(@"step %f", _step);
    }
    if(didChange){
        [_flowField generatePerlinWithAlpha:_alpha
                                       beta:_beta
                                       step:_step];
    }
}

- (void)clear
{
    glClearColor(0.2,0.2,0.2,1);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)draw
{
    [self clear];
    
    if(_isDrawingFlowField){
        NOCShaderProgram *shaderFF = [self shaderNamed:ShaderNameFlowField];
        [shaderFF use];
        [shaderFF setMatrix4:_projectionMatrix2D forUniform:UniformMVProjectionMatrix];
        [_flowField renderInRect:CGRectMake(-1.0, -1.0 / _viewAspect,
                                            2.0, 2.0 / _viewAspect)
                       lineWidth:0.01
                        weighted:YES];
    }
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    NOCShaderProgram *shaderParticles = [self shaderNamed:ShaderNameParticles];
    [shaderParticles use];
    
    // Bind the texture
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, _textureParticle.name);
    
    for(NOCFlowParticle *p in _particles){
        GLKMatrix4 modelMat = [p modelMatrix];
        GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(_projectionMatrix2D, modelMat);
        [shaderParticles setMatrix4:mvpMatrix forUniform:UniformMVProjectionMatrix];
        [p render];
    }
    
    glDisable(GL_BLEND);
}

- (void)teardown
{
    //...
}

#pragma mark - Touch

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        if(t.tapCount > 1){
            _isDrawingFlowField = !_isDrawingFlowField;
        }
    }
}

@end

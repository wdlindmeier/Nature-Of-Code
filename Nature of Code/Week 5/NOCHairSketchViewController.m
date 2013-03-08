//
//  NOCHairSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCHairSketchViewController.h"
//#import "NOCParticle2D.h"
//#import "NOCSpring2D.h"
#import "NOCHair.h"

@interface NOCHairSketchViewController ()
{
    NSMutableArray *_hairs;
    NSMutableSet *_touches;
}

@end

@implementation NOCHairSketchViewController

static NSString * HairShaderName = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - App Loop

- (void)setup
{
    self.view.multipleTouchEnabled = YES;
    
    NOCShaderProgram *shader = [[NOCShaderProgram alloc] initWithName:HairShaderName];

    shader.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                        @"color" : @(GLKVertexAttribColor) };

    shader.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shader named:HairShaderName];

    _touches = [NSMutableSet setWithCapacity:5];
    
    [self reset];
}

- (void)reset
{
    _hairs = [NSMutableArray arrayWithCapacity:100];

    float xIncrement = 2.0 / 100.0f;
    float restLength = 0.05;
    
    for(int i=0;i<50;i++){
        
        float pX = -0.5 + (xIncrement * i);
        float pY = 0.5;
        GLKVector2 posAnchor = GLKVector2Make(pX, pY);
        NOCHair *hair = [[NOCHair alloc] initWithAnchor:posAnchor
                                           numParticles:10
                                               ofLength:restLength];
        [_hairs addObject:hair];
    }
}

- (void)update
{
    GLKVector2 gravity = GLKVector2Make(0, -0.05);
    
    // Calculate the touch positions
    int numTouches = _touches.count;
    GLKVector2 touchPos[numTouches];
    int i=0;
    for(UITouch *t in _touches){
        CGPoint posTouch = [t locationInView:self.view];
        CGRect frame = self.view.frame;
        GLKVector2 posWind = NOCGLPositionFromCGPointInRect(posTouch, frame);
        posWind.y *= -1;
        touchPos[i] = posWind;
        i++;
    }
    
    float xOff = cos(self.frameCount * 0.05) * 0.01;
    
    for(NOCHair *h in _hairs)
    {
        // Test moving the anchor point.
        // This will be used on the face
        GLKVector2 anchorPoint = h.anchor;
        anchorPoint.x += xOff;
        h.anchor = anchorPoint;
        
        [h applyForce:gravity];
        for(int i=0;i<numTouches;i++){
            GLKVector2 posWind = touchPos[i];
            [h applyPointForce:posWind
                 withMagnitude:^float(float distToParticle) {
                     // This makes the wind diminish if the particle is further away.
                     return 0.035 / distToParticle;
                 }];
        }
        
        [h update];
    }
}

- (void)draw
{
    [self clear];
    
    NOCShaderProgram *shaderHair = [self shaderNamed:HairShaderName];
    [shaderHair use];
    
    const static GLfloat colorParticles[] = {
        1.0,0,0,1.0,
        1.0,0,0,1.0,
        1.0,0,0,1.0,
        1.0,0,0,1.0,
    };
    
    const static GLfloat colorSprings[] = {
        1.0,1,0,1.0,
        1.0,1,0,1.0,
        1.0,1,0,1.0,
        1.0,1,0,1.0,
    };

    for(NOCHair *h in _hairs){

        [h renderParticles:^(GLKMatrix4 particleMatrix, NOCParticle2D *p) {

            GLKMatrix4 mvProjMat = GLKMatrix4Multiply(_projectionMatrix2D, particleMatrix);
            [shaderHair setMatrix:mvProjMat forUniform:UniformMVProjectionMatrix];
            
            glEnableVertexAttribArray(GLKVertexAttribColor);
            glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &colorParticles);

        } andSprings:^(GLKMatrix4 springMatrix, NOCSpring2D *s) {
            
            GLKMatrix4 mvProjMat = GLKMatrix4Multiply(_projectionMatrix2D, springMatrix);
            [shaderHair setMatrix:mvProjMat forUniform:UniformMVProjectionMatrix];

            glEnableVertexAttribArray(GLKVertexAttribColor);
            glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &colorSprings);

        }];

    }
    
}

- (void)teardown
{
    //...
}

#pragma mark - Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        [_touches addObject:t];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        [_touches removeObject:t];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        [_touches removeObject:t];
    }
}

@end

//
//  NOCTouchFlowFieldViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTouchFlowFieldSketchViewController.h"
#import "NOCFlowField.h"
#import "NOCFlowParticle.h"

@interface NOCTouchFlowFieldSketchViewController ()
{
    NOCFlowField *_flowField;
    float _alpha, _beta, _step;
}
@end

@implementation NOCTouchFlowFieldSketchViewController

static NSString * ShaderNameFlowField = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiFlowField";
}

#pragma maek - Sketch Loop

- (void)setup
{
    // Setup the shader
    [super setup];
    
    self.view.multipleTouchEnabled = YES;
    
    NOCShaderProgram *shaderFF = [[NOCShaderProgram alloc] initWithName:ShaderNameFlowField];
    
    shaderFF.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                             @"color" : @(GLKVertexAttribColor) };
    
    shaderFF.uniformNames = @[ UniformMVProjectionMatrix ];
    
    [self addShader:shaderFF
              named:ShaderNameFlowField];
    
    _flowField = [[NOCFlowField alloc] initWithWidth:35
                                              height:50];
}

- (void)update
{
    [self updateFromGUI];
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
    
    NOCShaderProgram *shaderFF = [self shaderNamed:ShaderNameFlowField];
    [shaderFF use];
    [shaderFF setMatrix4:_projectionMatrix2D forUniform:UniformMVProjectionMatrix];
    [_flowField renderInRect:CGRectMake(-1.0, -1.0 / _viewAspect,
                                        2.0, 2.0 / _viewAspect)
                   lineWidth:0.015
                    weighted:YES];
}

- (void)teardown
{
    //...
}

#pragma mark - Touch

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        CGPoint touchPos = [t locationInView:self.view];
        CGPoint prevPos = [t previousLocationInView:self.view];
        GLKVector2 glPos = NOCGLPositionFromCGPointInRect(touchPos, self.view.bounds);
        GLKVector2 glPosPrev = NOCGLPositionFromCGPointInRect(prevPos, self.view.bounds);
        glPos.y *= -1;
        glPosPrev.y *= -1;
        
        [self affectFieldFromTouchPoint:glPos toPoint:glPosPrev];
    }
}

- (void)affectFieldFromTouchPoint:(GLKVector2)pos1 toPoint:(GLKVector2)pos2
{
    // For the moment, let's iterate over the entire grid
    // Compare the position of the plot with the line
    GLKVector2 vec = GLKVector2Subtract(pos2, pos1);
    GLKVector2 vecUnit = GLKVector2Normalize(vec);
    
    float plotWidth = 2.0 / _flowField.dimensions.width;
    float plotHeight = 2.0 / _viewAspect / _flowField.dimensions.height;
    
    float maxRange = 0.3;
    float touchInfluence = 0.35;
    
    
    // TODO:
    // Only iterate over the ones that are close to the touch
    
    for(int x=0;x<_flowField.dimensions.width;x++){
        for(int y=0;y<_flowField.dimensions.height;y++){
            
            float plotX = -1.0 + (plotWidth * x) + (plotWidth * 0.5);
            float plotY = (-1.0/_viewAspect) + (plotHeight * y) + (plotHeight*0.5);
            
            GLKVector2 plotCenter = GLKVector2Make(plotX,plotY);
            
            float distFrom1 = GLKVector2Distance(plotCenter, pos1);
            float distFrom2 = GLKVector2Distance(plotCenter, pos2);
            float minDist = MIN(distFrom1, distFrom2);
            
            if(minDist <= maxRange){
                
                // NOTE: This doesn't take into account the scenario
                // where pos1 and pos2 are further from each other than the
                // min range, thus creating a line, but in practice, this
                // doesn't seem to happen with the touch events.
                
                GLKVector3 vecPlot3 = [_flowField vectorAtX:x y:y];
                GLKVector2 vecPlot = GLKVector2Make(vecPlot3.x, vecPlot3.y);
                
                // Now we can divide the unit vector by the distance and apply that to the plot
                GLKVector2 vecDelta = GLKVector2Subtract(vecUnit, vecPlot);
                float amtInfluence = ((maxRange - minDist) / maxRange) * touchInfluence;
                GLKVector2 vecInfluence = GLKVector2MultiplyScalar(vecDelta, amtInfluence);
                GLKVector3 newPlotVec = GLKVector3Add(vecPlot3,
                                                      GLKVector3Make(vecInfluence.x, vecInfluence.y, 0));
                [_flowField setVector:GLKVector3Normalize(newPlotVec)
                                  atX:x
                                    y:y];
                
            }
        }
    }
}

@end

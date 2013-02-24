//
//  NOCPaperBurnSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCPaperBurnSketchViewController.h"
#import "NOCFlame.h"
#import "NOCFlameParticle.h"
#import "NOCFrameBuffer.h"
#import <CoreMotion/CoreMotion.h>

@interface NOCPaperBurnSketchViewController ()
{
    NSMutableArray *_flames;
    CMMotionManager *_motionManager;
    GLKTextureInfo *_flameTexture;
    NOCFrameBuffer *_fbo;
}

@end

@implementation NOCPaperBurnSketchViewController

// NOTE: Keep this in sync w/ the shader array value
static const int MaxNumFlames = 10;
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformTexture = @"texture";
static NSString * UniformFlamePositions = @"flamePositions";
static NSString * NOCPaperShaderName = @"Paper";
static NSString * NOCTextureShaderName = @"Texture";

#pragma mark - Accessors

// We're tracking motion, so don't allow autorotation
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - Sketch

- (void)setup
{
    CGSize sizeView = self.view.frame.size;
    
    _fbo = [[NOCFrameBuffer alloc] initWithPixelWidth:sizeView.width
                                          pixelHeight:sizeView.height];
    
    // Motion
    _motionManager = [[CMMotionManager alloc] init];
    [_motionManager startDeviceMotionUpdates];
    
    _flameTexture = NOCLoadGLTextureWithName(@"flame_red");;
    
    // Flames
    _flames = [NSMutableArray arrayWithCapacity:MaxNumFlames];
    
    // Shaders
    NOCShaderProgram *paperShader = [[NOCShaderProgram alloc] initWithName:NOCPaperShaderName];
    paperShader.attributes = @{@"position" : @(GLKVertexAttribPosition),
                               @"texCoord" : @(GLKVertexAttribTexCoord0)};
    paperShader.uniformNames = @[ UniformMVProjectionMatrix, UniformFlamePositions, UniformTexture ];

    NOCShaderProgram *textureShader = [[NOCShaderProgram alloc] initWithName:NOCTextureShaderName];
    textureShader.attributes = @{@"position" : @(GLKVertexAttribPosition),
                                @"texCoord" : @(GLKVertexAttribTexCoord0)};
    textureShader.uniformNames = @[ UniformMVProjectionMatrix, UniformTexture ];
    
    self.shaders = @{ NOCPaperShaderName : paperShader, NOCTextureShaderName : textureShader };
    
    
}

- (void)update
{
    GLKVector2 motionVector = [self motionVectorFromManager:_motionManager];
    motionVector = GLKVector2MultiplyScalar(motionVector, -0.0001); // Eyeball the desired lift
    
    NSMutableArray *deadFlames = [NSMutableArray arrayWithCapacity:_flames.count];
    for(NOCFlame *flame in _flames){
        
        // TMP
        float newX = flame.position.x + motionVector.x * 20;
        float newY = flame.position.y + motionVector.y * 20;
        if(newX < -1.5 ||
           newX > 1.5 ||
           newY < -1.5 ||
           newY > 1.5 ){
            [deadFlames addObject:flame];
        }else{
            flame.position = GLKVector3Make(newX, newY, 0);
        }
        
        [flame stepWithLift:motionVector];
        
    }
    
    for(NOCFlame *flame in deadFlames){
        [_flames removeObject:flame];
    }
    
}

- (void)renderPaperToFBO
{
    // Draw a red square w/ the paper shader
    [_fbo bind];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    NOCShaderProgram *paperShader = self.shaders[NOCPaperShaderName];
    [paperShader use];
    // Binding the fbo as a texture so we can access the previous pixel color
    [_fbo bindTexture:0];
    [paperShader setInt:0 forUniform:UniformTexture];

    NSNumber *uniLoc = paperShader.uniformLocations[UniformFlamePositions];
    GLfloat flameLocs[MaxNumFlames*3];
    for(int i=0;i<MaxNumFlames;i++){
        if(_flames.count > i){
            NOCFlame *flame = _flames[i];
            flameLocs[i*3+0] = flame.position.x;
            flameLocs[i*3+1] = flame.position.y * -1; // Not sure why I have to flip the y...
            flameLocs[i*3+2] = flame.position.z;
        }else{
            // just fill it up w/ junk data
            flameLocs[i*3+0] = -100;
            flameLocs[i*3+1] = -100;
            flameLocs[i*3+2] = -100;
        }
    }
    glUniform3fv([uniLoc intValue], MaxNumFlames, flameLocs);

    [paperShader setMatrix:_projectionMatrix2D forUniform:UniformMVProjectionMatrix];
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &Screen3DBillboardVertexData);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &Square3DTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // unbind
    [(GLKView*)self.view bindDrawable];   
}

- (void)draw
{
    [self renderPaperToFBO];
    
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    // Draw the FBO as a texture
    NOCShaderProgram *texShader = self.shaders[NOCTextureShaderName];
    [texShader use];
    [texShader setMatrix:_projectionMatrix2D forUniform:UniformMVProjectionMatrix];
    [_fbo bindTexture:0];
    [texShader setInt:0 forUniform:UniformTexture];

    // This should draw a distorted box, since we're drawing the whole FBO in a square
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &Screen3DBillboardVertexData);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &Square3DTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    for(NOCFlame *flame in _flames){
        [flame renderInMatrix:_projectionMatrix2D];
    }
}

- (void)teardown
{
    [_motionManager stopDeviceMotionUpdates];
}

#pragma mark - Touch

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        
        if(t.tapCount > 0 && _flames.count < MaxNumFlames){
            
            // Add a new flame
            CGPoint posTouch = [t locationInView:self.view];
            CGSize sizeView = self.view.frame.size;
            float aspect = sizeView.width / sizeView.height;
            
            float scalarX = posTouch.x / sizeView.width;
            float scalarY = 1.0 - (posTouch.y / sizeView.height);
            
            float glX = (scalarX * 2.0f) - 1.0f;
            float glY = (scalarY * (2.0f / aspect)) - (1.0 / aspect);
            
            NOCFlame *flame = [[NOCFlame alloc] initWithPosition:GLKVector3Make(glX, glY, 0)
                                                    flameTexture:_flameTexture];
            [_flames addObject:flame];

        }
        
    }
    
}

@end

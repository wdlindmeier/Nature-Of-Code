//
//  NOCFaceCapSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFaceCapSketchViewController.h"

@interface NOCFaceCapSketchViewController ()
{
    UIView *_viewVideoPreview;
    GLKTextureInfo *_textureVideo;
}
@end

static NSString * TextureShaderName = @"Texture";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformTexture = @"texture";

@implementation NOCFaceCapSketchViewController

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
    NOCShaderProgram *texShader = [[NOCShaderProgram alloc] initWithName:TextureShaderName];

    texShader.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                              @"texCoord" : @(GLKVertexAttribTexCoord0) };

    texShader.uniformNames = @[ UniformMVProjectionMatrix, UniformTexture ];

    self.shaders = @{ TextureShaderName : texShader };

    // Ignoring faces for the moment
    _videoSession = [[NOCVideoSession alloc] initWithDelegate:nil]; //self];
    _videoSession.shouldOutlineFaces = NO;
    
    const static BOOL USE_CA_PREVIEW = NO;
    
    if(!USE_CA_PREVIEW){
        
        // OpenGL preview
        [_videoSession setupWithDevice:[NOCVideoSession frontFacingCamera] inContext:self.context];
        
    }else{
    
        // CALayer preview
        AVCaptureVideoPreviewLayer *videoPreview = [_videoSession setupForPreviewWithDevice:[NOCVideoSession frontFacingCamera]];

        _viewVideoPreview = [[UIView alloc] initWithFrame:self.view.bounds];
        
        [self.view addSubview:_viewVideoPreview];
        CALayer *rootLayer = [_viewVideoPreview layer];
        [rootLayer setMasksToBounds:YES];
        [videoPreview setFrame:[rootLayer bounds]];
        [rootLayer addSublayer:videoPreview];
        
    }
    
    _textureVideo = NOCLoadGLTextureWithName(@"face");
    
}

- (void)update
{
    //...
}

- (void)clear
{
    glClearColor(0.4, 0.4, 0.4, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)draw
{
    [self clear];
    
    NOCShaderProgram *texShader = self.shaders[TextureShaderName];
    [texShader use];
    [texShader setMatrix:_projectionMatrix2D forUniform:UniformMVProjectionMatrix];
    
    [_videoSession bindTexture:0];
    [texShader setInt:0 forUniform:UniformTexture];

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_screen3DBillboardVertexData);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &Square3DTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindTexture(GL_TEXTURE_2D, 0);

}

- (void)teardown
{
    [super teardown];
    [_videoSession teardown];
    _videoSession = nil;
}

#pragma mark - Video 

- (void)videoSession:(NOCVideoSession *)videoSession
       detectedFaces:(NSArray *)faceFeatures
             inFrame:(CGRect)previewFrame
         orientation:(UIDeviceOrientation)orientation
               scale:(CGSize)videoScale
{
    // Do something
}

@end

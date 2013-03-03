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
    NSArray *_faceRects;
}
@end

static NSString * TextureShaderName = @"Texture";
static NSString * FaceShaderName = @"SceneBox";
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
    
    NOCShaderProgram *shaderFace = [[NOCShaderProgram alloc] initWithName:FaceShaderName];
    shaderFace.attributes = @{ @"position" : @(GLKVertexAttribPosition) };
    shaderFace.uniformNames = @[ UniformMVProjectionMatrix ];

    self.shaders = @{ TextureShaderName : texShader };

    _videoSession = [[NOCVideoSession alloc] initWithFaceDelegate:self];
    
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
    
    // Account for camera texture orientation
    float scaleX = [_videoSession isMirrored] ? -1 : 1;
    GLKMatrix4 matTexture = GLKMatrix4MakeScale(scaleX, -1, 1);
    matTexture = GLKMatrix4RotateZ(matTexture, M_PI * 0.5);
    matTexture = GLKMatrix4Multiply(matTexture, _projectionMatrix2D);
    
    [texShader setMatrix:matTexture forUniform:UniformMVProjectionMatrix];
    
    [_videoSession bindTexture:0];
    [texShader setInt:0 forUniform:UniformTexture];

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_screen3DBillboardVertexData);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &Square3DTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // Draw faces
    
    // Draw the scene box
    NOCShaderProgram *shaderFace = self.shaders[FaceShaderName];
    [shaderFace use];
    [shaderFace setMatrix:matTexture forUniform:UniformMVProjectionMatrix];

    // Draw a stroked cube
    for(NSValue *rectValue in _faceRects){
        CGRect rect = [rectValue CGRectValue];
        GLfloat verts[] = {
            rect.origin.x, rect.origin.y + rect.size.height, 0,
            rect.origin.x + rect.size.width, rect.origin.y + rect.size.height, 0,
            rect.origin.x + rect.size.width, rect.origin.y, 0,
            rect.origin.x, rect.origin.y, 0,
        };
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &verts);
        int numCoords = sizeof(verts) / sizeof(GLfloat) / 3;
        glDrawArrays(GL_LINE_LOOP, 0, numCoords);
    }

}

- (void)teardown
{
    [super teardown];
    [_videoSession teardown];
    _videoSession = nil;
}

#pragma mark - Video 

- (CGSize)sizeVideoFrameInGLSpaceForSession:(NOCVideoSession *)session
{
    //return CGSizeMake(2.0, 2.0 / _viewAspect);
    // TMP
    // For the moment lets return the size of the view
    return self.view.frame.size;
}

- (void)videoSession:(NOCVideoSession *)videoSession
       detectedFaces:(NSArray *)faceFeatures
             inFrame:(CGRect)previewFrame
         orientation:(UIDeviceOrientation)orientation
               scale:(CGSize)videoScale
{

    NSMutableArray *rects = [NSMutableArray arrayWithCapacity:faceFeatures.count];

    for ( CIFaceFeature *ff in faceFeatures ) {

        CGRect faceRect = [ff bounds];
        
        // Scale up from image size to view size
        faceRect = CGRectApplyAffineTransform(faceRect, CGAffineTransformMakeScale(videoScale.width, videoScale.height));

        // Mirror if source is mirrored
        if ([_videoSession isMirrored])
            faceRect = CGRectApplyAffineTransform(faceRect, CGAffineTransformMakeScale(-1, 1));
        
        // Translate the rect origin
        faceRect = CGRectApplyAffineTransform(faceRect, CGAffineTransformMakeTranslation(previewFrame.origin.x, previewFrame.origin.y));

        // Convert to GL space
        GLKVector2 glPos = NOCGLPositionFromCGPointInRect(faceRect.origin, previewFrame);
        float scale = 2.0f / previewFrame.size.width;
        GLKVector2 glSize = GLKVector2Make(faceRect.size.width * scale,
                                           faceRect.size.height * scale);
        
        [rects addObject:[NSValue valueWithCGRect:CGRectMake(glPos.x, glPos.y,
                                                             glSize.x, glSize.y)]];

    }

    _faceRects = [NSArray arrayWithArray:rects];

}

@end

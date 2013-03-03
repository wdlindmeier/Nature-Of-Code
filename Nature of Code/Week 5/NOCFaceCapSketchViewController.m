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
static NSString * FaceShaderName = @"Triangulation";
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
    shaderFace.attributes = @{@"position" : @(GLKVertexAttribPosition),
                             @"texCoord" : @(GLKVertexAttribTexCoord0)};
    shaderFace.uniformNames = @[UniformMVProjectionMatrix, UniformTexture];

    self.shaders = @{ TextureShaderName : texShader, FaceShaderName : shaderFace };

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
    
    // Account for camera texture orientation
    float scaleX = [_videoSession isMirrored] ? -1 : 1;
    GLKMatrix4 matTexture = GLKMatrix4MakeScale(scaleX, -1, 1);
    matTexture = GLKMatrix4RotateZ(matTexture, M_PI * 0.5);
    matTexture = GLKMatrix4Multiply(matTexture, _projectionMatrix2D);
    

    // Draw the video background
    NOCShaderProgram *texShader = self.shaders[TextureShaderName];
    [texShader use];
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
    NOCShaderProgram *shaderFace = self.shaders[FaceShaderName];
    [shaderFace use];
    [shaderFace setMatrix:matTexture forUniform:UniformMVProjectionMatrix];
    [_videoSession bindTexture:0];
    [shaderFace setInt:0 forUniform:UniformTexture];

    // Draw a stroked cube
    for(NSValue *rectValue in _faceRects){
        
        CGRect rect = [rectValue CGRectValue];
        
        // Generate the average tex coords
        int vxPerTri = 3;
        int numTri = 2;
        int numTexIdx = vxPerTri * numTri * 2;
        int numVertIdx = numTri * vxPerTri * 3;
        
        GLfloat verts[] = {
            
            // Tri UL
            rect.origin.x + rect.size.width, rect.origin.y + rect.size.height, 0,
            rect.origin.x, rect.origin.y + rect.size.height, 0,
            rect.origin.x, rect.origin.y, 0,

            // Tri LR
            rect.origin.x + rect.size.width, rect.origin.y + rect.size.height, 0,
            rect.origin.x + rect.size.width, rect.origin.y, 0,
            rect.origin.x, rect.origin.y, 0,
        };
        
        GLfloat texCoords[numTexIdx];
        
        for(int i=0;i<numTri;i++){
            float avgX = 0;
            float avgY = 0;

            for(int j=0;j<vxPerTri;j++){
                avgX += verts[(i*vxPerTri*3)+(j*3)+0];
                avgY += verts[(i*vxPerTri*3)+(j*3)+1];
            }
            avgX = avgX / vxPerTri;
            avgY = avgY / vxPerTri;

            for(int j=0;j<vxPerTri;j++){
                texCoords[(i*vxPerTri*2)+(j*2)+0] = 0.5 + (avgX * 0.5);
                texCoords[(i*vxPerTri*2)+(j*2)+1] = 0.5 + (avgY * -0.5);
            }
        }
        
        /*
        float avgX1 = (verts[0] + verts[3] + verts[6]) / 3.0f;
        avgX1 = 0.5 + (avgX1 * 0.5);
        float avgY1 = (verts[1] + verts[4] + verts[7]) / 3.0f;
        avgY1 = 0.5 + (avgY1 * -0.5);

        float avgX2 = (verts[9] + verts[12] + verts[15]) / 3.0f;
        avgX2 = 0.5 + (avgX2 * 0.5);
        float avgY2 = (verts[10] + verts[13] + verts[16]) / 3.0f;
        avgY2 = 0.5 + (avgY2 * -0.5);

        GLfloat texCoords[] = {
            avgX1,avgY1,
            avgX1,avgY1,
            avgX1,avgY1,
            
            avgX2,avgY2,
            avgX2,avgY2,
            avgX2,avgY2,
        };
        */
        
        /*
        GLfloat texCoords[numTexIdx];

        for(int i=0;i<numTri;i++){
            float sumX = 0;
            float sumY = 0;
            for(int j=0;j<vxPerTri;j++){
                float vX = verts[(i*vxPerTri)+(j*3)+0];
                float vY = verts[(i*vxPerTri)+(j*3)+1];
                float texCoordX = 0.5 + (vX * 0.5);
                float texCoordY = 0.5 + (vY * -0.5);
                sumX += texCoordX;
                sumY += texCoordY;
            }
            float avgX = sumX / (float)vxPerTri;
            float avgY = sumY / (float)vxPerTri;
            for(int j=0;j<vxPerTri;j++){
                texCoords[(i*vxPerTri)+(j*2)+0] = avgX;
                texCoords[(i*vxPerTri)+(j*2)+1] = avgY;
            }
        }
        */
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &verts);
        
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &texCoords);

        int numCoords = sizeof(verts) / sizeof(GLfloat) / 3;
        glDrawArrays(GL_TRIANGLES, 0, numCoords);
        
    }

}

- (void)teardown
{
    [super teardown];
    [_videoSession teardown];
    _videoSession = nil;
}

#pragma mark - Video 

- (CGSize)sizeVideoFrameForSession:(NOCVideoSession *)session
{
    return _sizeView;
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

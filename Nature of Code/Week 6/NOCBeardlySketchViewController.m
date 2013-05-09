//
//  NOCBeardMatrixViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/9/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCBeardlySketchViewController.h"
#import "NOCBeard.h"
#import "NOCHair.h"
#import "NOCSketchViewController+OpenGLScreenCapture.h"

@interface NOCBeardlySketchViewController ()
{
    NSArray *_faceRects;
    int _numFramesWithoutFace;
    int _numFramesWithFace;
    GLKVector2 _posBeard;
    GLKMatrix4 _matVideoTexture;
    NOCBeard *_beard;
    float _beardScale;
    float _beardScaleTo;
    NSMutableSet *_touches;
    BOOL _beardIsDirty;
    GLKTextureInfo *_textureHair;
}
@end

@implementation NOCBeardlySketchViewController

static NSString * TextureShaderName = @"Texture";
static NSString * FaceTrackingShaderName = @"ColoredVerts";
static NSString * HairShaderName = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformTexture = @"texture";
static const int NumFramesWithoutFaceToResetBeard = 30;

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIButton *buttonCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonCamera setImage:[UIImage imageNamed:@"camera"]
                  forState:UIControlStateNormal];
    [buttonCamera sizeToFit];
    CGSize sizeCam = buttonCamera.frame.size;
    [buttonCamera setBackgroundColor:[UIColor clearColor]];
    [buttonCamera addTarget:self action:@selector(buttonCameraPressed:) forControlEvents:UIControlEventTouchUpInside];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        buttonCamera.frame = CGRectMake(50, 50, sizeCam.width + 20, sizeCam.height + 16);
        buttonCamera.transform = CGAffineTransformMakeScale(0.8, 0.8);
    }else{
        buttonCamera.frame = CGRectMake(10, 10, sizeCam.width + 20, sizeCam.height + 16);
        buttonCamera.transform = CGAffineTransformMakeScale(0.5, 0.5);
    }
    [self.view addSubview:buttonCamera];
}

#pragma mark - Accessors

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiBeardPicker";
}

- (void)setBeardType:(NOCBeardType)type
{
    _beard = [[NOCBeard alloc] initWithBeardType:type
                                        position:GLKVector2Zero
                                         texture:_textureHair];
    
    _faceRects = nil;
    _numFramesWithoutFace = 1;
    _numFramesWithFace = 0;
    _posBeard = GLKVector2Zero;
    _beardScale = 1;
    _beardScaleTo = 1;
    _beardIsDirty = YES;
}

#pragma mark - App Loop

- (void)setup
{
    // Setup the shaders
    // Hair shader
    NOCShaderProgram *shader = [[NOCShaderProgram alloc] initWithName:HairShaderName];
    shader.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                           @"color" : @(GLKVertexAttribColor) };
    shader.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shader named:HairShaderName];
 
    // Video texture
    NOCShaderProgram *texShader = [[NOCShaderProgram alloc] initWithName:TextureShaderName];
    texShader.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                              @"texCoord" : @(GLKVertexAttribTexCoord0) };
    texShader.uniformNames = @[ UniformMVProjectionMatrix, UniformTexture ];
    [self addShader:texShader named:TextureShaderName];
    
    // Create the beard
    _textureHair = NOCLoadGLTextureWithName(@"beard_hair_cartoon");
    [self setBeardType:NOCBeardTypeStandard];
    
    // Video
    _videoSession = [[NOCVideoSession alloc] initWithFaceDelegate:self];
    _videoSession.shouldDetectFacesInBackground = YES;
    [_videoSession setupWithDevice:[NOCVideoSession frontFacingCamera] inContext:self.context];
    
    _numFramesWithoutFace = 0;
    _numFramesWithFace = 0;
    _posBeard = GLKVector2Zero;
    
    _beardIsDirty = NO;

    _touches = [NSMutableSet setWithCapacity:5];
    
    self.view.multipleTouchEnabled = YES;
}

- (void)update
{

    if(_faceRects.count > 0){
        
        _beardIsDirty = YES;
        
        [self applyTouchesToBeard];

        [self repositionBeard];

    }else if(_beardIsDirty && _numFramesWithoutFace > NumFramesWithoutFaceToResetBeard){
        
        [_beard reset];
        
        // I love this variable name
        _beardIsDirty = NO;
        
    }
    
}
- (void)applyTouchesToBeard
{
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
    
    for(NOCHair *h in [_beard hairs])
    {
        for(int i=0;i<numTouches;i++){
            GLKVector2 posWind = touchPos[i];
            [h applyPointForce:posWind
                 withMagnitude:^float(float distToParticle) {
                     // This makes the wind diminish if the particle is further away.
                     return 0.035 / distToParticle;
                 }];
        }
    }    
}

- (void)repositionBeard
{
    NSValue *rectFaceVal = _faceRects[0];
    CGRect rectFace = [rectFaceVal CGRectValue];
    
    // Account for video transform
    CGAffineTransform videoTransform = CGAffineTransformMakeRotation(M_PI * 0.5);
    videoTransform = CGAffineTransformScale(videoTransform, -1, 1);
    rectFace = CGRectApplyAffineTransform(rectFace, videoTransform);
    
    // Set the beard scale
    // The beard is 1 unit
    CGSize sizeFace = rectFace.size;
    float newScale = sizeFace.width / 1.0f * 0.7; // eyeball to taste
    
    // Lerp
    _beardScaleTo = newScale;
    _beardScale = _beardScale + (_beardScaleTo - _beardScale) * 0.2;
    
    // No Lerp
    //_beardScale = newScale;
    
    // Account for scale in positioning because the whole matrix is scaled
    // up, including the location of each hair
    GLKVector2 newPosBeard = GLKVector2Make(CGRectGetMidX(rectFace) * _viewAspect / _beardScale,
                                            CGRectGetMidY(rectFace) / _viewAspect / _beardScale);
    
    if(_numFramesWithFace == 1){
        // The first frame should just drop the beard on top of the face w/ out transition
        _beard.position = newPosBeard;
        _posBeard = newPosBeard;
    }
    
    GLKVector2 posBeardDelta = GLKVector2Subtract(newPosBeard, _posBeard);
    _posBeard = newPosBeard;
    
    [_beard updateWithOffset:posBeardDelta];
}

- (void)draw
{
    [self clear];
    
    // Account for camera texture orientation
    float scaleX = [_videoSession isMirrored] ? -1 : 1;
    GLKMatrix4 matTexture = GLKMatrix4MakeScale(scaleX, -1, 1);
    matTexture = GLKMatrix4RotateZ(matTexture, M_PI * 0.5);
    _matVideoTexture = GLKMatrix4Multiply(matTexture, _projectionMatrix2D);
    
    // Draw the video
    [self drawVideoTexture];
    
    // Draw a strokeded line
    // [self drawFaceTracking];
    
    // Draw the beard
    if(_faceRects.count > 0){
        [self drawBeard];
    }

}

- (void)drawVideoTexture
{
    // Draw the video background    
    NOCShaderProgram *texShader = [self shaderNamed:TextureShaderName];
    [texShader use];
    [texShader setMatrix4:_matVideoTexture forUniform:UniformMVProjectionMatrix];
    [_videoSession bindTexture:0];
    [texShader setInt:0 forUniform:UniformTexture];
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_screen3DBillboardVertexData);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &Square3DTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindTexture(GL_TEXTURE_2D, 0);   
}

- (void)drawFaceTracking
{    
    // Draw faces
    NOCShaderProgram *shaderFace = [self shaderNamed:FaceTrackingShaderName];
    [shaderFace use];
    [shaderFace setMatrix4:_matVideoTexture forUniform:UniformMVProjectionMatrix];
    
    // Draw a stroked cube
    for(NSValue *rectValue in _faceRects){
        
        CGRect rect = [rectValue CGRectValue];
        
        GLfloat verts[] = {
            rect.origin.x, rect.origin.y + rect.size.height, 0,
            rect.origin.x + rect.size.width, rect.origin.y + rect.size.height, 0,
            rect.origin.x + rect.size.width, rect.origin.y, 0,
            rect.origin.x, rect.origin.y, 0,
        };
        
        const static GLfloat colors[] = {
            1.0,0.0,0.0,1.0,
            1.0,0.0,0.0,1.0,
            1.0,0.0,0.0,1.0,
            1.0,0.0,0.0,1.0,
        };
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &verts);
        glEnableVertexAttribArray(GLKVertexAttribColor);
        glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &colors);
        
        glDrawArrays(GL_LINE_LOOP, 0, 4);
        
    }
}

- (void)drawBeard
{
    GLKMatrix4 matBeard = GLKMatrix4Scale(_projectionMatrix2D, _beardScale, _beardScale, 1.0);
    [_beard renderInMatrix:matBeard];
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
    
    static const int NumEmptyFramesForClearingFaces = 5;
    
    if(faceFeatures.count == 0){
        
        _numFramesWithFace = 0;
        _numFramesWithoutFace++;
        
        if(_numFramesWithoutFace > NumEmptyFramesForClearingFaces){
            
            // Only reset if the face is gone for a bit.
            // The detector can be a little choppy.
            _faceRects = nil;
        }
        // otherwise, just keep the current rect
        
    }else{
        
        _numFramesWithoutFace = 0;
        _numFramesWithFace++;
        
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
    
}

#pragma mark - IBActions

- (IBAction)buttonCameraPressed:(id)sender
{
    UIView *viewFlash = [[UIView alloc] initWithFrame:self.view.bounds];
    viewFlash.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:viewFlash];
    [UIView animateWithDuration:0.25
                     animations:^{
                         viewFlash.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         [viewFlash removeFromSuperview];
                     }];
    UIImage *screenshot = [self openGLSnapshot];
    UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, NULL);
}

- (IBAction)buttonResetPressed:(id)sender
{
    [_beard reset];
}

- (IBAction)buttonBeardStandardPressed:(id)sender
{
    [self setBeardType:NOCBeardTypeStandard];
    [self buttonHideControlsPressed:nil];
}

- (IBAction)buttonBeardLincolnPressed:(id)sender
{
    [self setBeardType:NOCBeardTypeLincoln];
    [self buttonHideControlsPressed:nil];
}

- (IBAction)buttonBeardHoganPressed:(id)sender
{
    [self setBeardType:NOCBeardTypeHogan];
    [self buttonHideControlsPressed:nil];
}

- (IBAction)buttonBeardGoteePressed:(id)sender
{
    [self setBeardType:NOCBeardTypeGotee];
    [self buttonHideControlsPressed:nil];
}

- (IBAction)buttonBeardWolverinePressed:(id)sender
{
    [self setBeardType:NOCBeardTypeWolverine];
    [self buttonHideControlsPressed:nil];
}

- (IBAction)buttonBeardMuttonPressed:(id)sender
{
    [self setBeardType:NOCBeardTypeMutton];
    [self buttonHideControlsPressed:nil];
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
        if(t.tapCount > 1){
            [self buttonResetPressed:nil];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        [_touches removeObject:t];
    }
}


@end

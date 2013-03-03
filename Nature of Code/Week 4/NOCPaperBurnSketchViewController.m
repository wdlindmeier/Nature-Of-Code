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
#import "NOCUIKitHelpers.h"
#import "NOCOpenGLHelpers.h"

@interface NOCPaperBurnSketchViewController ()
{
    NSMutableArray *_flames;
    CMMotionManager *_motionManager;
    GLKTextureInfo *_textureFlame;
    GLKTextureInfo *_texturePaper;
    NOCFrameBuffer *_fbo;
    UIImageView *_imageViewSample;
    UIView *_viewVecPointer;
    BOOL _hasRenderedTexture;
}

@end

@implementation NOCPaperBurnSketchViewController

// NOTE: Keep this in sync w/ the shader array value
static const int MaxNumFlames = 10;
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformTexture = @"texture";
static NSString * UniformFlamePositions = @"flamePositions";
static NSString * PaperShaderName = @"Paper";
static NSString * TextureShaderName = @"Texture";

// World constants
static const float FlameSpeed = 0.01;
static const float MotionLiftMultiplier = -0.0001;
static const float MotionLiftAffectOnBurnDirection = 0.35 / MotionLiftMultiplier * -1;

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

#pragma mark - View

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(!_fbo){
        _fbo = [[NOCFrameBuffer alloc] initWithPixelWidth:_sizeView.width
                                              pixelHeight:_sizeView.height];
        
        [self createPaperTexture];
    }
}

#pragma mark - Sketch

- (void)setup
{
    _hasRenderedTexture = NO;

    // This shows us what the FBO sample sees
    _imageViewSample = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 100, 100)];
    [self.view addSubview:_imageViewSample];
    
    _viewVecPointer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 6, 6)];
    _viewVecPointer.backgroundColor = [UIColor redColor];
    _viewVecPointer.center = CGPointMake(60, 60);
    [self.view addSubview:_viewVecPointer];
    
    // Motion
    _motionManager = [[CMMotionManager alloc] init];
    [_motionManager startDeviceMotionUpdates];
    
    _textureFlame = NOCLoadGLTextureWithName(@"flame_red");
    
    // Flames
    _flames = [NSMutableArray arrayWithCapacity:MaxNumFlames];
    
    // Shaders
    NOCShaderProgram *paperShader = [[NOCShaderProgram alloc] initWithName:PaperShaderName];
    paperShader.attributes = @{@"position" : @(GLKVertexAttribPosition),
                               @"texCoord" : @(GLKVertexAttribTexCoord0)};
    paperShader.uniformNames = @[ UniformMVProjectionMatrix, UniformFlamePositions, UniformTexture ];

    NOCShaderProgram *textureShader = [[NOCShaderProgram alloc] initWithName:TextureShaderName];
    textureShader.attributes = @{@"position" : @(GLKVertexAttribPosition),
                                 @"texCoord" : @(GLKVertexAttribTexCoord0)};
    textureShader.uniformNames = @[ UniformMVProjectionMatrix, UniformTexture ];
    
    self.shaders = @{ PaperShaderName : paperShader, TextureShaderName : textureShader };
    
}

- (void)createPaperTexture
{
    
    // Create a perlin map which is the paper
    
    // float scalarX = 0.5 + (RAND_SCALAR * 0.5);
    // float scalarY = RAND_SCALAR * 0.5;
    float alpha = 1.0f; //map(scalarX, 0.0, 1.0, 0.5, 2.0);
    float beta = 0.02; //map(scalarY, 0.0, 1.0, 0.0, 0.25);
    int numOctaves = 4; //4 + (arc4random() % 3);
    UIImage *perlinMap = [UIImage perlinMapOfSize:CGSizeMake(_sizeView.width * 0.5, _sizeView.height * 0.5)
                                            alpha:alpha
                                             beta:beta
                                          octaves:numOctaves
                                           minVal:0
                                           maxVal:255];
    
    // NOTE: The default image format doesn't work as a GL texture
    // so I have to convert it first, otherwise I get:
    // GLKTextureLoaderErrorDomain error 12, "Image decoding failed"
    UIImage *img = [UIImage imageWithData:UIImagePNGRepresentation(perlinMap)];
    _texturePaper = NOCLoadGLTextureWithImage(img);
    
}

- (void)update
{
    GLKVector2 motionVector = [self motionVectorFromManager:_motionManager];
    motionVector = GLKVector2MultiplyScalar(motionVector, MotionLiftMultiplier); // Eyeball the desired lift
    
#if TARGET_IPHONE_SIMULATOR
    motionVector = GLKVector2Make(-0.0, 0.001);
#endif
    
    [self seekFuelForFlames];
    
    NSMutableArray *deadFlames = [NSMutableArray arrayWithCapacity:_flames.count];
    for(NOCFlame *flame in _flames){

        BOOL isDead = [flame isDead];
        
        if(!isDead){
            // Prune flames that are no longer in the scene
            float newX = flame.position.x;
            float newY = flame.position.y;
            if(newX < -1 ||
               newX > 1 ||
               newY < -1.0/_viewAspect ||
               newY > 1.0/_viewAspect ){
                isDead = YES;
            };
        }

        if(isDead){
            [deadFlames addObject:flame];
        }else{
            [flame stepWithLift:motionVector];
        }
        
    }
    
    for(NOCFlame *flame in deadFlames){
        [_flames removeObject:flame];
    }
    
}

- (void)seekFuelForFlames
{
    // Get the image while it's still bound
    [_fbo bind];
    
    float halfWidth = (_sizeView.width * 0.5);
    float halfHeight = (_sizeView.height * 0.5);
    
    // Look around the center point and find the brightest spot
    const static float RangeOfInspection = 0.125;
    int pxSampleSize = ceil(_sizeView.width * (RangeOfInspection * 0.5));
    // NOTE: Keep these dimensions an odd number so there is a "middle" pixel
    if(pxSampleSize % 2 == 0) pxSampleSize -= 1;
    
    float sampleWidth = pxSampleSize;
    float sampleHeight = pxSampleSize;
    float halfSampleWidth = (sampleWidth / 2);
    float halfSampleHeight = (sampleHeight / 2);
    int flameSampleX = halfSampleWidth + 1;
    int flameSampleY = halfSampleHeight + 1;
    NSInteger samplePixelCount = sampleWidth * sampleHeight;

    for(NOCFlame *f in _flames){
        
        GLKVector3 posFlame = f.position;
        
        // Convert flame loc to screen coords
        float pxX = halfWidth + (posFlame.x * halfWidth);
        float pxY = halfHeight + ((posFlame.y * -1 * _viewAspect) * halfHeight);
        
        float x = MIN(MAX(0, pxX - (sampleWidth*0.5)), _sizeView.width - (sampleWidth*0.5));
        float y = MIN(MAX(0, pxY - (sampleHeight*0.5)), _sizeView.height - (sampleHeight*0.5));
        
        CGRect sampleRect = CGRectMake(x, y, sampleWidth, sampleHeight);
        
        GLubyte buffer[samplePixelCount * 4];
        [_fbo pixelValuesInRect:sampleRect buffer:buffer];
        
        int degreesIncrement = 6; // Granularity of sweep. 628 is M_PI * 2 * 100: a full circle
        GLubyte brightestValue = 0;
        GLKVector3 vecBrightest = GLKVector3Zero;
        int numSamples=0;
        for(int i=0;i<628;i+=degreesIncrement){
            float rads = i*0.01;
            GLKVector2 vecSample = GLKVector2Make(cos(rads),
                                                  sin(rads));
            int lookAtX = flameSampleX + (vecSample.x * (halfSampleWidth-1));
            int lookAtY = flameSampleY + (vecSample.y * (halfSampleHeight-1));
            
            float pxIndex = lookAtY * sampleWidth + lookAtX;
            int rIdx = pxIndex*4+0;
            GLubyte r = buffer[rIdx];
            if(r > brightestValue){
                brightestValue = r;
                vecBrightest = GLKVector3Make(vecSample.x, // faster towards brighter
                                              vecSample.y,
                                              0);
            }
            numSamples++;
        }
        
        if(vecBrightest.x == 0 && vecBrightest.y == 0){
            [f kill];
            continue;
        }
        
        // How bright was the brightest point
        float scalarBrightestValue = (int)brightestValue / 255.0f;
        
        // The flame should move faster towards brighter paper
        GLKVector3 vectorBurn = GLKVector3Make(vecBrightest.x * (0.35 + scalarBrightestValue * 0.65),
                                               vecBrightest.y * (0.35 + scalarBrightestValue * 0.65) * -1,
                                               0);
        
        vectorBurn = GLKVector3MultiplyScalar(vectorBurn, FlameSpeed);
        f.velocity = vectorBurn;
        
        // If this is the most recent flame, we'll track its searching progress
        // on screen. It appears in the upper left corner.
        if(f == [_flames lastObject]){
            
            CGPoint sampleCenter = _imageViewSample.center;
            CGPoint pointerCenter = CGPointMake(sampleCenter.x + (vecBrightest.x*halfSampleWidth),
                                                sampleCenter.y + (vecBrightest.y*halfSampleHeight));
            
            _viewVecPointer.center = pointerCenter;
            
            UIImage *sampleImage = [_fbo imageAtRect:CGRectMake(x, y, sampleWidth, sampleHeight)];

            _imageViewSample.frame = CGRectMake(sampleCenter.x - halfSampleWidth,
                                                sampleCenter.y - halfSampleHeight,
                                                sampleWidth, sampleHeight);
            
            _imageViewSample.image = sampleImage;

        }
    }
}

- (void)renderPaperToFBO
{
    [_fbo bind];

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    NOCShaderProgram *paperShader = self.shaders[PaperShaderName];
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
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_screen3DBillboardVertexData);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &Square3DTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    if(_texturePaper && !_hasRenderedTexture){
        
        NOCShaderProgram *texShader = self.shaders[TextureShaderName];
        [texShader use];
        [texShader setMatrix:_projectionMatrix2D forUniform:UniformMVProjectionMatrix];

        glEnable(GL_TEXTURE_2D);
        glActiveTexture(0);
        glBindTexture(GL_TEXTURE_2D, _texturePaper.name);
        [texShader setInt:0 forUniform:UniformTexture];

        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_screen3DBillboardVertexData);
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &Square3DTexCoords);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glBindTexture(GL_TEXTURE_2D, 0);

        _hasRenderedTexture = YES;
    }

}

- (void)draw
{
    [self renderPaperToFBO];

    [(GLKView*)self.view bindDrawable];

    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    // Draw the FBO as a texture
    NOCShaderProgram *texShader = self.shaders[TextureShaderName];
    [texShader use];
    [texShader setMatrix:_projectionMatrix2D forUniform:UniformMVProjectionMatrix];
    [_fbo bindTexture:0];
    [texShader setInt:0 forUniform:UniformTexture];

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_screen3DBillboardVertexData);
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

            CGPoint posTouch = [t locationInView:self.view];

            float scalarX = posTouch.x / _sizeView.width;
            float scalarY = 1.0 - (posTouch.y / _sizeView.height);
            
            float glX = (scalarX * 2.0f) - 1.0f;
            float glY = (scalarY * (2.0f / _viewAspect)) - (1.0 / _viewAspect);
            
            // Add a new flame
            NOCFlame *flame = [[NOCFlame alloc] initWithPosition:GLKVector3Make(glX, glY, 0)
                                                    flameTexture:_textureFlame];
            flame.velocity = GLKVector3Zero;
            [_flames addObject:flame];

        }
        
    }
    
}

@end

//
//  NOCBeardMatrixViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/9/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCBeardMatrixViewController.h"
#import "NOCBeardVerts.h"
#import "NOCHair.h"

#define DRAW_BEARD_IN_GL    1

@interface NOCBeardMatrixViewController ()
{
    UIImageView *_imgViewBeard;
    NSMutableArray *_hairs;
}
@end

@implementation NOCBeardMatrixViewController

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

#if DRAW_BEARD_IN_GL

- (void)setup
{
    // Setup the shader
    NOCShaderProgram *shader = [[NOCShaderProgram alloc] initWithName:HairShaderName];

    shader.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                           @"color" : @(GLKVertexAttribColor) };

    shader.uniformNames = @[ UniformMVProjectionMatrix ];

    [self addShader:shader named:HairShaderName];
    
    // Create the hairs
    [self createBeard];
}

- (void)createBeard
{
    _hairs = [NSMutableArray arrayWithCapacity:NumHairsBeard0];
    
    float faceOffsetY = -0.2f;
    float faceOffsetX = 0;
    CGRect frameBeard = CGRectMake(-0.25 + faceOffsetX,
                                   0.5 + faceOffsetY,
                                   0.5, 0.5);
    
    for(int i=0;i<NumHairsBeard0;i++){

        float x = HairVertsBeard0[i*2+0];
        float y = HairVertsBeard0[i*2+1];
        x = frameBeard.origin.x + (x * frameBeard.size.width);
        y = frameBeard.origin.y + (y * frameBeard.size.height);
        
        GLKVector2 posAnchor = GLKVector2Make(x, y);
        NOCHair *hair = [[NOCHair alloc] initWithAnchor:posAnchor
                                           numParticles:0
                                               ofLength:0.1];
        hair.growthRate = 0.0005;
        hair.maxNumParticles = 8;

        [_hairs addObject:hair];
    }
}

- (void)update
{
    GLKVector2 gravity = GLKVector2Make(0, -0.05);
    float xOff = cos(self.frameCount * 0.05) * 0.01;
    
    for(NOCHair *h in _hairs)
    {
        GLKVector2 anchorPoint = h.anchor;
        anchorPoint.x += xOff;
        h.anchor = anchorPoint;
        [h applyForce:gravity];
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

#else

#pragma mark - Building the beard matrix

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIImage *imgMask0 = [UIImage imageNamed:@"beard_mask_0"];
    _imgViewBeard = [[UIImageView alloc] initWithImage:imgMask0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _imgViewBeard.center = CGPointMake(_sizeView.width * 0.5,
                                       _sizeView.height * 0.5);
    [self.view addSubview:_imgViewBeard];
    [self loadMatrix];
}

- (void)loadMatrix
{
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(_imgViewBeard.image.CGImage));
    const UInt8* data = CFDataGetBytePtr(pixelData);
    CGSize sizeBeard = _imgViewBeard.frame.size;

    int strideX = 8;
    int offsetX = -3;
    int strideY = 8;
    int offsetY = -3;
    int hairX = 0;
    NSMutableArray *outp = [NSMutableArray arrayWithCapacity:(sizeBeard.width * sizeBeard.height) / (strideX*strideY)];
    for(int x=0;x<sizeBeard.width;x+=1){
        hairX = 0;
        for(int y=0;y<sizeBeard.height;y+=1){
            if((offsetX+x) % strideX == 0 &&
               (offsetY+y) % strideY == 0){

                hairX++;

                // This gives it a staggered pattern
                float xOff = (hairX % 2) * ((float)strideY * 0.5);
                float yOff = 0;
                
                float pxX = CONSTRAIN(x + xOff, 0, sizeBeard.width-1);
                float pxY = CONSTRAIN(y + yOff, 0, sizeBeard.height-1);

                int pixelIdx = ((sizeBeard.width * pxY) + pxX) * 4;
                //UInt8 r = data[pixelIdx + 0];
                //UInt8 g = data[pixelIdx + 1];
                //UInt8 b = data[pixelIdx + 2];
                UInt8 a = data[pixelIdx + 3];
                if(a > 50){
                    
                    float scalarX = pxX / sizeBeard.width;
                    float scalarY = 1.0 - (pxY / sizeBeard.height);
                    [outp addObject:[NSString stringWithFormat:@"%f, %f,", scalarX, scalarY]];
                    // Add a dot
                    CALayer *l = [[CALayer alloc] init];
                    l.backgroundColor = [UIColor yellowColor].CGColor;
                    l.bounds = CGRectMake(0,0,4,4);
                    l.cornerRadius = 2;
                    l.position = CGPointMake(pxX,pxY);
                    [_imgViewBeard.layer addSublayer:l];
                }
            }
        }
    }
    NSLog(@"static int NumHairsBeard0 = %i;", outp.count);
    NSLog(@"\n%@", [outp componentsJoinedByString:@"\n"]);
    
}

#endif

@end

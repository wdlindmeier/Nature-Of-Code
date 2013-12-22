//
//  NOCTracerPhotoSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/4/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTracerPhotoSketchViewController.h"
#import "NOCPhotoTracer.h"
#import "NOCColorHelpers.h"

static NSString * ShaderNameTracers = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * ShaderNameTexture = @"Texture";
static NSString * UniformTexture = @"texture";

@implementation NOCTracerPhotoSketchViewController
{
    NSArray *_tracerGroups;
    int _numBatchTracers;
    int _numTracerGroups;
    int _generationFrame;
    int _numFramesPerGeneration;
    int _updateSpeed;
    CGRect _bounds;
    GLKVector2 _targetPosition;
    float _targetRadius;
    GLKTextureInfo *_texturePhoto;
    unsigned char *_rawPxData;
    CGSize _sizeImage;

    float _sampleWidth;
    PhotoSampleType _sampleType;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiPhotoTracers";
}

- (void)updateFromSliders
{
    int framesPerUpdate = self.sliderEvolutionRate.value;
    if(framesPerUpdate != _updateSpeed){
        _updateSpeed = framesPerUpdate;
        NSLog(@"_updateSpeed: %i", _updateSpeed);
    }
    
    float mutationRate = self.sliderMutationRate.value * 0.001;
    if(mutationRate != [NOCPhotoTracer mutationRate]){
        [NOCTracer setMutationRate:mutationRate];
        NSLog(@"Mutation rate: %f", [NOCTracer mutationRate]);
    }
    
    float sampleWidth = self.sliderSampleSize.value;
    if(_sampleWidth != sampleWidth){
        _sampleWidth = sampleWidth;
        NSLog(@"sampleWidth: %f", sampleWidth);
    }
    
    int sampleType = self.segmentedControlContrastMethod.selectedSegmentIndex;
    if(sampleType != _sampleType){
        _sampleType = sampleType;
        NSLog(@"sampleType: %i", sampleType);
    }

}

- (void)loadPixelData:(NSString *)imageName
{
    UIImage *imgFace = [UIImage imageNamed:imageName];
    CGImageRef image = imgFace.CGImage;
    _sizeImage = imgFace.size;
    NSUInteger width = _sizeImage.width;
    NSUInteger height = _sizeImage.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if(_rawPxData){
        free(_rawPxData);
    }
    _rawPxData = malloc(height * width * 4);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(_rawPxData,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGContextRelease(context);

}

#pragma mark - Setup

- (void)resize
{
    [super resize];
    float sceneWidth = 2.0f;
    float sceneHeight = 2.0f/_viewAspect;
    
    _bounds = CGRectMake(-1, -1 / _viewAspect,
                         sceneWidth, sceneHeight);
    
}

- (void)setup
{
    _rawPxData = NULL;
    _updateSpeed = 1;
    _numBatchTracers = 10;
    _numTracerGroups = 30;
    _generationFrame = 0;
    _numFramesPerGeneration = 200;
    
    [self loadPixelData:@"face"];
    
    _targetPosition = GLKVector2Make(0, -1);
    _targetRadius = 0.1;
        
    NOCShaderProgram *shaderTracers = [[NOCShaderProgram alloc] initWithName:ShaderNameTracers];
    shaderTracers.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                  @"color" : @(GLKVertexAttribColor), };
    shaderTracers.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shaderTracers named:ShaderNameTracers];
    
    NOCShaderProgram *textureShader = [[NOCShaderProgram alloc] initWithName:ShaderNameTexture];
    textureShader.attributes = @{@"position" : @(GLKVertexAttribPosition),
                                 @"texCoord" : @(GLKVertexAttribTexCoord0)};
    textureShader.uniformNames = @[ UniformMVProjectionMatrix, UniformTexture ];
    [self addShader:textureShader named:ShaderNameTexture];
    
    _texturePhoto = NOCLoadGLTextureWithName(@"face");
    
    [self setupInitialTracers];
}

- (void)setupInitialTracers
{
    _generationFrame = 0;
    
    NSMutableArray *tracerGroups = [NSMutableArray arrayWithCapacity:_numTracerGroups];
    
    for(int i=0;i<_numTracerGroups;i++){
        
        GLKVector2 startingPos = GLKVector2Make(RAND_SCALAR * 2.0 - 1.0, RAND_SCALAR * 2.0 - 1.0);
        
        NSMutableArray *tracers = [NSMutableArray arrayWithCapacity:_numBatchTracers];
        for(int j=0;j<_numBatchTracers;j++){
            NOCPhotoTracer *tracer = [self randomTracer];
            // This should be in the DNA
            
            tracer.position = startingPos;
            
            [tracers addObject:tracer];
        }
        [tracerGroups addObject:[NSArray arrayWithArray:tracers]];
    }
    _tracerGroups = [NSArray arrayWithArray:tracerGroups];
    
}

- (NOCPhotoTracer *)randomTracer
{
    NOCPhotoTracer *randTracer = [[NOCPhotoTracer alloc] initWithLifeSpan:_numFramesPerGeneration];
    return randTracer;
}

#pragma mark - Breeding / Selection

- (void)selectNextGeneration
{
    _generationFrame = 0;
    
    NSMutableArray *tracerGroups = [NSMutableArray arrayWithCapacity:_numTracerGroups];
    for(NSArray *tracers in _tracerGroups){
        
        // Find the max fitness so we can normalize
        float maxFitness = 0;
        float minFitness = 0;
        int i=0;
        for(NOCPhotoTracer *t in tracers){
            float fitness = [t evaluateFitness];
            if(i == 0 || fitness > maxFitness){
                maxFitness = fitness;
            }
            if(i == 0 || fitness < minFitness){
                minFitness = fitness;
            }
            i++;
        }
        float fitnessRange = maxFitness - minFitness;
        
        int bucketSize = _numBatchTracers * 5; // large number so small fish still have a chance
        NSMutableArray *genePool = [NSMutableArray arrayWithCapacity:bucketSize];
        
        for(NOCPhotoTracer *t in tracers){
            // Normalize all of the fitnesses between 0 and 1
            float normalFitness = (t.fitness-minFitness) / fitnessRange;
            int numInPool = ceil(bucketSize * normalFitness);
            for(int i=0;i<numInPool;i++){
                [genePool addObject:t];
            }
        }
        if(genePool.count == 0){
            genePool = [NSArray arrayWithArray:tracers];
        }
        
        NSMutableArray *newTracers = [NSMutableArray arrayWithCapacity:_numBatchTracers];
        
        for(int i=0;i<_numBatchTracers;i++){
            
            int randIdxA = arc4random() % genePool.count;
            int randIdxB = arc4random() % genePool.count;
            
            NOCPhotoTracer *parentA = genePool[randIdxA];
            NOCPhotoTracer *parentB = genePool[randIdxB];
            
            NOCPhotoTracer *nextGen = (NOCPhotoTracer *)[parentA crossover:parentB];
            nextGen.position = [parentA positionAtFrame:0];
            
            // TODO: Put this in the genetic information
            // nextGen.position = _startingPosition;
            
            if(!nextGen){
                NSLog(@"ERROR: Couldn't cross over next gen");
            }else{
                [newTracers addObject:nextGen];
            }
            
        }
        
        [tracerGroups addObject:[NSArray arrayWithArray:newTracers]];
        
    }
    
    _tracerGroups = [NSArray arrayWithArray:tracerGroups];
    
}

- (void)update
{
    [super update];
    [self updateFromSliders];
    for(int i=0;i<_updateSpeed;i++){
        if(![self stepFrame]){
            // Force render if stepFrame returns NO
            break;
        }
    }
}

- (BOOL)stepFrame
{
    _generationFrame++;
    
    if(_generationFrame >= _numFramesPerGeneration){
        
        [self selectNextGeneration];
        self.labelGeneration.text = [NSString stringWithFormat:@"Generation: %i",
                                     [_tracerGroups[0][0] generation]];
        
    }else if(_generationFrame == _numFramesPerGeneration-1){
        
        return NO;
        
    }
    
    float halfWidth = _sizeImage.width * 0.5;
    float halfHeight = _sizeImage.height * 0.5;
    
    for(NSArray *tracers in _tracerGroups){
        for(NOCPhotoTracer *tracer in tracers)
        {
            [tracer stepInRect:_bounds];
            
            if(!tracer.didHitObstruction){
                
                if(!_rawPxData){
                    NSLog(@"ERROR: Could not find _rawPxData");
                    break;
                }
                // TODO: Wrap this up in a function
                GLKVector2 pos = tracer.position;
                GLKVector2 prevPos = [tracer previousPosition];
                
                tracer.sampleOffset = _sampleWidth;
                tracer.sampleType = _sampleType;
                
                // Account for the segment angle
                GLKVector2 perpVec = NOCGLKVector2Normal(GLKVector2Subtract(pos, prevPos));
                
                float pX1 = pos.x - (perpVec.x * tracer.sampleOffset * 0.5);
                float pX2 = pos.x + (perpVec.x * tracer.sampleOffset * 0.5);
                
                float pY1 = pos.y - (perpVec.y * tracer.sampleOffset * 0.5);
                float pY2 = pos.y + (perpVec.y * tracer.sampleOffset * 0.5);

                GLKVector2 pxPositionA = GLKVector2Make(halfWidth + pX1 * halfWidth,
                                                        halfHeight + pY1 * halfWidth);
                GLKVector2 pxPositionB = GLKVector2Make(halfWidth + pX2 * halfWidth,
                                                        halfHeight + pY2 * halfWidth);
                
                // TODO: Do a sanity check on these numbers
                int pxIdx1 = pxPositionA.x + (pxPositionA.y * _sizeImage.width);
                int pxIdx2 = pxPositionB.x + (pxPositionB.y * _sizeImage.width);
                
                RGBcolor colorA;
                RGBcolor colorB;
                
                colorA.r = (float)_rawPxData[pxIdx1*4+0] / 255.0;
                colorA.g = (float)_rawPxData[pxIdx1*4+1] / 255.0;
                colorA.b = (float)_rawPxData[pxIdx1*4+2] / 255.0;
                
                HSVcolor hsv1 = HSVfromRGB(colorA);

                colorB.r = (float)_rawPxData[pxIdx2*4+0] / 255.0;
                colorB.g = (float)_rawPxData[pxIdx2*4+1] / 255.0;
                colorB.b = (float)_rawPxData[pxIdx2*4+2] / 255.0;
                
                HSVcolor hsv2 = HSVfromRGB(colorB);
                
                float hContrast = fabs(hsv1.hue - hsv2.hue) / 360.0; // 0..1
                float sContrast = fabs(hsv1.sat - hsv2.sat); // 0..1
                float vContrast = fabs(hsv1.val - hsv2.val); // 0..1
                
                // For now, lets use value contrast
                [tracer updateFitnessWithContrastHue:hContrast
                                                 sat:sContrast
                                                 val:vContrast];
                
            }
        }
    }
    
    return YES;
}


#pragma mark - Drawing

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)renderPhotoTexture
{
    NOCShaderProgram *shaderTexture = [self shaderNamed:ShaderNameTexture];
    [shaderTexture use];
    [shaderTexture setMatrix4:_projectionMatrix2D
                   forUniform:UniformMVProjectionMatrix];
    // Bind the texture
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, _texturePhoto.name);
    [shaderTexture setInt:0 forUniform:UniformTexture];
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_screen3DBillboardVertexData);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &kSquare3DTexCoords);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)renderTracers
{
    BOOL drawFittest = NO;//self.switchDrawFittestLines.on;
    BOOL renderColored = NO;//self.switchRenderColoredHistory.on;
    
    for(NSArray *tracers in _tracerGroups){

        NOCPhotoTracer *fittestTracer = tracers[0];
    
        for(NOCPhotoTracer *tracer in tracers){
            
            if(drawFittest){
                
                // Constantly re-evaluate
                [tracer evaluateFitness];
                
                if(tracer.fitness > fittestTracer.fitness){
                    fittestTracer = tracer;
                }
                
            }else{
                
                [tracer render:renderColored];
                
            }
        }
        
        if(drawFittest){
            
            [fittestTracer render:renderColored];
            
        }
    }
}

- (void)draw
{
    [(GLKView*)self.view bindDrawable];
    
    [self clear];
    
    [self renderPhotoTexture];
    
    NOCShaderProgram *shaderTracers = [self shaderNamed:ShaderNameTracers];
    [shaderTracers use];
    [shaderTracers setMatrix4:_projectionMatrix2D
                   forUniform:UniformMVProjectionMatrix];

    // Draw the tracers
    [self renderTracers];

}

- (void)teardown
{
    [super teardown];
    if(_rawPxData) free(_rawPxData);
}

#pragma mark - Touch

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    for(UITouch *t in touches){
        if(t.tapCount > 0){
            [self setupInitialTracers];
        }
    }
}

@end

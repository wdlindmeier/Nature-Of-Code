//
//  NOCTracersSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTracersSketchViewController.h"
#import "NOCTracer3D.h"

@interface NOCTracersSketchViewController ()
{
    NOCBox3D _moverBounds;
    NSArray *_tracerGroups;
    GLKVector3 _vecNavigation;
    
    int _numBatchTracers;
    int _numTracersGroups;
    int _generationFrame;
    int _numFramesPerGeneration;
    int _updateSpeed;
    
    GLKVector3 _surfBottomWall[4];
    GLKVector3 _surfTopWall[4];
    GLKVector3 _surfBackWall[4];
    GLKVector3 _surfFrontWall[4];
    GLKVector3 _surfRightWall[4];
    GLKVector3 _surfLeftWall[4];
    
    // Circle shape
    float _circleRadius;
}
@end

static NSString * ShaderNameTracers = @"Being";
static NSString * ShaderNameSceneBox = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformNormalMatrix = @"normalMatrix";
static NSString * UniformColor = @"color";

@implementation NOCTracersSketchViewController

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiTracers";
}

- (void)updateFromSliders
{
    int framesPerUpdate = self.sliderEvolutionRate.value;
    if(framesPerUpdate != _updateSpeed){
        _updateSpeed = framesPerUpdate;
        NSLog(@"_updateSpeed: %i", _updateSpeed);
    }
    
    float mutationRate = self.sliderMutationRate.value * 0.001;
    if(mutationRate != [NOCTracer3D mutationRate]){
        [NOCTracer3D setMutationRate:mutationRate];
        NSLog(@"Mutation rate: %f", [NOCTracer3D mutationRate]);
    }
    
}

#pragma mark - Setup

- (void)setup
{
    _circleRadius = 0.85f;
    
    _updateSpeed = 1;
    _numBatchTracers = 20;
    _numTracersGroups = 15;
    _generationFrame = 0;
    _numFramesPerGeneration = 500;
    
    NOCShaderProgram *shaderSceneBox = [[NOCShaderProgram alloc] initWithName:ShaderNameSceneBox];
    shaderSceneBox.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                   @"color" : @(GLKVertexAttribColor), };
    shaderSceneBox.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shaderSceneBox named:ShaderNameSceneBox];
    
    NOCShaderProgram *shaderBeings = [[NOCShaderProgram alloc] initWithName:ShaderNameTracers];
    shaderBeings.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                 @"normal" : @(GLKVertexAttribNormal)};//,
    
    shaderBeings.uniformNames = @[ UniformMVProjectionMatrix, UniformNormalMatrix, UniformColor ];
    [self addShader:shaderBeings named:ShaderNameTracers];
    
    self.isArcballEnabled = NO;
    self.isGestureNavigationEnabled = YES;
    
    [self setupInitialTracers];
    
    glEnable(GL_DEPTH_TEST);
    
}

- (void)setupInitialTracers
{
    _generationFrame = 0;
    
    NSMutableArray *tracerGroups = [NSMutableArray arrayWithCapacity:_numTracersGroups];
    
    for(int i=0;i<_numTracersGroups;i++){
        
        NSMutableArray *tracers = [NSMutableArray arrayWithCapacity:_numBatchTracers];
        
        for(int j=0;j<_numBatchTracers;j++){
            [tracers addObject:[self randomTracer]];
        }
        
        [tracerGroups addObject:[NSArray arrayWithArray:tracers]];
    }
    
    _tracerGroups = [NSArray arrayWithArray:tracerGroups];
    
}

- (NOCTracer3D *)randomTracer
{
    NOCTracer3D *randTracer = [[NOCTracer3D alloc] initWithLifeSpan:_numFramesPerGeneration];
    [randTracer expressDNA];
    return randTracer;
}

- (void)setupWallSurfaces
{
    float height = 1.0 / _viewAspect;
    
    _surfLeftWall[0] = GLKVector3Make(-1, -1*height, -1);
    _surfLeftWall[1] = GLKVector3Make(-1, 1*height, -1);
    _surfLeftWall[2] = GLKVector3Make(-1, 1*height, 1);
    _surfLeftWall[3] = GLKVector3Make(-1, -1*height, 1);
    
    _surfRightWall[0] = GLKVector3Make(1, -1*height, -1);
    _surfRightWall[1] = GLKVector3Make(1, 1*height, -1);
    _surfRightWall[2] = GLKVector3Make(1, 1*height, 1);
    _surfRightWall[3] = GLKVector3Make(1, -1*height, 1);
    
    _surfFrontWall[0] = GLKVector3Make(-1, -1*height, -1);
    _surfFrontWall[1] = GLKVector3Make(-1, 1*height, -1);
    _surfFrontWall[2] = GLKVector3Make(1, 1*height, -1);
    _surfFrontWall[3] = GLKVector3Make(1, -1*height, -1);
    
    _surfBackWall[0] = GLKVector3Make(-1, -1*height, 1);
    _surfBackWall[1] = GLKVector3Make(-1, 1*height, 1);
    _surfBackWall[2] = GLKVector3Make(1, 1*height, 1);
    _surfBackWall[3] = GLKVector3Make(1, -1*height, 1);
    
    _surfTopWall[0] = GLKVector3Make(-1, 1*height, -1);
    _surfTopWall[1] = GLKVector3Make(1, 1*height, -1);
    _surfTopWall[2] = GLKVector3Make(1, 1*height, 1);
    _surfTopWall[3] = GLKVector3Make(-1, 1*height, 1);
    
    _surfBottomWall[0] = GLKVector3Make(-1, -1*height, -1);
    _surfBottomWall[1] = GLKVector3Make(1, -1*height, -1);
    _surfBottomWall[2] = GLKVector3Make(1, -1*height, 1);
    _surfBottomWall[3] = GLKVector3Make(-1, -1*height, 1);
}

#pragma mark - Loop

- (void)resize
{
    [super resize];
    [self setupWallSurfaces];
    
    float sceneWidth = 2.0f;
    float sceneHeight = 2.0f/_viewAspect;
    float sceneDepth = 2.0f;
    
    _moverBounds = NOCBox3DMake(-1,
                                -1 / _viewAspect,
                                -1,
                                sceneWidth,
                                sceneHeight,
                                sceneDepth);
}

- (void)selectNextGeneration
{
    _generationFrame = 0;
    
    NSMutableArray *newGroups = [NSMutableArray arrayWithCapacity:_numTracersGroups];
    
    // Find the max fitness so we can normalize
    for(NSArray *tracers in _tracerGroups){
        
        // Find the max fitness so we can normalize
        float maxFitness = ((NOCTracer3D *)tracers[0]).fitness;
        float minFitness = maxFitness;
        for(NOCTracer3D *t in tracers){
            float fitness = [t overallFitnessForCircleOfRadius:_circleRadius];
            if(fitness > maxFitness){
                maxFitness = fitness;
            }
            if(fitness < minFitness){
                minFitness = fitness;
            }
        }
        float fitnessRange = maxFitness - minFitness;
        
        int bucketSize = _numBatchTracers * 5; // large number so small fish still have a chance
        NSMutableArray *genePool = [NSMutableArray arrayWithCapacity:bucketSize];
        
        for(NOCTracer3D *t in tracers){
            
            float fitness = [t overallFitnessForCircleOfRadius:_circleRadius];
            
            // Normalize all of the fitnesses between 0 and 1
            float normalFitness = (fitness-minFitness) / fitnessRange;
            int numInPool = ceil(bucketSize * normalFitness);
            for(int i=0;i<numInPool;i++){
                [genePool addObject:t];
            }
        }
        
        NSMutableArray *newTracers = [NSMutableArray arrayWithCapacity:_numBatchTracers];
        
        for(int i=0;i<_numBatchTracers;i++){
            
            int randIdxA = arc4random() % genePool.count;
            int randIdxB = arc4random() % genePool.count;
            
            NOCTracer3D *parentA = genePool[randIdxA];
            NOCTracer3D *parentB = genePool[randIdxB];
            
            NOCTracer3D *nextGen = (NOCTracer3D *)[parentA crossover:parentB];
            
            if(!nextGen){
                NSLog(@"ERROR: Couldn't cross over next gen");
            }else{
                [newTracers addObject:nextGen];
            }
        }
        
        [newGroups addObject:[NSArray arrayWithArray:newTracers]];
        
        /*
        NSArray *sortedTracers = [tracers sortedArrayUsingComparator:^NSComparisonResult(NOCTracer *f1, NOCTracer *f2) {
            float fitness1 = [f1 overallFitnessForCircleOfRadius:_circleRadius];
            float fitness2 = [f2 overallFitnessForCircleOfRadius:_circleRadius];
            if(fitness1 > fitness2){
                return  NSOrderedAscending;
            }else{
                return  NSOrderedDescending;
            }
        }];
        
        NSArray *genePool = [sortedTracers subarrayWithRange:NSMakeRange(0, 2)];
        
        NSMutableArray *newTracers = [NSMutableArray arrayWithCapacity:_numBatchTracers];
        
        for(int i=0;i<_numBatchTracers;i++){
            
            NOCTracer *parentA = genePool[0];
            NOCTracer *parentB = genePool[1];
            
            NOCTracer *nextGen = (NOCTracer *)[parentA crossover:parentB];
            
            if(!nextGen){
                NSLog(@"ERROR: Couldn't cross over next gen");
            }else{
                [newTracers addObject:nextGen];
            }
        }
        
        [newGroups addObject:[NSArray arrayWithArray:newTracers]];
        */
        
    }
    
    _tracerGroups = [NSArray arrayWithArray:newGroups];
    
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
    
    for(NSArray *tracers in _tracerGroups){
        
        for(NOCTracer3D *tracer in tracers){
            [tracer step];
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

- (void)draw
{
    [self clear];
    
    GLKMatrix4 matCam = GLKMatrix4MakeTranslation(0, 0, self.cameraDepth);
    GLKMatrix4 matScene = GLKMatrix4Multiply(_projectionMatrix3D, matCam);
    
    matScene = [self rotateMatrixWithArcBall:matScene];
    
    // Draw the scene box
    NOCShaderProgram *shaderScene = [self shaderNamed:ShaderNameSceneBox];
    [shaderScene use];
    [shaderScene setMatrix4:matScene
                 forUniform:UniformMVProjectionMatrix];
    [self drawWalls];
    
    BOOL drawFittest = self.switchDrawFittestLines.on;
    BOOL renderColored = self.switchRenderColoredHistory.on;
    
    //glEnable (GL_BLEND);
    //glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    for(NSArray *tracers in _tracerGroups){
        
        NOCTracer3D *fittestTracer = tracers[0];
        
        for(NOCTracer3D *tracer in tracers){
            
            if(drawFittest){
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
    //glDisable(GL_BLEND);
    
}

- (void)drawWalls
{
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    for(int i=0;i<6;i++){
        
        GLKVector3 *wallVecs;
        WallSide wallSide = i+1;
        switch (wallSide) {
            case WallSideNone:
                break;
            case WallSideBack:
                wallVecs = _surfBackWall;
                break;
            case WallSideFront:
                wallVecs = _surfFrontWall;
                break;
            case WallSideLeft:
                wallVecs = _surfLeftWall;
                break;
            case WallSideRight:
                wallVecs = _surfRightWall;
                break;
            case WallSideTop:
                wallVecs = _surfTopWall;
                break;
            case WallSideBottom:
                wallVecs = _surfBottomWall;
                break;
        }
        
        GLfloat wallColor[5*4];
        GLfloat wallVerts[5*3];
        
        for(int j=0;j<5;j++){
            
            wallColor[j*4+0] = 1.0f;
            wallColor[j*4+1] = 1.0f;
            wallColor[j*4+2] = 1.0f;
            wallColor[j*4+3] = 1.0f;
            
            GLKVector3 corner = wallVecs[j%4];
            wallVerts[j*3+0] = corner.x;
            wallVerts[j*3+1] = corner.y;
            wallVerts[j*3+2] = corner.z;
            
        }
        
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &wallVerts);
        glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &wallColor);
        glDrawArrays(GL_LINE_LOOP, 0, 5);
        
    }
}

- (void)teardown
{
    [super teardown];
}

#pragma mark - Touch

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    for(UITouch *t in touches){
        if(t.tapCount > 1){
            // Double tap resets the world
            [self setupInitialTracers];
        }
    }
}

@end

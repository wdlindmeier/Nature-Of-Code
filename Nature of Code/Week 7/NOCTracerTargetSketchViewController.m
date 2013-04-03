//
//  NOCTracerTargetSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/3/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTracerTargetSketchViewController.h"
#import "NOCTracer2D.h"

@interface NOCTracerTargetSketchViewController ()

@end

static NSString * ShaderNameTracers = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";

@implementation NOCTracerTargetSketchViewController
{
    NSArray *_tracers;
    int _numBatchTracers;
    int _generationFrame;
    int _numFramesPerGeneration;
    int _updateSpeed;
    CGRect _bounds;
    GLKVector2 _targetPosition;
    GLKVector2 _startingPosition;
    float _targetRadius;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.switchDrawFittestLines.on = NO;
}

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
    if(mutationRate != [NOCTracer2D mutationRate]){
        [NOCTracer setMutationRate:mutationRate];
        NSLog(@"Mutation rate: %f", [NOCTracer mutationRate]);
    }
    
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
    _updateSpeed = 1;
    _numBatchTracers = 50;
    _generationFrame = 0;
    _numFramesPerGeneration = 200;
    
    _startingPosition= GLKVector2Make(0, 1);
    _targetPosition = GLKVector2Make(0, -1);
    _targetRadius = 0.1;
    
    NOCShaderProgram *shaderTracers = [[NOCShaderProgram alloc] initWithName:ShaderNameTracers];
    shaderTracers.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                  @"color" : @(GLKVertexAttribColor), };
    shaderTracers.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shaderTracers named:ShaderNameTracers];
    
    [self setupInitialTracers];
}

- (void)setupInitialTracers
{
    _generationFrame = 0;
    
    NSMutableArray *tracers = [NSMutableArray arrayWithCapacity:_numBatchTracers];
    
    for(int j=0;j<_numBatchTracers;j++){
        NOCTracer2D *tracer = [self randomTracer];
        tracer.position = _startingPosition;        
        [tracers addObject:tracer];
    }
    
    _tracers = [NSArray arrayWithArray:tracers];
    
}

- (NOCTracer2D *)randomTracer
{
    NOCTracer2D *randTracer = [[NOCTracer2D alloc] initWithLifeSpan:_numFramesPerGeneration];
    return randTracer;
}

#pragma mark - Breeding / Selection

- (void)selectNextGeneration
{
    _generationFrame = 0;
    
    // Find the max fitness so we can normalize
    float maxFitness = 0;
    float minFitness = 0;
    int i=0;
    for(NOCTracer2D *t in _tracers){
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
    
    for(NOCTracer2D *t in _tracers){
        // Normalize all of the fitnesses between 0 and 1
        float normalFitness = (t.fitness-minFitness) / fitnessRange;
        int numInPool = ceil(bucketSize * normalFitness);
        for(int i=0;i<numInPool;i++){
            [genePool addObject:t];
        }
    }
    
    NSMutableArray *newTracers = [NSMutableArray arrayWithCapacity:_numBatchTracers];
    
    for(int i=0;i<_numBatchTracers;i++){
        
        int randIdxA = arc4random() % genePool.count;
        int randIdxB = arc4random() % genePool.count;
        
        NOCTracer2D *parentA = genePool[randIdxA];
        NOCTracer2D *parentB = genePool[randIdxB];
        
        NOCTracer2D *nextGen = (NOCTracer2D *)[parentA crossover:parentB];
        
        // NOTE: Perhaps we should inherit the starting position
        nextGen.position = _startingPosition;
        
        if(!nextGen){
            NSLog(@"ERROR: Couldn't cross over next gen");
        }else{
            [newTracers addObject:nextGen];
        }
    }
    
    _tracers = [NSArray arrayWithArray:newTracers];
    
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
                                     [_tracers[0] generation]];
        
    }else if(_generationFrame == _numFramesPerGeneration-1){
        
        return NO;
        
    }

    for(NOCTracer2D *tracer in _tracers)
    {
        [tracer stepInRect:_bounds];
        [tracer checkTarget:_targetPosition
                     radius:_targetRadius];
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

    NOCShaderProgram *shaderTracers = [self shaderNamed:ShaderNameTracers];
    [shaderTracers use];
    [shaderTracers setMatrix4:_projectionMatrix2D
                   forUniform:UniformMVProjectionMatrix];
    
    // Draw the target

    [self renderTarget];

    // Draw the tracers

    BOOL drawFittest = self.switchDrawFittestLines.on;
    BOOL renderColored = self.switchRenderColoredHistory.on;

    NOCTracer2D *fittestTracer = _tracers[0];
        
    for(NOCTracer2D *tracer in _tracers){
        
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

// Ported from Cinder drawSolidCircle
- (void)renderTarget
{
    int numSegments = 32;

    // automatically determine the number of segments from the circumference
    if( numSegments <= 0 ) {
        numSegments = floor( _targetRadius * M_PI * 2 );
    }
    if( numSegments < 2 ) numSegments = 2;
    
    // TODO: Cache this
    GLfloat verts[(numSegments+2)*2];
    GLfloat colors[(numSegments+2)*4];
    
    verts[0] = _targetPosition.x;
    verts[1] = _targetPosition.y;
    
    colors[0] = 0;
    colors[1] = 1;
    colors[2] = 1;
    colors[3] = 1;
    
    for( int s = 0; s <= numSegments; s++ ) {
        float t = s / (float)numSegments * 2.0f * 3.14159f;
        verts[(s+1)*2+0] = _targetPosition.x + cos( t ) * _targetRadius;
        verts[(s+1)*2+1] = _targetPosition.y + sin( t ) * _targetRadius;
        
        colors[(s+1)*4+0] = 0;
        colors[(s+1)*4+1] = 1;
        colors[(s+1)*4+2] = 1;
        colors[(s+1)*4+3] = 1;
    }
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &verts);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &colors);

    glDrawArrays( GL_TRIANGLE_FAN, 0, numSegments + 2 );

}


#pragma mark - Touch

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches)
    {
        if(t.tapCount > 1){
            [self setupInitialTracers];
        }
    }
}

@end

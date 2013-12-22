//
//  NOCTracerTargetSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/3/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTracerTargetSketchViewController.h"
#import "NOCTracer2D.h"
#import "NOCFrameBuffer.h"

@interface NOCTracerTargetSketchViewController ()

@end

static NSString * ShaderNameTracers = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * ShaderNameTexture = @"Texture";
static NSString * UniformTexture = @"texture";

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
    BOOL _didReachTarget;
    
    GLKTextureInfo *_textureTarget;
    
    GLKMatrix4 _projectionMatrixFBO;
    NOCFrameBuffer *_fboTouches;
    NSMutableDictionary *_activeTouches;
    BOOL _hasClearedFBO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.switchDrawFittestLines.on = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(!_fboTouches){
        _hasClearedFBO = NO;
        _fboTouches = [[NOCFrameBuffer alloc] initWithPixelWidth:_sizeView.width
                                                     pixelHeight:_sizeView.height];
    }
    
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
    
    _projectionMatrixFBO = GLKMatrix4Scale(_projectionMatrix2D, 1, -1, 1);
    
}

- (void)setup
{
    _didReachTarget = NO;
    _updateSpeed = 1;
    _numBatchTracers = 50;
    _generationFrame = 0;
    _numFramesPerGeneration = 200;
    
    _startingPosition= GLKVector2Make(0, 1);
    _targetPosition = GLKVector2Make(0, -1);
    _targetRadius = 0.1;
    
    _activeTouches = [NSMutableDictionary dictionaryWithCapacity:10];
    
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
    
    _textureTarget = NOCLoadGLTextureWithName(@"target");
    
    [self setupInitialTracers];
}

- (void)setupInitialTracers
{
    _generationFrame = 0;
    _hasClearedFBO = NO;
    
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
    _didReachTarget = NO;
    
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
    
    [_fboTouches bind];

    float halfWidth = _sizeView.width * 0.5;
    float halfHeight = _sizeView.height * 0.5;

    for(NOCTracer2D *tracer in _tracers)
    {
        [tracer stepInRect:_bounds];
        [tracer checkTarget:_targetPosition
                     radius:_targetRadius];
        
        if(tracer.didHitTarget){
            
            _didReachTarget = YES;
            
        }else if(!tracer.didHitObstruction && _hasClearedFBO){
            
            // Checking against the obstructions
            GLKVector2 pxPosition = GLKVector2Make(halfWidth + tracer.position.x * halfWidth,
                                                   halfHeight + tracer.position.y * halfWidth);
            
            CGRect pxRect = CGRectMake(pxPosition.x, pxPosition.y, 1, 1);
            
            GLubyte buffer[4];
            
            [_fboTouches pixelValuesInRect:pxRect
                                    buffer:buffer];
            
            if(buffer[0] > 250 && buffer[1] > 250){
                
                tracer.didHitObstruction = YES;
                
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

- (void)renderTouchTexture
{
    NOCShaderProgram *shaderTexture = [self shaderNamed:ShaderNameTexture];
    [shaderTexture use];
    [shaderTexture setMatrix4:_projectionMatrixFBO
                   forUniform:UniformMVProjectionMatrix];
    [_fboTouches bindTexture:0];
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

- (void)draw
{
    [(GLKView*)self.view bindDrawable];

    [self clear];

    [self renderTouchTexture];
    
    // Draw the target
    [self renderTarget];
    
    NOCShaderProgram *shaderTracers = [self shaderNamed:ShaderNameTracers];
    [shaderTracers use];
    [shaderTracers setMatrix4:_projectionMatrix2D
                   forUniform:UniformMVProjectionMatrix];
    
    // Draw the active touches
    // Do this underneath so it's on the same level as the touches

    BOOL renderTouchesToFBO = NO;
    
    if(_activeTouches.count > 0){
        [self renderTouches:NO];
        renderTouchesToFBO = YES;
    }
    
    // Draw the tracers
    [self renderTracers];
        
    // Render the inactive touches to the buffer

    if(!_hasClearedFBO || renderTouchesToFBO){
        
        [_fboTouches bind];

        [shaderTracers use];
    
        if(!_hasClearedFBO){
            [self clear];
            _hasClearedFBO = YES;
        }
    
        if(renderTouchesToFBO){
            [self renderTouches:YES];
        }
        
    }    
}

- (void)renderTouches:(BOOL)pruneInactive
{
    if(_activeTouches.count > 0){
     
        NSMutableArray *deadTouches = [NSMutableArray arrayWithCapacity:_activeTouches.count];
        CGRect frame = self.view.frame;

        for(NSString *touchID in _activeTouches){
            
            NSDictionary *tInfo = _activeTouches[touchID];
            BOOL isActive = [tInfo[@"isActive"] boolValue];
            
            if(!isActive){
                
                [deadTouches addObject:touchID];
                
            }

            // Render
            NSArray *touchPoints = tInfo[@"points"];
            int numTouchPoints = touchPoints.count;
            int numVerts = numTouchPoints * 2;
            CGFloat verts[numVerts * 2];
            CGFloat color[numVerts * 4];
            
            int i=0;
            
            GLKVector2 prevPoint;
            if(touchPoints.count > 1){
                
                // Use the second vert for the first angle
                NSValue *valFirstPoint = touchPoints[0];
                NSValue *valNextPoint = touchPoints[1];
                CGPoint pos0 = [valFirstPoint CGPointValue];
                CGPoint pos1 = [valNextPoint CGPointValue];
                GLKVector2 point0 = NOCGLPositionFromCGPointInRect(pos0, frame);
                GLKVector2 point1 = NOCGLPositionFromCGPointInRect(pos1, frame);
                point0.y *= -1;
                point1.y *= -1;
                GLKVector2 delta = GLKVector2Subtract(point1, point0);
                prevPoint = GLKVector2Subtract(point0, delta);
                
            }else{
                
                NSValue *valNextPoint = touchPoints[0];
                CGPoint pos = [valNextPoint CGPointValue];
                prevPoint = NOCGLPositionFromCGPointInRect(pos, frame);
                prevPoint.y *= -1;
                
            }

            for(NSValue *v in touchPoints){
                
                CGPoint pos = [v CGPointValue];
                
                // just draw a line for the moment
                GLKVector2 posTouch = NOCGLPositionFromCGPointInRect(pos, frame);
                posTouch.y *= -1;

                float dist = GLKVector2Distance(prevPoint, posTouch);
                float segmentWidth = CONSTRAIN(dist, 0.03, 0.06);
                
                // Account for the segment angle
                GLKVector2 perpVec = NOCGLKVector2Normal(GLKVector2Subtract(posTouch, prevPoint));
                prevPoint = posTouch;

                float pX1 = posTouch.x - (perpVec.x * segmentWidth * 0.5);
                float pX2 = posTouch.x + (perpVec.x * segmentWidth * 0.5);
                
                float pY1 = posTouch.y - (perpVec.y * segmentWidth * 0.5);
                float pY2 = posTouch.y + (perpVec.y * segmentWidth * 0.5);
                
                verts[i*4+0] = pX1;
                verts[i*4+1] = pY1;                
                verts[i*4+2] = pX2;
                verts[i*4+3] = pY2;
                
                color[i*8+0] = 1.0;
                color[i*8+1] = 1.0;
                color[i*8+2] = 0.0;
                color[i*8+3] = 1.0;
                color[i*8+4] = 1.0;
                color[i*8+5] = 1.0;
                color[i*8+6] = 0.0;
                color[i*8+7] = 1.0;
                
                i++;
            }
            
            glEnableVertexAttribArray(GLKVertexAttribPosition);
            glEnableVertexAttribArray(GLKVertexAttribColor);
            
            glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &verts);
            glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &color);
            
            glDrawArrays( GL_TRIANGLE_STRIP, 0, numTouchPoints * 2 );
            
        }
        
        if(!pruneInactive){
            for(NSString *touchID in deadTouches){
                [_activeTouches removeObjectForKey:touchID];
            }
        }
        
    }

}

// Ported from Cinder drawSolidCircle
- (void)renderTarget
{
    int numSegments = 32;
    
    NOCShaderProgram *shaderTexture = [self shaderNamed:ShaderNameTexture];
    [shaderTexture use];
    [shaderTexture setMatrix4:_projectionMatrix2D
                   forUniform:UniformMVProjectionMatrix];
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, _textureTarget.name);
    [shaderTexture setInt:0 forUniform:UniformTexture];

    // automatically determine the number of segments from the circumference
    if( numSegments <= 0 ) {
        numSegments = floor( _targetRadius * M_PI * 2 );
    }
    if( numSegments < 2 ) numSegments = 2;
    
    // TODO: Cache this
    GLfloat verts[(numSegments+2)*2];
    GLfloat texs[(numSegments+2)*2];
    GLfloat colors[(numSegments+2)*4];
    
    verts[0] = _targetPosition.x;
    verts[1] = _targetPosition.y;
    texs[0] = 0.5;
    texs[1] = 0.5;

    colors[0] = _didReachTarget;
    colors[1] = 1;
    colors[2] = 1;
    colors[3] = 1;
    
    for( int s = 0; s <= numSegments; s++ ) {
        float t = s / (float)numSegments * 2.0f * 3.14159f;
        
        float radX = cos( t );
        float radY = sin( t );
        
        verts[(s+1)*2+0] = _targetPosition.x + radX * _targetRadius;
        verts[(s+1)*2+1] = _targetPosition.y + radY * _targetRadius;
        
        texs[(s+1)*2+0] = (1.0 + radX) * 0.5;
        texs[(s+1)*2+1] = 1.0 - ((1.0 + radY) * 0.5);
        
        colors[(s+1)*4+0] = _didReachTarget;
        colors[(s+1)*4+1] = 1;
        colors[(s+1)*4+2] = 1;
        colors[(s+1)*4+3] = 1;
    }
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &verts);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &texs);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &colors);

    glDrawArrays( GL_TRIANGLE_FAN, 0, numSegments + 2 );
    glBindTexture(GL_TEXTURE_2D, 0);

}


#pragma mark - Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    for(UITouch *t in touches){
        [self updateTouch:t];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    for(UITouch *t in touches){
        [self updateTouch:t];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    for(UITouch *t in touches){
        [self updateTouch:t];
        [self endTouch:t];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    for(UITouch *t in touches)
    {
        if(t.tapCount > 1){
            [self setupInitialTracers];
        }
        [self updateTouch:t];
        [self endTouch:t];
    }
}

- (void)updateTouch:(UITouch *)touch
{
    NSString *touchID = [NSString stringWithFormat:@"%i", [touch hash]];
    NSMutableDictionary *touchInfo = _activeTouches[touchID];
    if(!touchInfo){
        touchInfo = [NSMutableDictionary dictionary];
        touchInfo[@"touch"] = touch;
        touchInfo[@"isActive"] = @(YES);
        NSMutableArray *touchPos = [NSMutableArray array];
        touchInfo[@"points"] = touchPos;
        _activeTouches[touchID] = touchInfo;
    }
    
    [touchInfo[@"points"] addObject:[NSValue valueWithCGPoint:[touch locationInView:touch.view]]];
    
}

- (void)endTouch:(UITouch *)touch
{
    NSString *touchID = [NSString stringWithFormat:@"%i", [touch hash]];
    NSMutableDictionary *touchInfo = _activeTouches[touchID];
    if(touchInfo){
        touchInfo[@"isActive"] = @(NO);
    }
}

@end

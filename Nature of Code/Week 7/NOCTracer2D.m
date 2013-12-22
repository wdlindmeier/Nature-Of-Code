//
//  NOCTracer2D.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/3/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTracer2D.h"

const static float ForceDistMulti = 0.005;

@interface NOCTracer2D()

@property (nonatomic, assign) GLKVector2 velocity;
@property (nonatomic, assign) GLKVector2 acceleration;

@end

@implementation NOCTracer2D
{
    GLKVector2 *_vectors;
    GLKVector2 *_history;
    float _maxVelocity;
    float _recordDistance;
    int _framesToFinish;
    float _fitness;
}

@synthesize fitness = _fitness;

- (id)initWithDNALength:(int)DNALength
{
    self = [super initWithDNALength:DNALength];
    if(self){
        [self initTracer2D];
    }
    return self;
}

- (id)initWithLifeSpan:(int)lifespan
{
    self = [super initWithLifeSpan:lifespan];
    if(self){
        [self initTracer2D];
    }
    return self;
}

- (void)initTracer2D
{
    _maxVelocity = 0.02;
    _framesToFinish = 0;
    _recordDistance = 10000;
    _fitness = -10000;
    self.didHitObstruction = NO;
    [self expressDNA];
}

- (void)dealloc
{
    if(_vectors) free(_vectors);
    if(_history) free(_history);
}

#pragma mark - Accessors

- (GLKVector2)positionAtFrame:(int)frame
{
    if(frame <= self.framesAlive && frame >= 0){
        return _history[frame];
    }
    return GLKVector2Zero;
}

#pragma mark - Life

- (BOOL)isDead
{
    return self.framesAlive >= self.lifespan;
}

#pragma mark - Genotype

- (void)inheritDNA:(NSArray *)dna1 :(NSArray *)dna2
{
    NSMutableArray *newDNA = [NSMutableArray arrayWithCapacity:self.DNALength];
    for(int i=0;i<self.DNALength;i++){
        NSNumber *n = (RandScalar() < 0.5) ? dna1[i] : dna2[i];
        [newDNA addObject:n];
    }
    self.DNA = [NSArray arrayWithArray:newDNA];
}

- (void)expressDNA
{
    // This is the index after the positions
    int idx = self.lifespan * 2;
    
    // Color
    float r = f([self DNA][idx+0]);
    float g = f([self DNA][idx+1]);
    float b = f([self DNA][idx+2]);
    self.color = [UIColor colorWithRed:r green:g blue:b alpha:1];
    
    if(_vectors) free(_vectors);
    _vectors = malloc(sizeof(GLKVector2) * (self.lifespan));
    if(_history) free(_history);
    _history = malloc(sizeof(GLKVector2) * (self.lifespan + 1)); // +1 for starting position
    
    // Vectors
    for(int i=0;i<self.lifespan;i++){
        
        // -1..1
        float x = ((f([self DNA][(i*2)+0]) * 2) - 1.0f);
        float y = ((f([self DNA][(i*2)+1]) * 2) - 1.0f);
        GLKVector2 pos = GLKVector2MultiplyScalar(GLKVector2Make(x,y), ForceDistMulti);

        _vectors[i] = pos;
        
    }
    
}

#pragma mark - Step

// Taken from Particle2D

- (void)applyForce:(GLKVector2)vecForce
{
    self.acceleration = GLKVector2Add(self.acceleration, vecForce);
}

- (void)checkHitBounds:(CGRect)rect
{
    float x = self.position.x;
    float y = self.position.y;
    
    float minX = rect.origin.x;
    float maxX = (rect.origin.x + rect.size.width);
    float minY = rect.origin.y;
    float maxY = (rect.origin.y + rect.size.height);
    
    if(x < minX){
        x = minX;
        self.didHitObstruction = YES;
    }
    else if(x > maxX){
        x = maxX;
        self.didHitObstruction = YES;
    }
    
    if(y < minY){
        y = minY;
        self.didHitObstruction = YES;
    }
    else if(y > maxY){
        y = maxY;
        self.didHitObstruction = YES;
    }
    
    if(self.didHitObstruction){
        // Constrain
        self.position = GLKVector2Make(x, y);
    }

}

- (void)stepInRect:(CGRect)rect
{
    if(self.framesAlive == 0){
        // Starting position
        _history[self.framesAlive] = self.position;
    }
    
    [super step];
    
    if(![self isDead]){
        
        if(!self.didHitObstruction){
            
            [self applyForce:_vectors[self.framesAlive]];
            
            // Add accel to velocity
            self.velocity = GLKVector2Add(self.velocity, self.acceleration);
            
            // Limit the velocity
            if(_maxVelocity > 0){
                self.velocity = GLKVector2Limit(self.velocity, _maxVelocity);
            }
            
            // Add velocity to location
            self.position = GLKVector2Add(self.position, self.velocity);
            
            [self checkHitBounds:rect];
            
        }
        
        _history[self.framesAlive] = self.position;
        
    }else{
        
        self.velocity = GLKVector2Zero;
        
    }

    // Reset the acceleration
    self.acceleration = GLKVector2Zero;
}

#pragma mark - Fitness

- (void)checkTarget:(GLKVector2)target radius:(float)targetRadius
{    
    float d = GLKVector2Distance(self.position, target);
    if (d < _recordDistance) _recordDistance = d;

    if (d < targetRadius) {
        self.didHitTarget = YES;
    }
    
    else if (!self.didHitTarget) {
        _framesToFinish += 1;
    }
}

- (float)evaluateFitness
{

    if (_recordDistance < 0.00001) _recordDistance = 0.00001;
    
    // Reward finishing faster and getting close
    float fitness = (1/(_framesToFinish*_recordDistance));
    
    // Make the function exponential
    fitness = pow(fitness, 4);
    
    if (self.didHitObstruction) fitness *= 0.1; // lose 90% of fitness hitting an obstacle
    if (self.didHitTarget) fitness *= 2; // twice the fitness for finishing!

    _fitness = fitness;
    return _fitness;
    
}

#pragma mark - Draw

- (void)render:(BOOL)colored
{
    GLfloat myColor[4];
    if(colored){
        
        [self glColor:myColor];
        
    }else{
        
        if(self.didHitTarget){
            
            myColor[0] = 0.2;
            myColor[1] = 1;
            myColor[2] = 0.2;

        }else if(self.didHitObstruction){
            
            myColor[0] = 1;
            myColor[1] = 0.2;
            myColor[2] = 0.2;

        }else{
            
            myColor[0] = 0.75;
            myColor[1] = 0.75;
            myColor[2] = 0.75;
        }
    }
    
    int framesAlive = self.framesAlive;
    
    GLfloat historyColor[framesAlive*4];
    GLfloat historyVecs[framesAlive*2];
    
    for(int i=0;i<framesAlive;i++){
        
        historyColor[i*4+0] = myColor[0];
        historyColor[i*4+1] = myColor[1];
        historyColor[i*4+2] = myColor[2];
        historyColor[i*4+3] = 0.5;
        
        historyVecs[i*2] = _history[i].x;
        historyVecs[i*2+1] = _history[i].y;
        
    }
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, &historyVecs);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &historyColor);
    glDrawArrays( GL_LINE_STRIP, 0, framesAlive );
}

@end

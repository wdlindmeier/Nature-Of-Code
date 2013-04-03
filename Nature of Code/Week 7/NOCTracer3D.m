//
//  NOCTracer3D.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/3/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTracer3D.h"

static const float MaxConstrain = 0.05f;
static const float MinConstrain = 0.001f;
static const float RangeConstrain = MaxConstrain - MinConstrain;


@implementation NOCTracer3D
{
    float _constrain;
    GLKVector3 *_positions;

}

- (id)initWithDNALength:(int)DNALength
{
    self = [super initWithDNALength:DNALength];
    if(self){
        _positions = NULL;
    }
    return self;
}


- (void)dealloc
{
    if(_positions){
        free(_positions);
        _positions = NULL;
    }
}

#pragma mark - Phenotype

// NOTE: This suggests a poor design, because we're passing down the
// "effects" and not just the DNA...
// Ask Dan about this.
- (void)inheritPositions:(GLKVector3 *)positionsA :(GLKVector3 *)positionsB
{
    int halfwayPoint = arc4random() % (self.lifespan+1);
    for(int i=0;i<self.lifespan+1;i++){
        // Populate the DNA
        GLKVector3 posA = positionsA[i];
        GLKVector3 posB = positionsB[i];
        GLKVector3 posC = (i < halfwayPoint) ? posA : posB;
        _positions[i] = posC;
    }
}

- (void)mutatePositions
{
    double mutRate = [NOCTracer mutationRate];
    for(int i=0;i<self.lifespan+1;i++){
        if(RAND_SCALAR < mutRate){
            
            GLKVector3 pos = _positions[i];
            
            float x = ((RAND_SCALAR * 2) - 1.0f) * MaxConstrain;
            float y = ((RAND_SCALAR * 2) - 1.0f) * MaxConstrain;
            float z = ((RAND_SCALAR * 2) - 1.0f) * MaxConstrain;
            GLKVector3 offset = GLKVector3Make(x, y, z);
            
            GLKVector3 newPos = GLKVector3Add(pos, offset);
            
            // Constrain if necessary.
            // This might not be perfect, but it should be close enough.
            /*
             if(i>0){
             GLKVector3 lastPos = _positions[i-1];
             GLKVector3 dirLastPoint = GLKVector3Subtract(newPos, lastPos);
             float distLastPoint = GLKVector3Length(dirLastPoint);
             if(distLastPoint > MaxConstrain){
             GLKVector3 offsetLast = GLKVector3MultiplyScalar(dirLastPoint, MaxConstrain);
             newPos = GLKVector3Add(lastPos, offsetLast);
             }
             }
             if(i<self.lifespan){
             GLKVector3 nextPos = _positions[i+1];
             GLKVector3 dirNextPoint = GLKVector3Subtract(newPos, nextPos);
             float distNextPoint = GLKVector3Length(dirNextPoint);
             if(distNextPoint > MaxConstrain){
             GLKVector3 offsetNext = GLKVector3MultiplyScalar(dirNextPoint, MaxConstrain);
             newPos = GLKVector3Add(nextPos, offsetNext);
             }
             }
             */
            _positions[i] = newPos;
            
        }
    }
}

- (GLKVector3 *)positions
{
    return _positions;
}

#pragma mark Genotype

- (void)expressDNA
{
    
    // This is the index after the positions
    int idx = (self.lifespan + 1) * 3;
    
    // Color
    float r = f([self DNA][idx+0]) * 2 - 1.0f;
    float g = f([self DNA][idx+1]) * 2 - 1.0f;
    float b = f([self DNA][idx+2]) * 2 - 1.0f;
    self.color = [UIColor colorWithRed:r green:g blue:b alpha:1];
    
    // Spring constraints
    float constrain = f([self DNA][idx+3]);
    _constrain = MinConstrain + (constrain * RangeConstrain);
    
    _positions = malloc(sizeof(GLKVector3) * (self.lifespan + 1));
    
    GLKVector3 lastPos;
    
    // Positions
    for(int i=0;i<self.lifespan+1;i++){
        
        float x = ((f([self DNA][(i*3)+0]) * 2) - 1.0f);
        float y = ((f([self DNA][(i*3)+1]) * 2) - 1.0f);
        float z = ((f([self DNA][(i*3)+2]) * 2) - 1.0f);
        
        GLKVector3 pos;
        
        if(i == 0){
            
            // this is the starting position
            pos = GLKVector3Make(x, y, z);
            
        }else{
            
            // This is an offset from the previous point
            // -1..1 * MaxConstrain
            GLKVector3 delta = GLKVector3Make(x * MaxConstrain,
                                              y * MaxConstrain,
                                              z * MaxConstrain);
            
            GLKVector3 offset = delta;
            float dist = GLKVector3Length(delta);
            GLKVector3 normDelta = GLKVector3Normalize(delta);
            if(dist < MinConstrain){
                offset = GLKVector3MultiplyScalar(normDelta, MinConstrain);
            }else if(dist > MaxConstrain){
                offset = GLKVector3MultiplyScalar(normDelta, MaxConstrain);
            }
            
            pos = GLKVector3Add(lastPos, offset);
            
        }
        
        _positions[i] = pos;
        
        lastPos = pos;
        
    }    
    
}

#pragma mark - Reproduction

- (NOCTracer3D *)crossover:(NOCTracer3D *)mate
{
    NOCTracer3D *baby = (NOCTracer3D *)[super crossover:mate];
    // NOTE: We actually want to pass down the specific positions
    // and not just a steering map. Basically we're exchanging Phenotype
    // and clobbering the genotype.
    [baby inheritPositions:[self positions] :[mate positions]];
    [baby mutatePositions];    
    return baby;
}

#pragma mark - Fitness

- (float)overallFitnessForCircleOfRadius:(float)radius
{
    // Zero is as good as it gets.
    // All of the distances will be subtracted from 0.
    float fitness = 0;
    
    for(int i=0;i<self.lifespan+1;i++){
        
        GLKVector3 pos = _positions[i];
        
        float posDist = GLKVector3Length(pos);
        
        float delta = fabs(radius - posDist);
        
        fitness -= delta;
    }
    
    return fitness;
}

#pragma mark - Draw

- (void)render:(BOOL)colored
{
    GLfloat myColor[4];
    if(colored){
        [self glColor:myColor];
    }else{
        myColor[0] = 0.75;
        myColor[1] = 0.75;
        myColor[2] = 0.75;
    }
    
    int framesAlive = self.framesAlive;
    
    GLfloat historyColor[framesAlive*4];
    GLfloat historyVecs[framesAlive*3];
    
    for(int i=0;i<framesAlive;i++){
        historyColor[i*4+0] = myColor[0];
        historyColor[i*4+1] = myColor[1];
        historyColor[i*4+2] = myColor[2];
        historyColor[i*4+3] = 0.5;
        
        historyVecs[i*3] = _positions[i].x;
        historyVecs[i*3+1] = _positions[i].y;
        historyVecs[i*3+2] = _positions[i].z;
    }
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &historyVecs);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &historyColor);
    glDrawArrays( GL_LINE_STRIP, 0, framesAlive );
}

@end

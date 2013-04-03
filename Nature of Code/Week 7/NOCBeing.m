//
//  NOCBeing.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCBeing.h"
#import "NOCColorHelpers.h"

static const float ForceDistMulti = 0.005;

@implementation NOCBeing
{
    int _framesAlive;
    int _lifespan;
    float _fitness;
    GLKVector3 _vectors[MaxBeingLifespan];
    GLKVector3 _positionHistory[MaxBeingLifespan];
    float _distTravelled;
    int _numChildren;
    int _frameLastBaby;
}

@synthesize distTravelled = _distTravelled;
@synthesize framesAlive = _framesAlive;
@synthesize startingPosition = _startingPosition;
@synthesize numChildren = _numChildren;

- (id)initWithRadius:(float)radius position:(GLKVector3)position mass:(float)mass
{
    // We'll use the dimension to create a size, but it won't be strictly accurate
    float dimension = radius * 2;
    self = [super initWithSize:GLKVector3Make(dimension, dimension, dimension)
                      position:position
                          mass:mass];
    if(self){
        _startingPosition = position;
        _framesAlive = 0;
        _lifespan = MaxBeingLifespan;
        _distTravelled = 0;
        _frameLastBaby = 0;
        _numChildren = 0;
        self.numWallCollisions = 0;
        self.fitness = -1;
        self.radius = radius;        
        self.maxVelocity = 0.1;
        
        [NOCBeing calculateGeometry];

    }
    return self;
}

- (GLKVector3 *)vectors
{
    return _vectors;
}

- (GLKVector3 *)positionHistory
{
    return _positionHistory;
}

- (BOOL)canProcreate
{
    return (_framesAlive - _frameLastBaby) > MinFramesBetweenProcreation;
}

- (void)didProcreate
{
    _frameLastBaby = _framesAlive;
    _numChildren++;
}

- (void)randomizeDNA
{
    for(int i=0;i<MaxBeingLifespan;i++){
        GLKVector3 vec = GLKVector3Make((RAND_SCALAR*2) - 1.0,
                                        (RAND_SCALAR*2) - 1.0,
                                        (RAND_SCALAR*2) - 1.0);
        vec = GLKVector3Normalize(vec);
        vec = GLKVector3MultiplyScalar(vec, ForceDistMulti);
        _vectors[i] = vec;
    }
    
    self.color = [UIColor colorWithRed:RAND_SCALAR
                                 green:RAND_SCALAR
                                  blue:RAND_SCALAR
                                 alpha:1];
}

- (float)evaluateFitness
{
    self.fitness = self.numChildren + 1;
    return self.fitness;
}

- (NOCBeing *)presentOpportunityToProcreateWithMate:(NOCBeing *)mate
{
    NOCBeing *baby = nil;
    
    if([self canProcreate] && [mate canProcreate]){
        
        [self evaluateFitness];
        [mate evaluateFitness];
        
        baby = [self crossover:mate];
        
    }else{
        NSLog(@"ERROR: Can't procreate yet");
    }
    
    return baby;
}

- (NOCBeing *)crossover:(NOCBeing *)mate
{
    NOCBeing *baby = nil;
    
    float myWeight = self.fitness / (self.fitness + mate.fitness);
    
    float bRadius = RAND_SCALAR < myWeight ? self.radius : mate.radius;
     GLKVector3 bPosition = RAND_SCALAR < myWeight ? self.startingPosition : mate.startingPosition;
    float bMass = RAND_SCALAR < myWeight ? self.mass : mate.mass;
    
    baby = [[[self class] alloc] initWithRadius:bRadius
                                       position:bPosition
                                           mass:bMass];    
    for(int i=0;i<MaxBeingLifespan;i++){
        // Populate the DNA
        baby.vectors[i] = RAND_SCALAR < myWeight ? [self vectors][i] : [mate vectors][i];
    }
        
    const CGFloat *myColor = CGColorGetComponents(self.color.CGColor);
    if(CGColorGetNumberOfComponents(self.color.CGColor) < 3){
        myColor = CGColorGetComponents([UIColor whiteColor].CGColor);
    }
    const CGFloat *mateColor = CGColorGetComponents(mate.color.CGColor);
    if(CGColorGetNumberOfComponents(mate.color.CGColor) < 3){
        mateColor = CGColorGetComponents([UIColor whiteColor].CGColor);
    }
    
    baby.color = [UIColor colorWithRed:RAND_SCALAR < myWeight ? myColor[0] : mateColor[0]
                                 green:RAND_SCALAR < myWeight ? myColor[1] : mateColor[1]
                                  blue:RAND_SCALAR < myWeight ? myColor[2] : mateColor[2]
                                 alpha:1];
    
    [baby mutate];
    
    baby.generation = MAX(self.generation, mate.generation) + 1;
    
    [self didProcreate];
    [mate didProcreate];
    
    return baby;    
}

- (void)mutate
{
    for(int i=0;i<MaxBeingLifespan;i++){
        if(RAND_SCALAR < BeingMutationRate){
            GLKVector3 vec = GLKVector3Make((RAND_SCALAR*2) - 1.0,
                                            (RAND_SCALAR*2) - 1.0,
                                            (RAND_SCALAR*2) - 1.0);
            vec = GLKVector3Normalize(vec);
            vec = GLKVector3MultiplyScalar(vec, ForceDistMulti);
            _vectors[i] = vec;            
        }
    }
    
    float rand = RAND_SCALAR;
    if(rand < BeingMutationRate){
        self.color = [UIColor colorWithRed:RAND_SCALAR
                                     green:RAND_SCALAR
                                      blue:RAND_SCALAR
                                     alpha:1];
    }else{
        //NSLog(@"no change rand: %f BeingMutationRate %f", rand, BeingMutationRate);
    }
    
    // NOTE: This is making assumptions about the size of the world
    if(RAND_SCALAR < BeingMutationRate){
        float randX = (RAND_SCALAR * 1.9) - 0.95f;
        float randY = (RAND_SCALAR * 1.9) - 0.95f;
        float randZ = (RAND_SCALAR * 1.9) - 0.95f;
        _startingPosition = GLKVector3Make(randX, randY, randZ);
        self.position = _startingPosition;
    }
}

- (BOOL)isDead
{
    return _framesAlive > _lifespan;
}

- (void)step
{
    GLKVector3 prevPos = self.position;
    _positionHistory[_framesAlive] = prevPos;
    
    if(![self isDead]){
        [self applyForce:_vectors[_framesAlive]];
    }
    
    [super step];
    float dist = GLKVector3Distance(self.position, prevPos);
    _distTravelled += dist;    
    _framesAlive++;
    const float friction = -0.01;
    self.velocity = GLKVector3MultiplyScalar(self.velocity, 1.0 + friction);

}

- (void)glColor:(GLfloat *)components
{
    
    float scalarAge = 1.0 - ((float)_framesAlive / (float)_lifespan);
    
    CGFloat red = 1.0;
    CGFloat green = 1.0;
    CGFloat blue = 1.0;
    CGFloat alpha = 1.0;
    int framesSinceBaby = _framesAlive - _frameLastBaby;
    BOOL recentlyProcreated = framesSinceBaby < 5 && _framesAlive > framesSinceBaby;
    if(recentlyProcreated){
        // Color them red when they're in contact w/ another being
        green = 0;
        blue = 0;
    }
    components[0] = red * scalarAge;
    components[1] = green * scalarAge;
    components[2] = blue * scalarAge;
    components[3] = alpha * scalarAge;
}

- (void)render
{
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &BeingBodyVerts);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, &BeingBodyNormals);
    
    glDrawArrays( GL_TRIANGLE_STRIP, 0, BeingNumRenderVerts );
}

- (void)renderHistory:(BOOL)colored
{
    GLfloat myColor[4];
    if(colored){
        [self glColor:myColor];
    }else{
        myColor[0] = 0.75;
        myColor[1] = 0.75;
        myColor[2] = 0.75;
    }
    
    GLfloat historyColor[_framesAlive*4];
    GLfloat historyVecs[_framesAlive * 3];
    
    for(int i=0;i<_framesAlive;i++){
        historyColor[i*4+0] = myColor[0];
        historyColor[i*4+1] = myColor[1];
        historyColor[i*4+2] = myColor[2];
        historyColor[i*4+3] = 0.5;

        historyVecs[i*3] = _positionHistory[i].x;
        historyVecs[i*3+1] = _positionHistory[i].y;
        historyVecs[i*3+2] = _positionHistory[i].z;
    }
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    // NOTE: Is this bad mojo?
    // Getting some odd crashes. ( e.g. EXC_??? )
    //glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_positionHistory);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &historyVecs);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &historyColor);
    glDrawArrays( GL_LINE_STRIP, 0, _framesAlive );
    //glDrawArrays( GL_TRIANGLE_STRIP, 0, _framesAlive );
}

// Based on Cinder gl::drawSphere
+ (void)calculateGeometry
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        int numJs = BeingSphereSegments / 2;
        int nIdx=0;
        int texIdx=0;
        int vIdx=0;
        int dIdx=0;
        for( int j = 0; j < numJs; j++ ) {
            float theta1 = j * 2 * 3.14159f / BeingSphereSegments - ( 3.14159f / 2.0f );
            float theta2 = (j + 1) * 2 * 3.14159f / BeingSphereSegments - ( 3.14159f / 2.0f );
            
            for( int i = 0; i <= BeingSphereSegments; i++ ) {
                
                GLKVector3 e, p;
                
                float theta3 = i * 2 * 3.14159f / BeingSphereSegments;
                
                e.x = cos( theta1 ) * cos( theta3 );
                e.y = sin( theta1 );
                e.z = cos( theta1 ) * sin( theta3 );
                
                p = GLKVector3MultiplyScalar(e, 0.5);
                
                BeingBodyNormals[nIdx+0] = e.x; BeingBodyNormals[nIdx+1] = e.y; BeingBodyNormals[nIdx+2] = e.z;
                
                BeingBodyTexCoords[texIdx+0] = 0.999f - i / (float)BeingSphereSegments;
                BeingBodyTexCoords[texIdx+1] = 0.999f - 2 * j / (float)BeingSphereSegments;
                
                BeingBodyVerts[vIdx+0] = p.x; BeingBodyVerts[vIdx+1] = p.y; BeingBodyVerts[vIdx+2] = p.z;
                
                // Fill the data array
                BeingBodyDrawBuffer[dIdx+0] = BeingBodyVerts[vIdx+0];
                BeingBodyDrawBuffer[dIdx+1] = BeingBodyVerts[vIdx+1];
                BeingBodyDrawBuffer[dIdx+2] = BeingBodyVerts[vIdx+2];
                BeingBodyDrawBuffer[dIdx+3] = BeingBodyNormals[nIdx+0];
                BeingBodyDrawBuffer[dIdx+4] = BeingBodyNormals[nIdx+1];
                BeingBodyDrawBuffer[dIdx+5] = BeingBodyNormals[nIdx+2];
                vIdx+=3;
                nIdx+=3;
                texIdx+=2;
                dIdx+=6;
                
                e.x = cos( theta2 ) * cos( theta3 );
                e.y = sin( theta2 );
                e.z = cos( theta2 ) * sin( theta3 );
                
                p = GLKVector3MultiplyScalar(e, 0.5);
                
                BeingBodyNormals[nIdx+0] = e.x; BeingBodyNormals[nIdx+1] = e.y; BeingBodyNormals[nIdx+2] = e.z;
                
                BeingBodyTexCoords[texIdx+0] = 0.999f - i / (float)BeingSphereSegments;
                BeingBodyTexCoords[texIdx+1] = 0.999f - 2 * ( j + 1 ) / (float)BeingSphereSegments;
                
                BeingBodyVerts[vIdx+0] = p.x; BeingBodyVerts[vIdx+1] = p.y; BeingBodyVerts[vIdx+2] = p.z;
                
                // Fill the data array
                BeingBodyDrawBuffer[dIdx+0] = BeingBodyVerts[vIdx+0];
                BeingBodyDrawBuffer[dIdx+1] = BeingBodyVerts[vIdx+1];
                BeingBodyDrawBuffer[dIdx+2] = BeingBodyVerts[vIdx+2];
                BeingBodyDrawBuffer[dIdx+3] = BeingBodyNormals[nIdx+0];
                BeingBodyDrawBuffer[dIdx+4] = BeingBodyNormals[nIdx+1];
                BeingBodyDrawBuffer[dIdx+5] = BeingBodyNormals[nIdx+2];
                vIdx+=3;
                nIdx+=3;
                texIdx+=2;
                dIdx+=6;

            }

        }
    });
    
}

static float BeingMutationRate = 0.01;

+ (float)mutationRate
{
    return BeingMutationRate;
}

+ (void)setMutationRate:(float)newRate
{
    BeingMutationRate = newRate;
}


@end

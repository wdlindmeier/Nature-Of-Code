//
//  NOCHair.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/8/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCHair.h"
#import "NOCParticle2D.h"
#import "NOCSpring2D.h"
#import "NOCShaderProgram.h"

@implementation NOCHair
{
    NSMutableArray *_particles;
    NSMutableArray *_springs;
    int _numParticles;
    void *_kvoContextUpdateAnchor;
    void *_kvoContextUpdateParticles;
    void *_kvoContextUpdateSprings;
    float _lastSegmentLength;
    float _distBetweenParticles;
}

@synthesize lastSegmentLength = _lastSegmentLength;

- (id)initWithAnchor:(GLKVector2)anchor numParticles:(int)numParticles ofLength:(float)distBetweenParticles
{
    self = [super init];
    if(self){
        
        self.maxNumParticles = 0;
        self.anchor = anchor;
        _particles = [NSMutableArray arrayWithCapacity:numParticles];
        _springs = [NSMutableArray arrayWithCapacity:numParticles];
        _growthRate = 0;
        _distBetweenParticles = distBetweenParticles;
        _lastSegmentLength = numParticles > 0 ? distBetweenParticles : 0.0f;

        for(int i=0;i<numParticles;i++){
            
            [self addParticle];
            
        }
        
        /*
        // Major WTF: KVO doesn't work on GLKVector2, but it works with
        // CGPoints. For member consistency, I'm just going to keep the
        // GLKVector and add a custom setter that calls the observe method.
        [self addObserver:self
               forKeyPath:@"anchor"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextUpdateAnchor];
        */
        
        [self addObserver:self
               forKeyPath:@"maxVelocity"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextUpdateParticles];
        
        [self addObserver:self
               forKeyPath:@"amtStretch"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextUpdateSprings];
        
        [self addObserver:self
               forKeyPath:@"dampening"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextUpdateSprings];
        
        
        self.maxVelocity = 0.2f;
        self.amtStretch = 2.0f;
        // Dont bother dampening. It doesnt give us much here, other than a little slow down
        // self.dampening = -0.1;
        
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"maxVelocity"];
    [self removeObserver:self forKeyPath:@"amtStretch"];
    [self removeObserver:self forKeyPath:@"dampening"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context == &_kvoContextUpdateParticles){
        [self updateParticleParams];
    }else if(context == &_kvoContextUpdateSprings){
        [self updateSpringParams];
    }
}

#pragma mark - Accessors

// NOTE: For some reason observing KVO doesn't work w/ GLKVector2
- (void)setAnchor:(GLKVector2)anchor
{
    _anchor = anchor;
    [self updateAnchorSpring];
}

- (void)addParticle
{
    
    if(self.numParticles < self.maxNumParticles){
        
        NOCParticle2D *previousP = [_particles lastObject];

        GLKVector2 pStart;
        if(previousP){
            pStart = previousP.position;
        }else{
            pStart = self.anchor;
        }
        
        NOCParticle2D *p = [[NOCParticle2D alloc] initWithSize:GLKVector2Make(0.01, 0.01) // size is arbitrary atm
                                                      position:pStart];
        
        [_particles addObject:p];
        
        NOCSpring2D *spring;
        
        if(previousP){
            
            spring = [[NOCSpring2D alloc] initWithParicleA:previousP
                                                 particleB:p
                                                restLength:_lastSegmentLength];
            
        }else{
            
            spring = [[NOCSpring2D alloc] initWithParicle:p
                                                   anchor:self.anchor
                                               restLength:_lastSegmentLength];
            
        }
        
        [_springs addObject:spring];
        
    }    
}


- (int)numParticles
{
    return _particles.count;
}

#pragma mark - Update

- (void)updateParticleParams
{
    for(NOCParticle2D *p in _particles){
        p.maxVelocity = self.maxVelocity;
    }
}

- (void)updateSpringParams
{
    for(NOCSpring2D *s in _springs){
        s.maxLength = s.restLength * self.amtStretch;
        s.dampening = self.dampening;
    }
}

- (void)updateAnchorSpring
{
    if(_springs.count > 0){
        NOCSpring2D *anchorSpring = _springs[0];
        anchorSpring.anchor = GLKVector2Make(self.anchor.x, self.anchor.y);
    }
}

- (void)update
{
    for(NOCParticle2D *p in _particles){
        [p step];
    }
    
    // Constrain after they've stepped
    for(int i=0;i<_particles.count;i++){
        NOCSpring2D *s = _springs[i];
        [s constrainParticles];
    }
    
    // Adding particles afterward so their spawn position isn't 1 frame behind
    if(_growthRate > 0){
        
        float newSegmentLength = fmod((_lastSegmentLength + _growthRate), _distBetweenParticles);
        BOOL didWrap = (newSegmentLength < _lastSegmentLength) || (_particles.count == 0);
    
        if(didWrap){
            
            if(self.numParticles < self.maxNumParticles){
                // We've wrapped. Add a particle
                [self addParticle];
            }else{
                // NOTE: Kill the growth if we've run out of particles
                newSegmentLength = _lastSegmentLength;
            }
            
        }
        
        _lastSegmentLength = newSegmentLength;
        
        // Extend the length of the last spring
        NOCSpring2D *lastSpring = [_springs lastObject];
        lastSpring.restLength = _lastSegmentLength;
        // Constrain it to the truncated length
        lastSpring.maxLength = _lastSegmentLength;
        
    }
    
}


#pragma mark - Physics

- (void)applyForce:(GLKVector2)force toParticleAtIndex:(int)pIdx
{
    // Whenever we apply a force, we also constrain the particle according to it's spring.
    // If we apply the springs after all of the particles have been updated,
    // it has an unexpected cascading effect that doesn't look natural.
    // In other words, whenever a particle or spring is updated,
    // the one before it should already be updated.
    
    NOCParticle2D *p = _particles[pIdx];
    NOCSpring2D *s = _springs[pIdx];
    
    // First move the particle.
    [p applyForce:force];
    // Then apply spring effect.
    [s applyForceToParticles];

    // We could constrain here also, but it doesnt seem to have much effect
}

// NOTE: This applies to all paricles equally regardless of the position of the particle.
// This is good for gravity and general wind.
- (void)applyForce:(GLKVector2)force
{
    for(int i=0;i<_particles.count;i++){
        [self applyForce:force toParticleAtIndex:i];
    }
}

// NOTE: This takes the position of the force and the position of the particle
// into effect. We yeild control to a block so it can affect the force (e.g.
// using a distance multi, reverse, or whatever.
- (void)applyPointForce:(GLKVector2)fPos withMagnitude:(float(^)(float distToParticle))forceBlock;
{
    for(int i=0;i<_particles.count;i++){
        NOCParticle2D *p = _particles[i];
        GLKVector2 dir = GLKVector2Subtract(p.position, fPos);
        float distToParicle = GLKVector2Length(dir);
        dir = GLKVector2Normalize(dir);
        float mag = 1.0f;
        if(forceBlock){
            mag = forceBlock(distToParicle);
        }
        GLKVector2 force = GLKVector2MultiplyScalar(dir, mag);
        [self applyForce:force toParticleAtIndex:i];
    }
}

#pragma mark - Draw

- (void)renderParticles:(void(^)(GLKMatrix4 particleMatrix, NOCParticle2D *p))pRenderBlock
             andSprings:(void(^)(GLKMatrix4 springMatrix, NOCSpring2D *s))sRenderBlock
{
    for(NOCParticle2D *p in _particles){
        
        // Get the model matrix
        GLKMatrix4 modelMat = [p modelMatrix];
        pRenderBlock(modelMat, p);

        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &Square3DBillboardVertexData);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
    }

    for(NOCSpring2D *s in _springs){
        
        // NOTE: Springs don't have their own matrix. Just draw in projection.
        GLKMatrix4 modelMat = GLKMatrix4Identity;
        sRenderBlock(modelMat, s);
        [s render];
    }
}

@end

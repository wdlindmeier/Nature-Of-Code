//
//  NOCFollowersSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/31/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFollowersSketchViewController.h"
#import "NOCShaderProgram.h"
#import "NOCFollower.h"
#import "NOCSharedFollowerTrail.h"

@interface NOC3DSketchViewController(Private)

- (void)rotateQuaternionWithVector:(CGPoint)delta;

@end

@interface NOCFollowersSketchViewController ()
{
    
    NOCBox3D _moverBounds;
    NSMutableArray *_followers;
    GLKVector3 _vecNavigation;
    
    int _numBatchFollowers;
    int _generationFrame;
    int _numFramesPerGeneration;
    int _numUpdates;
    int _updateSpeed;
    
    GLKVector3 _surfBottomWall[4];
    GLKVector3 _surfTopWall[4];
    GLKVector3 _surfBackWall[4];
    GLKVector3 _surfFrontWall[4];
    GLKVector3 _surfRightWall[4];
    GLKVector3 _surfLeftWall[4];

    NOCSharedFollowerTrail *_sharedTrail;    
    
}

@end

static NSString * ShaderNameFollowers = @"Being";
static NSString * ShaderNameSceneBox = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformNormalMatrix = @"normalMatrix";
static NSString * UniformColor = @"color";

@implementation NOCFollowersSketchViewController

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiFollowers";
}

- (void)updateFromSliders
{
    int framesPerUpdate = self.sliderEvolutionRate.value;
    if(framesPerUpdate != _updateSpeed){
        _updateSpeed = framesPerUpdate;
        NSLog(@"_updateSpeed: %i", _updateSpeed);
    }
    
    float mutationRate = self.sliderMutationRate.value * 0.001;
    if(mutationRate != [NOCFollower mutationRate]){
        [NOCFollower setMutationRate:mutationRate];
        NSLog(@"Mutation rate: %f", [NOCFollower mutationRate]);
    }
    
}

#pragma mark - Setup

- (void)setup
{
    _sharedTrail = [[NOCSharedFollowerTrail alloc] init];
    
    _updateSpeed = 1;
    _numBatchFollowers = 30;
    _generationFrame = 0;
    _numFramesPerGeneration = MaxBeingLifespan;
    
    NOCShaderProgram *shaderSceneBox = [[NOCShaderProgram alloc] initWithName:ShaderNameSceneBox];
    shaderSceneBox.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                   @"color" : @(GLKVertexAttribColor), };
    shaderSceneBox.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shaderSceneBox named:ShaderNameSceneBox];
    
    NOCShaderProgram *shaderBeings = [[NOCShaderProgram alloc] initWithName:ShaderNameFollowers];
    shaderBeings.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                 @"normal" : @(GLKVertexAttribNormal)};//,

    shaderBeings.uniformNames = @[ UniformMVProjectionMatrix, UniformNormalMatrix, UniformColor ];
    [self addShader:shaderBeings named:ShaderNameFollowers];
    
    self.isArcballEnabled = NO;
    self.isGestureNavigationEnabled = YES;
    
    [self setupInitialFollowers];
    
    glEnable(GL_DEPTH_TEST);
    
    [NOCBeing calculateGeometry];
    
}

- (void)setupInitialFollowers
{
    [_sharedTrail reset];
    
    _numUpdates = 0;
    _generationFrame = 0;
    
    _followers = [NSMutableArray arrayWithCapacity:_numBatchFollowers];

    for(int i=0;i<_numBatchFollowers;i++){
        [_followers addObject:[self randomFollower]];
    }
}

- (NOCBeing *)randomFollower
{
    float randX = (RAND_SCALAR * 1.9) - 0.95f;
    float randY = (RAND_SCALAR * 1.9) - 0.95f;
    float randZ = (RAND_SCALAR * 1.9) - 0.95f;
    GLKVector3 startingPoint = GLKVector3Make(randX, randY, randZ);
    float mass = 1.0f;
    float radius = 0.05;
    NOCFollower *randFollower = [[NOCFollower alloc] initWithRadius:radius
                                                           position:startingPoint
                                                               mass:mass];
    [randFollower randomizeDNA];
    randFollower.generation = 0;
    randFollower.sharedTrail = [[NOCSharedFollowerTrail alloc] init];
    
    return randFollower;
    
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

    // Find the max fitness so we can normalize
    float maxFitness = ((NOCFollower *)_followers[0]).fitness;
    float minFitness = maxFitness;
    for(NOCFollower *f in _followers){
        if(f.fitness > maxFitness){
            maxFitness = f.fitness;
        }
        if(f.fitness < minFitness){
            minFitness = f.fitness;
        }
    }
    float fitnessRange = maxFitness - minFitness;
    
    int bucketSize = _numBatchFollowers * 5; // large number so small fish still have a chance
    NSMutableArray *genePool = [NSMutableArray arrayWithCapacity:bucketSize];
    
    for(NOCFollower *f in _followers){
        
        // Normalize all of the fitnesses between 0 and 1
        float normalFitness = (f.fitness-minFitness) / fitnessRange;
        int numInPool = round(bucketSize * normalFitness);
        for(int i=0;i<numInPool;i++){
            [genePool addObject:f];
        }
    }

    _followers = [NSMutableArray arrayWithCapacity:_numBatchFollowers];
    
    NSMutableDictionary *sharedTrails = [NSMutableDictionary dictionaryWithCapacity:_numBatchFollowers];
    
    for(int i=0;i<_numBatchFollowers;i++){
        
        int randIdxA = arc4random() % genePool.count;
        int randIdxB = arc4random() % genePool.count;
        
        NOCFollower *parentA = genePool[randIdxA];
        NOCFollower *parentB = genePool[randIdxB];
        
        // How do we select which parent to link the trail on...?
        // Maybe the one with the greater fitness to encourage greater
        // variety.
        NOCFollower *siblingParent = parentA.fitness > parentB.fitness ? parentA : parentB;
        NSString *sharedTrailKey = [NSString stringWithFormat:@"%i", [siblingParent hash]];
        NOCSharedFollowerTrail *sharedTrail = [sharedTrails valueForKey:sharedTrailKey];
        if(!sharedTrail){
            sharedTrail = [[NOCSharedFollowerTrail alloc] init];
            [sharedTrails setValue:sharedTrail forKey:sharedTrailKey];
        }
        
        NOCFollower *nextGen = (NOCFollower *)[parentA crossover:parentB];
        nextGen.sharedTrail = sharedTrail;
        
        if(!nextGen){
            NSLog(@"ERROR: Couldn't cross over next gen");
        }else{
            [_followers addObject:nextGen];
        }
    }
    
}

- (void)update
{
    [super update];
    
    [self updateFromSliders];
    
    _generationFrame++;
    
    if(_generationFrame >= _numFramesPerGeneration){
        
        [self selectNextGeneration];
        self.labelGeneration.text = [NSString stringWithFormat:@"Generation: %i", [_followers[0] generation]];
        
    }else if(_generationFrame == _numFramesPerGeneration-1){
        
        // Force the screen to render before a new generation
        _numUpdates = _updateSpeed;
        
    }

    for(NOCFollower *follower in _followers){
        
        
        FollowerGridPosition fPos0 = follower.gridPosition;
        
        BOOL ShouldConstrain = YES;
        
        // NOTE: If it doesn't constrain, it can't test the trail
        if(ShouldConstrain){
            
            follower.wallContact = WallSideNone;
            WallSide contactWall = [self detectCollisionWithWallsOnFollower:follower];
            
            if(contactWall != WallSideNone){
                follower.wallContact = contactWall;
                [self applyWallContact:contactWall onFollower:follower];
            }
            
            [follower stepInBox:_moverBounds
                     shouldWrap:NO];            
        }else{
            
            [follower step];
            
        }
        
        FollowerGridPosition fPos1 = follower.gridPosition;
        
        BOOL shouldUpdateFitnessOnlyWhenMovedPlot = YES;
        
        // Check how many paths the follower overlaps
        if(!shouldUpdateFitnessOnlyWhenMovedPlot ||
           (fPos0.x != fPos1.x || fPos0.y != fPos1.y || fPos0.z != fPos1.z)){
            
            // The position has changed. Update the trail.
            [_sharedTrail addToHistoryToGridPosition:fPos1];
            
            // NOTE: Do we do this every frame or only when the follower moves?
            int curTrailValue = [_sharedTrail historyAtGridPosition:fPos1];
            
            // Update the fitness
            [follower updateFitnessWithTrailValue:curTrailValue];
            
        }

    }
    
    // Either repeat or continue
    _numUpdates++;
    if(_numUpdates < _updateSpeed){
        [self update];
    }else{
        _numUpdates = 0;
    }
}

- (void)applyWallContact:(WallSide)wallSide onFollower:(NOCFollower *)follower
{
    if(wallSide != WallSideNone){
        
        GLKVector3 vectorCollisionDetection;
        
        switch (wallSide) {
            case WallSideBack:
            case WallSideFront:
                vectorCollisionDetection = GLKVector3Make(0, 0, follower.velocity.z*-2);
                break;
            case WallSideLeft:
            case WallSideRight:
                vectorCollisionDetection = GLKVector3Make(follower.velocity.x*-2, 0, 0);
                break;
            case WallSideTop:
            case WallSideBottom:
                vectorCollisionDetection = GLKVector3Make(0, follower.velocity.y*-2, 0);
                break;
            default:
                break;
        }
        
        [follower applyForce:vectorCollisionDetection];
    }
}

- (WallSide)detectCollisionWithWallsOnFollower:(NOCFollower *)follower
{
    for(int i=0;i<6;i++){
        
        WallSide wallSide = i+1; // NOTE: WallSideNone = 0
        GLKVector3 *surf = NULL;
        
        switch (wallSide) {
            case WallSideBack:
                surf = _surfBackWall;
                break;
            case WallSideFront:
                surf = _surfFrontWall;
                break;
            case WallSideLeft:
                surf = _surfLeftWall;
                break;
            case WallSideRight:
                surf = _surfRightWall;
                break;
            case WallSideTop:
                surf = _surfTopWall;
                break;
            case WallSideBottom:
                surf = _surfBottomWall;
                break;
            case WallSideNone:
                break;
        }
        
        GLKVector3 posOnSurf = [self positionOfFollower:follower
                                              onSurface:surf
                                               numVerts:4];
        
        GLKVector3 vecFromWall = GLKVector3Subtract(follower.position, posOnSurf);
        float distToWall = GLKVector3Length(vecFromWall);
        
        if(distToWall < follower.radius){
            
            return wallSide;
        }
    }
    
    return WallSideNone;
    
}

- (GLKVector3)positionOfFollower:(NOCFollower *)follower onSurface:(GLKVector3[])surf numVerts:(int)numVerts
{
    GLKVector3 originSurf = GLKVector3Zero;
    for(int i=0;i<numVerts;i++){
        originSurf.x += surf[i].x;
        originSurf.y += surf[i].y;
        originSurf.z += surf[i].z;
    }
    originSurf = GLKVector3DivideScalar(originSurf, numVerts);
    
    GLKVector3 n = NOCSurfaceNormalForTriangle(surf[0],surf[1],surf[2]);
    GLKVector3 v = GLKVector3Subtract(follower.position, originSurf);
    float dist = GLKVector3DotProduct(v, n);
    GLKVector3 posOnPlane = GLKVector3Subtract(follower.position, GLKVector3MultiplyScalar(n, dist));
    
    return posOnPlane;
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

    for(NOCFollower *follower in _followers){
        [follower renderHistory:NO];
    }
    
    NOCShaderProgram *shaderFollowers = [self shaderNamed:ShaderNameFollowers];
    [shaderFollowers use];
    
    for(NOCFollower *follower in _followers){
        
        GLKMatrix4 modelMat = [follower modelMatrix];
        GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelMat), NULL);
        GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(matScene, modelMat);
        
        GLfloat beingColor[4];
        [follower glColor:beingColor];
        [shaderFollowers set4DFloatArray:beingColor withNumElements:1 forUniform:UniformColor];
        
        [shaderFollowers setMatrix4:mvpMatrix forUniform:UniformMVProjectionMatrix];
        [shaderFollowers setMatrix3:normalMatrix forUniform:UniformNormalMatrix];
        
        [follower render];
        
    }
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
            [self setupInitialFollowers];
        }
    }
}

@end

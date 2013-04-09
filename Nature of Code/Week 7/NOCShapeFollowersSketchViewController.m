//
//  NOCShapeFollowersSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/31/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCShapeFollowersSketchViewController.h"
#import "NOCShaderProgram.h"
#import "NOCShapeFollower.h"

@interface NOCShapeFollowersSketchViewController ()
{
    
    NOCBox3D _moverBounds;
    NSArray *_followerGroups;
    GLKVector3 _vecNavigation;
    
    int _numBatchFollowers;
    int _numFollowersGroups;
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

static NSString * ShaderNameFollowers = @"Being";
static NSString * ShaderNameSceneBox = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformNormalMatrix = @"normalMatrix";
static NSString * UniformColor = @"color";

@implementation NOCShapeFollowersSketchViewController

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiShapeFollowers";
}

- (void)updateFromSliders
{
    int framesPerUpdate = self.sliderEvolutionRate.value;
    if(framesPerUpdate != _updateSpeed){
        _updateSpeed = framesPerUpdate;
        NSLog(@"_updateSpeed: %i", _updateSpeed);
    }
    
    float mutationRate = self.sliderMutationRate.value * 0.001;
    if(mutationRate != [NOCShapeFollower mutationRate]){
        [NOCShapeFollower setMutationRate:mutationRate];
        NSLog(@"Mutation rate: %f", [NOCShapeFollower mutationRate]);
    }
    
}

#pragma mark - Setup

- (void)setup
{
    _circleRadius = 0.45f;
    
    _updateSpeed = 1;
    _numBatchFollowers = 20;
    _numFollowersGroups = 15;
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
    _generationFrame = 0;
    
    NSMutableArray *followerGroups = [NSMutableArray arrayWithCapacity:_numFollowersGroups];
    
    for(int i=0;i<_numFollowersGroups;i++){
        
        NSMutableArray *followers = [NSMutableArray arrayWithCapacity:_numBatchFollowers];

        for(int j=0;j<_numBatchFollowers;j++){
            [followers addObject:[self randomFollower]];
        }
        
        [followerGroups addObject:[NSArray arrayWithArray:followers]];
    }
    
    _followerGroups = [NSArray arrayWithArray:followerGroups];
    
}

- (NOCBeing *)randomFollower
{
    float randX = (RAND_SCALAR * 1.9) - 0.95f;
    float randY = (RAND_SCALAR * 1.9) - 0.95f;
    float randZ = (RAND_SCALAR * 1.9) - 0.95f;
    GLKVector3 startingPoint = GLKVector3Make(randX, randY, randZ);
    float mass = 1.0f;
    float radius = 0.05;
    NOCShapeFollower *randFollower = [[NOCShapeFollower alloc] initWithRadius:radius
                                                           position:startingPoint
                                                               mass:mass];
    [randFollower randomizeDNA];
    randFollower.generation = 0;

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

    NSMutableArray *newGroups = [NSMutableArray arrayWithCapacity:_numFollowersGroups];
    
    // Find the max fitness so we can normalize
    for(NSArray *followers in _followerGroups){
        
        // NOTE: This gives all of the followers a say
        
        /*

        float maxFitness = ((NOCShapeFollower *)followers[0]).fitness;
        float minFitness = maxFitness;
        for(NOCShapeFollower *f in followers){
            if(f.fitness > maxFitness){
                maxFitness = f.fitness;
            }
            if(f.fitness < minFitness){
                minFitness = f.fitness;
            }
        }
        float fitnessRange = maxFitness - minFitness;
        
        int bucketSize = MAX(_numBatchFollowers * 5, 2); // large number so small fish still have a chance
        NSMutableArray *genePool = [NSMutableArray arrayWithCapacity:bucketSize];
        
        for(NOCShapeFollower *f in followers){
            
            // Normalize all of the fitnesses between 0 and 1
            float normalFitness = (f.fitness-minFitness) / fitnessRange;
            int numInPool = round(bucketSize * normalFitness);
            for(int i=0;i<numInPool;i++){
                [genePool addObject:f];
            }
        }
        
        if(genePool.count == 0){
            // Reuse
            genePool = [NSArray arrayWithArray:followers];
        }
        
        NSMutableArray *newFollowers = [NSMutableArray arrayWithCapacity:_numBatchFollowers];
        
        for(int i=0;i<_numBatchFollowers;i++){
            
            int randIdxA = arc4random() % genePool.count;
            int randIdxB = arc4random() % genePool.count;
            
            NOCShapeFollower *parentA = genePool[randIdxA];
            NOCShapeFollower *parentB = genePool[randIdxB];
            
            NOCShapeFollower *nextGen = (NOCShapeFollower *)[parentA crossover:parentB];

            if(!nextGen){
                NSLog(@"ERROR: Couldn't cross over next gen");
            }else{
                [newFollowers addObject:nextGen];
            }
        }
         
        [newGroups addObject:[NSArray arrayWithArray:newFollowers]];
         
         */
        
        // This approach only breeds the most successful 2.
        // This might be a better approach considering our ability to mutate
        
        NSArray *sortedFollowers = [followers sortedArrayUsingComparator:^NSComparisonResult(NOCShapeFollower *f1, NOCShapeFollower *f2) {
            if(f1.fitness > f2.fitness){
                return  NSOrderedAscending;
            }else{
                return  NSOrderedDescending;
            }
        }];
        
        NSArray *genePool = [sortedFollowers subarrayWithRange:NSMakeRange(0, 2)];
        
        NSMutableArray *newFollowers = [NSMutableArray arrayWithCapacity:_numBatchFollowers];
        for(int i=0;i<_numBatchFollowers;i++){
            
            NOCShapeFollower *parentA = genePool[0];
            NOCShapeFollower *parentB = genePool[1];
            
            NOCShapeFollower *nextGen = (NOCShapeFollower *)[parentA crossover:parentB];
            
            if(!nextGen){
                NSLog(@"ERROR: Couldn't cross over next gen");
            }else{
                [newFollowers addObject:nextGen];
            }
        }
        
        [newGroups addObject:[NSArray arrayWithArray:newFollowers]];

        
    }
    
    _followerGroups = [NSArray arrayWithArray:newGroups];
    
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
                                     [_followerGroups[0][0] generation]];
        
    }else if(_generationFrame == _numFramesPerGeneration-1){
        
        return NO;
        
    }

    for(NSArray *followers in _followerGroups){
        
        for(NOCShapeFollower *follower in followers){
            
            BOOL ShouldConstrain = NO;
            
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
            
            // A simple circle
            float distFromCenter = GLKVector3Distance(follower.position, GLKVector3Zero);
            float distFromClosestSurface = fabsf(_circleRadius - distFromCenter);
            
            // Update the fitness
            [follower updateFitnessWithDistanceToShapeSurface:distFromClosestSurface];
            
        }
    }
    
    return YES;
}

- (void)applyWallContact:(WallSide)wallSide onFollower:(NOCShapeFollower *)follower
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

- (WallSide)detectCollisionWithWallsOnFollower:(NOCShapeFollower *)follower
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

- (GLKVector3)positionOfFollower:(NOCShapeFollower *)follower onSurface:(GLKVector3[])surf numVerts:(int)numVerts
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
    
    // Draw the scene box
    NOCShaderProgram *shaderScene = [self shaderNamed:ShaderNameSceneBox];
    [shaderScene use];
    [shaderScene setMatrix4:_projectionMatrix3D
                 forUniform:UniformMVProjectionMatrix];
    [self drawWalls];

    BOOL drawFittest = self.switchDrawFittestLines.on;
    BOOL drawBodies = self.switchDrawBodies.on;
    BOOL coloredHistory = self.switchRenderColoredHistory.on;

    //glEnable (GL_BLEND);
    //glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    for(NSArray *followers in _followerGroups){
        
        NOCShapeFollower *fittestFollower = followers[0];
        
        for(NOCShapeFollower *follower in followers){

            if(drawFittest){
                if(follower.fitness > fittestFollower.fitness){
                    fittestFollower = follower;
                }
            }else{
                [follower renderHistory:coloredHistory];
            }
        }
        
        if(drawFittest){
            [fittestFollower renderHistory:coloredHistory];
        }
        
    }
    //glDisable(GL_BLEND);
    
    if(drawBodies){
        
        NOCShaderProgram *shaderFollowers = [self shaderNamed:ShaderNameFollowers];
        
        [shaderFollowers use];
        
        for(NSArray *followers in _followerGroups){
            
            NOCShapeFollower *fittestFollower = followers[0];
            
            for(NOCShapeFollower *follower in followers){
                
                if(drawFittest){
                    if(follower.fitness > fittestFollower.fitness){
                        fittestFollower = follower;
                    }
                }else{
                    [self renderFollower:follower inScene:_projectionMatrix3D withShader:shaderFollowers];
                }
            }
            
            if(drawFittest){
                [self renderFollower:fittestFollower inScene:_projectionMatrix3D withShader:shaderFollowers];
            }
        }        
    }
}
    
- (void)renderFollower:(NOCShapeFollower *)follower
               inScene:(GLKMatrix4)matScene
            withShader:(NOCShaderProgram *)shader
{
    GLKMatrix4 modelMat = [follower modelMatrix];
    GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelMat), NULL);
    GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(matScene, modelMat);
    
    GLfloat beingColor[4];
    [follower glColor:beingColor];
    [shader set4DFloatArray:beingColor withNumElements:1 forUniform:UniformColor];
    
    [shader setMatrix4:mvpMatrix forUniform:UniformMVProjectionMatrix];
    [shader setMatrix3:normalMatrix forUniform:UniformNormalMatrix];
    
    [follower render];
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

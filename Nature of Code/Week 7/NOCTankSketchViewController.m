//
//  NOCTankSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTankSketchViewController.h"
#import "NOCSceneBox.h"
#import "NOCShaderProgram.h"
#import "NOCBeing.h"

@interface NOC3DSketchViewController(Private)

- (void)rotateQuaternionWithVector:(CGPoint)delta;

@end

@interface NOCTankSketchViewController ()
{
    NOCBox3D _moverBounds;
    NSMutableArray *_beings;
    NSMutableArray *_deadBeings;
    NSMutableArray *_frameChildren;
    GLKVector3 _vecNavigation;
    BOOL _wallContact[6];
    
    GLKVector3 _surfBottomWall[4];
    GLKVector3 _surfTopWall[4];
    GLKVector3 _surfBackWall[4];
    GLKVector3 _surfFrontWall[4];
    GLKVector3 _surfRightWall[4];
    GLKVector3 _surfLeftWall[4];
    
}
@end

@implementation NOCTankSketchViewController

static NSString * ShaderNameBeings = @"Being";
static NSString * ShaderNameSceneBox = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformNormalMatrix = @"normalMatrix";
static NSString * UniformColor = @"color";

#pragma mark - Setup

- (void)setup
{    
    NOCShaderProgram *shaderSceneBox = [[NOCShaderProgram alloc] initWithName:ShaderNameSceneBox];
    shaderSceneBox.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                   @"color" : @(GLKVertexAttribColor), };
    shaderSceneBox.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shaderSceneBox named:ShaderNameSceneBox];
    
    NOCShaderProgram *shaderBeings = [[NOCShaderProgram alloc] initWithName:ShaderNameBeings];
    shaderBeings.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                 @"normal" : @(GLKVertexAttribNormal)};//,
                                 //@"color" : @(GLKVertexAttribColor) };
    shaderBeings.uniformNames = @[ UniformMVProjectionMatrix, UniformNormalMatrix, UniformColor ];
    [self addShader:shaderBeings named:ShaderNameBeings];

    
    self.isArcballEnabled = NO;
    self.isGestureNavigationEnabled = YES;
    
    [self setupInitialBeings];
    
    glEnable(GL_DEPTH_TEST);
      
    [NOCBeing calculateGeometry];

}

- (void)setupInitialBeings
{
    _beings = [NSMutableArray arrayWithCapacity:MaxBeingLifespan];
    _deadBeings = [NSMutableArray arrayWithCapacity:MaxBeingLifespan];
    
    const static int SeedCount = 25;
    for(int i=0;i<SeedCount;i++){
        [_beings addObject:[self randomBeing]];
    }
}

- (NOCBeing *)randomBeing
{
    float randX = (RAND_SCALAR * 1.9) - 0.95f;
    float randY = (RAND_SCALAR * 1.9) - 0.95f;
    float randZ = (RAND_SCALAR * 1.9) - 0.95f;
    GLKVector3 startingPoint = GLKVector3Make(randX, randY, randZ);
    float mass = 1.0f;
    float radius = 0.05;
    NOCBeing *randBeing = [[NOCBeing alloc] initWithRadius:radius
                                                  position:startingPoint
                                                      mass:mass];
    [randBeing randomizeDNA];
    randBeing.generation = 0;
    return randBeing;
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

- (void)update
{
    [super update];
    
    for(int i=0;i<6;i++){
        _wallContact[i] = NO;
    }
    
    NSMutableArray *deadBeings = [NSMutableArray arrayWithCapacity:_beings.count];
    _frameChildren = [NSMutableArray arrayWithCapacity:_beings.count];
    
    for(NOCBeing *being in _beings){
        
        if([being isDead]){
            
            [deadBeings addObject:being];
            
        }else{
            
            being.wallContact = WallSideNone;
            
            GLKVector3 force = [self worldForceOnBeing:being];
            [being applyForce:force];
            WallSide contactWall = [self detectCollisionWithWallsOnBeing:being];
            if(contactWall != WallSideNone){
                being.numWallCollisions += 1;
            
                // NOTE: We're storing the wall contact in the being
                // so we can later use it to draw the contact point.
                // It's probably not the greatest OO design to have this world
                // knowledge in the being, but it makes data management
                // easier.
                being.wallContact = contactWall;
                [self applyWallContact:contactWall onBeing:being];
            }
            
            [being stepInBox:_moverBounds
                  shouldWrap:NO];
            
        }
    }

    // Remove dead beings
    [_deadBeings addObjectsFromArray:deadBeings];
    [_beings removeObjectsInArray:deadBeings];
    
    // Add new beings
    [_beings addObjectsFromArray:_frameChildren];

}

- (GLKVector3)worldForceOnBeing:(NOCBeing *)being
{
    GLKVector3 vecReaction = GLKVector3Zero;
    
    if([being canProcreate]){
        
        for(NOCBeing *beingOther in _beings){
            
            // NOTE: Only allowing beings of the same generation to procreate
            BOOL isAncestor = beingOther.generation < being.generation;
            
            if([beingOther canProcreate] && !isAncestor){
                
                if(beingOther != being && ![beingOther isDead]){
                    
                    GLKVector3 vecDir = GLKVector3Subtract(being.position, beingOther.position);
                    float distance = GLKVector3Length(vecDir);
                    float distContact = being.radius + beingOther.radius;

                    if(distance < distContact){
                        NOCBeing *b = [being presentOpportunityToProcreateWithMate:beingOther];
                        if(b){
                            [_frameChildren addObject:b];
                            // A being can only have 1 baby per frame
                            break;
                        }
                    }
                }
            }
        }
    }

    return vecReaction;
}


- (void)applyWallContact:(WallSide)wallSide onBeing:(NOCBeing *)being
{
    if(wallSide != WallSideNone){
        
        GLKVector3 vectorCollisionDetection;
        
        switch (wallSide) {
            case WallSideBack:
            case WallSideFront:
                vectorCollisionDetection = GLKVector3Make(0, 0, being.velocity.z*-2);
                break;
            case WallSideLeft:
            case WallSideRight:
                vectorCollisionDetection = GLKVector3Make(being.velocity.x*-2, 0, 0);
                break;
            case WallSideTop:
            case WallSideBottom:
                vectorCollisionDetection = GLKVector3Make(0, being.velocity.y*-2, 0);
                break;
            default:
                break;
        }
        
        [being applyForce:vectorCollisionDetection];
    }
}

- (WallSide)detectCollisionWithWallsOnBeing:(NOCBeing *)being
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
        
        GLKVector3 posOnSurf = [self positionOfBeing:being
                                           onSurface:surf
                                            numVerts:4];
        
        GLKVector3 vecFromWall = GLKVector3Subtract(being.position, posOnSurf);
        float distToWall = GLKVector3Length(vecFromWall);
        
        if(distToWall < being.radius){
            
            _wallContact[i] = YES;
            return wallSide;
        }
    }
    
    return WallSideNone;
    
}

- (GLKVector3)positionOfBeing:(NOCBeing *)being onSurface:(GLKVector3[])surf numVerts:(int)numVerts
{
    GLKVector3 originSurf = GLKVector3Zero;
    for(int i=0;i<numVerts;i++){
        originSurf.x += surf[i].x;
        originSurf.y += surf[i].y;
        originSurf.z += surf[i].z;
    }
    originSurf = GLKVector3DivideScalar(originSurf, numVerts);
    
    GLKVector3 n = NOCSurfaceNormalForTriangle(surf[0],surf[1],surf[2]);
    
    // 1) Make a vector from your orig point to the point of interest:
    // v = point-orig (in each dimension);
    GLKVector3 v = GLKVector3Subtract(being.position, originSurf);
    
    // 2) Take the dot product of that vector with the normal vector n:
    // dist = vx*nx + vy*ny + vz*nz; dist = scalar distance from point to plane along the normal
    float dist = GLKVector3DotProduct(v, n);
    
    // 3) Multiply the normal vector by the distance, and subtract that vector from your point.
    // projected_point = point - dist*normal;
    GLKVector3 posOnPlane = GLKVector3Subtract(being.position, GLKVector3MultiplyScalar(n, dist));

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
    
    // Draw any contact points
    
    for(NOCBeing *being in _deadBeings) {
        
        [being renderHistory];
        
    }
    
    for(NOCBeing *being in _beings){
        
        [being renderHistory];

        /*
        switch (being.wallContact) {
            case WallSideNone:
                break;
            case WallSideTop:
                [self drawBeingPosition:being
                                 onWall:_surfTopWall
                              numCoords:4
                               axisMask:GLKVector3Make(1, 0, 1)];
                break;
            case WallSideBottom:
                [self drawBeingPosition:being
                                 onWall:_surfBottomWall
                              numCoords:4
                               axisMask:GLKVector3Make(1, 0, 1)];
                break;
            case WallSideFront:
                [self drawBeingPosition:being
                                 onWall:_surfFrontWall
                              numCoords:4
                               axisMask:GLKVector3Make(1, 1, 0)];
                break;
            case WallSideBack:
                [self drawBeingPosition:being
                                 onWall:_surfBackWall
                              numCoords:4
                               axisMask:GLKVector3Make(1, 1, 0)];
                break;
            case WallSideLeft:
                [self drawBeingPosition:being
                                 onWall:_surfLeftWall
                              numCoords:4
                               axisMask:GLKVector3Make(0, 1, 1)];
                break;
            case WallSideRight:
                [self drawBeingPosition:being
                                 onWall:_surfRightWall
                              numCoords:4
                               axisMask:GLKVector3Make(0, 1, 1)];
                break;
        }*/
    }

    NOCShaderProgram *shaderBeings = [self shaderNamed:ShaderNameBeings];
    [shaderBeings use];

    for (NOCBeing *being in _beings){
        
        GLKMatrix4 modelMat = [being modelMatrix];
        GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelMat), NULL);
        GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(matScene, modelMat);
        
        GLfloat beingColor[4];
        [being glColor:beingColor];
        [shaderBeings set4DFloatArray:beingColor withNumElements:1 forUniform:UniformColor];
        
        [shaderBeings setMatrix4:mvpMatrix forUniform:UniformMVProjectionMatrix];
        [shaderBeings setMatrix3:normalMatrix forUniform:UniformNormalMatrix];

        [being render];

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
        
        BOOL isWhite = YES;// !_wallContact[i];
        GLfloat wallColor[5*4];
        GLfloat wallVerts[5*3];
        
        for(int j=0;j<5;j++){
            
            wallColor[j*4+0] = 1.0f;
            wallColor[j*4+1] = 1.0f * isWhite;
            wallColor[j*4+2] = 1.0f * isWhite;
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

- (void)drawBeingPosition:(NOCBeing *)being
                   onWall:(GLKVector3[])surf
                numCoords:(int)numSurfVerts
                 axisMask:(GLKVector3)mask
{
    
    GLKVector3 posOnSurf = [self positionOfBeing:being onSurface:surf numVerts:numSurfVerts];
    
    GLfloat color[5*4];
    
    for(int j=0;j<5;j++){
        color[j*4+0] = 0.5f;
        color[j*4+1] = 0.5f;
        color[j*4+2] = 0.5f;
        color[j*4+3] = 1.0f;
    }

    GLfloat collisionVerts[] = {
        posOnSurf.x + surf[0].x * being.radius * mask.x,
        posOnSurf.y + surf[0].y * being.radius * mask.y,
        posOnSurf.z + surf[0].z * being.radius * mask.z,
        
        posOnSurf.x + surf[1].x * being.radius * mask.x,
        posOnSurf.y + surf[1].y * being.radius * mask.y,
        posOnSurf.z + surf[1].z * being.radius * mask.z,
        
        posOnSurf.x + surf[2].x * being.radius * mask.x,
        posOnSurf.y + surf[2].y * being.radius * mask.y,
        posOnSurf.z + surf[2].z * being.radius * mask.z,
        
        posOnSurf.x + surf[3].x * being.radius * mask.x,
        posOnSurf.y + surf[3].y * being.radius * mask.y,
        posOnSurf.z + surf[3].z * being.radius * mask.z,
        
        posOnSurf.x + surf[0].x * being.radius * mask.x,
        posOnSurf.y + surf[0].y * being.radius * mask.y,
        posOnSurf.z + surf[0].z * being.radius * mask.z,
    };
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &collisionVerts);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &color);
    glDrawArrays(GL_LINE_LOOP, 0, 5);
    //glDrawArrays(GL_TRIANGLE_STRIP, 0, 5);

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
            // reset
            [self setupInitialBeings];
        }
    }
}

@end

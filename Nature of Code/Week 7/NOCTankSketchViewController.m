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

@interface NOCTankSketchViewController ()
{
    NOCSceneBox *_sceneBox;
    NSMutableArray *_beings;
}
@end

@implementation NOCTankSketchViewController

static NSString * ShaderNameBeings = @"SampleShader";
static NSString * ShaderNameSceneBox = @"SceneBox";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformNormalMatrix = @"normalMatrix";

#pragma mark - Setup

- (void)setup
{
    NOCShaderProgram *shaderBeings = [[NOCShaderProgram alloc] initWithName:ShaderNameBeings];
    shaderBeings.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                 @"normal" : @(GLKVertexAttribNormal) };
    shaderBeings.uniformNames = @[ UniformMVProjectionMatrix, UniformNormalMatrix ];
    [self addShader:shaderBeings named:ShaderNameBeings];


    NOCShaderProgram *shaderSceneBox = [[NOCShaderProgram alloc] initWithName:ShaderNameSceneBox];
    shaderSceneBox.attributes = @{ @"position" : @(GLKVertexAttribPosition) };
    shaderSceneBox.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shaderSceneBox named:ShaderNameSceneBox];
    
    _sceneBox = [[NOCSceneBox alloc] initWithAspect:_viewAspect];
    
    self.isArcballEnabled = NO;
    self.isGestureNavigationEnabled = YES;
    
    [self setupInitialBeings];
    
    glEnable(GL_DEPTH_TEST);

}

- (void)setupInitialBeings
{
    int numInitialBeings = 10;
    _beings = [NSMutableArray arrayWithCapacity:numInitialBeings];
    
    for(int i=0;i<numInitialBeings;i++){
        float randX = (RAND_SCALAR * 1.0) - 0.5f;
        float randY = (RAND_SCALAR * 1.0) - 0.5f;
        float randZ = (RAND_SCALAR * 1.0) - 0.5f;
        GLKVector3 startingPoint = GLKVector3Make(randX, randY, randZ);
        [self addBeingAtPoint:startingPoint];
    }
}

- (void)addBeingAtPoint:(GLKVector3)point
{
    float mass = 1.0f;
    float radius = 0.2;
    NOCBeing *being = [[NOCBeing alloc] initWithRadius:radius
                                              position:point
                                                  mass:mass];
    [_beings addObject:being];    
}

#pragma mark - Loop

- (void)resize
{
    [super resize];
    [_sceneBox resizeWithAspect:_viewAspect];
}

- (void)update
{
    [super update];
    
    float sceneWidth = 2.0f;
    float sceneHeight = 2.0f/_viewAspect;
    float sceneDepth = 2.0f;
    
    NOCBox3D moverBounds = NOCBox3DMake(-1,
                                        -1 / _viewAspect,
                                        -1,
                                        sceneWidth,
                                        sceneHeight,
                                        sceneDepth);
    
    for(NOCBeing *being in _beings){
        GLKVector3 force = [self worldForceOnBeing:being];
        [being applyForce:force];
        [being stepInBox:moverBounds
              shouldWrap:YES];
    }
}

- (GLKVector3)worldForceOnBeing:(NOCBeing *)being
{
    GLKVector3 vecReaction = GLKVector3Zero;
    
    for(NOCBeing *beingOther in _beings){
        
        if(beingOther != being){
            
            GLKVector3 vecDir = GLKVector3Subtract(being.position, beingOther.position);
            float distance = GLKVector3Length(vecDir);
            GLKVector3 vecNormal = GLKVector3Normalize(vecDir);
            
            // If they share a position, make some nominal delta
            if(distance <= 0){
                distance = 0.001;
                vecNormal = GLKVector3Random();
            }
            
            float distContact = being.radius + beingOther.radius;
            float magnitudeMoverForce = 0;
            if(distance < distContact){
                // They overlap. Move them apart.
                magnitudeMoverForce = distance - distContact;
            }

            GLKVector3 vecMoverForce = GLKVector3MultiplyScalar(vecNormal, magnitudeMoverForce);
            vecReaction = GLKVector3Subtract(vecReaction, vecMoverForce);

        }
    }
    
    if(!GLKVector3Equal(vecReaction, GLKVector3Zero)){
        vecReaction = GLKVector3Normalize(vecReaction);
    }
    
    float movementScale = 0.001;
    vecReaction = GLKVector3MultiplyScalar(vecReaction, movementScale);

    return vecReaction;
}

// TODO: Move this
GLKVector3 SurfaceNormalForTriangle(GLKVector3 ptA, GLKVector3 ptB, GLKVector3 ptC)
{
    GLKVector3 vector1 = GLKVector3Subtract(ptB,ptA);
    GLKVector3 vector2 = GLKVector3Subtract(ptC,ptA);
    GLKVector3Normalize(GLKVector3CrossProduct(vector1, vector2));
    return GLKVector3Normalize(GLKVector3CrossProduct(vector1, vector2));
}


// TMP
- (void)drawPositionsOnWall:(GLKVector3[])surf numCoords:(int)numSurfCoords displayMulti:(GLKVector3)multi
{
    GLKVector3 originSurf = GLKVector3Zero;
    for(int i=0;i<numSurfCoords;i++){
        originSurf.x += surf[i].x;
        originSurf.y += surf[i].y;
        originSurf.z += surf[i].z;
    }
    originSurf = GLKVector3DivideScalar(originSurf, numSurfCoords);
    
    GLKVector3 n = SurfaceNormalForTriangle(surf[0],surf[1],surf[2]);
    
    for(NOCBeing *being in _beings){

        // 1) Make a vector from your orig point to the point of interest:
        // v = point-orig (in each dimension);
        GLKVector3 v = GLKVector3Subtract(being.position, originSurf);

        // 2) Take the dot product of that vector with the normal vector n:
        // dist = vx*nx + vy*ny + vz*nz; dist = scalar distance from point to plane along the normal
        float dist = GLKVector3DotProduct(v, n);

        // 3) Multiply the normal vector by the distance, and subtract that vector from your point.
        // projected_point = point - dist*normal;
        GLKVector3 posOnPlane = GLKVector3Subtract(being.position, GLKVector3MultiplyScalar(n, dist));

        GLKVector3 vecFromWall = GLKVector3Subtract(being.position, posOnPlane);
        float distToWall = GLKVector3Length(vecFromWall);
        // TODO: Check if this is the same as dist
        GLKVector3 vecWallNormal = GLKVector3Normalize(vecFromWall);

        // Lets draw a bunch of boxes on the plane
        
        GLfloat collisionVerts[] = {
            posOnPlane.x + surf[0].x * being.radius * multi.x,
            posOnPlane.y + surf[0].y * being.radius * multi.y,
            posOnPlane.z + surf[0].z * being.radius * multi.z,

            posOnPlane.x + surf[1].x * being.radius * multi.x,
            posOnPlane.y + surf[1].y * being.radius * multi.y,
            posOnPlane.z + surf[1].z * being.radius * multi.z,

            posOnPlane.x + surf[2].x * being.radius * multi.x,
            posOnPlane.y + surf[2].y * being.radius * multi.y,
            posOnPlane.z + surf[2].z * being.radius * multi.z,

            posOnPlane.x + surf[3].x * being.radius * multi.x,
            posOnPlane.y + surf[3].y * being.radius * multi.y,
            posOnPlane.z + surf[3].z * being.radius * multi.z,

            posOnPlane.x + surf[0].x * being.radius * multi.x,
            posOnPlane.y + surf[0].y * being.radius * multi.y,
            posOnPlane.z + surf[0].z * being.radius * multi.z,

        };
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &collisionVerts);
        glDrawArrays(GL_LINE_LOOP, 0, 5);

    }
    
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
    [_sceneBox render];
    
    // TODO
    // Let's also do some collision detection with the tank walls
    
    // For the moment, we'll just draw their positions on the wall
    // Left Wall
    float height = 1.0 / _viewAspect;
    GLKVector3 surfLeftWall[] = {
        GLKVector3Make(-1, -1*height, -1),
        GLKVector3Make(-1, 1*height, -1),
        GLKVector3Make(-1, 1*height, 1),
        GLKVector3Make(-1, -1*height, 1),
    };
    GLKVector3 surfRightWall[] = {
        GLKVector3Make(1, -1*height, -1),
        GLKVector3Make(1, 1*height, -1),
        GLKVector3Make(1, 1*height, 1),
        GLKVector3Make(1, -1*height, 1),
    };
    GLKVector3 surfFrontWall[] = {
        GLKVector3Make(-1, -1*height, -1),
        GLKVector3Make(-1, 1*height, -1),
        GLKVector3Make(1, 1*height, -1),
        GLKVector3Make(1, -1*height, -1),
    };
    GLKVector3 surfBackWall[] = {
        GLKVector3Make(-1, -1*height, 1),
        GLKVector3Make(-1, 1*height, 1),
        GLKVector3Make(1, 1*height, 1),
        GLKVector3Make(1, -1*height, 1),
    };
    GLKVector3 surfTopWall[] = {
        GLKVector3Make(-1, 1*height, -1),
        GLKVector3Make(1, 1*height, -1),
        GLKVector3Make(1, 1*height, 1),
        GLKVector3Make(-1, 1*height, 1),
    };
    GLKVector3 surfBottomWall[] = {
        GLKVector3Make(-1, -1*height, -1),
        GLKVector3Make(1, -1*height, -1),
        GLKVector3Make(1, -1*height, 1),
        GLKVector3Make(-1, -1*height, 1),
    };
    [self drawPositionsOnWall:surfLeftWall numCoords:4 displayMulti:GLKVector3Make(0, 1, 1)];
    [self drawPositionsOnWall:surfRightWall numCoords:4 displayMulti:GLKVector3Make(0, 1, 1)];
    [self drawPositionsOnWall:surfFrontWall numCoords:4 displayMulti:GLKVector3Make(1, 1, 0)];
    [self drawPositionsOnWall:surfBackWall numCoords:4 displayMulti:GLKVector3Make(1, 1, 0)];
    [self drawPositionsOnWall:surfTopWall numCoords:4 displayMulti:GLKVector3Make(1, 0, 1)];
    [self drawPositionsOnWall:surfBottomWall numCoords:4 displayMulti:GLKVector3Make(1, 0, 1)];
    
    NOCShaderProgram *shaderBeings = [self shaderNamed:ShaderNameBeings];
    [shaderBeings use];
    
    for (NOCBeing *being in _beings){
        
        GLKMatrix4 modelMat = [being modelMatrix];
        GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelMat), NULL);
        GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(matScene, modelMat);
        
        [shaderBeings setMatrix4:mvpMatrix forUniform:UniformMVProjectionMatrix];
        [shaderBeings setMatrix3:normalMatrix forUniform:UniformNormalMatrix];
        
        [being render];
    }
}

- (void)teardown
{
    //...
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    for(UITouch *t in touches){
        if(t.tapCount > 0){
            // reset
            [self setupInitialBeings];
        }
    }
}

@end

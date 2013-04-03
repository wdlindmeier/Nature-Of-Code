//
//  NOCBeing.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCMover3D.h"

const static int MaxBeingLifespan = 500;
const static int MinFramesBetweenProcreation = 30;
const static int BeingSphereSegments = 16;//32;
const static int BeingNumBodyVerts = (BeingSphereSegments+1)*2*3*(BeingSphereSegments / 2);
const static int BeingNumBodyNormals = (BeingSphereSegments+1)*2*3*(BeingSphereSegments / 2);
const static int BeingNumDataVerts = BeingNumBodyVerts+BeingNumBodyNormals;
const static int BeingNumRenderVerts = (BeingSphereSegments + 1)*2*(BeingSphereSegments / 2);
static GLfloat __unused BeingBodyVerts[BeingNumBodyVerts];
static GLfloat __unused BeingBodyNormals[BeingNumBodyNormals];
static GLfloat __unused BeingBodyTexCoords[(BeingSphereSegments+1)*2*2*(BeingSphereSegments / 2)];
static GLfloat __unused BeingBodyDrawBuffer[BeingNumDataVerts];

@interface NOCBeing : NOCMover3D
{
    GLKVector3 _startingPosition;
}

// NOTE: We'll treat beings as spheres, so "size" doesn't really apply
- (id)initWithRadius:(float)radius
            position:(GLKVector3)position
                mass:(float)mass;

@property (nonatomic, assign) float radius;
@property (nonatomic, assign) float fitness;
@property (nonatomic, readonly) float distTravelled;
@property (nonatomic, readonly) int framesAlive;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) int numWallCollisions;
@property (nonatomic, readonly) int numChildren;
@property (nonatomic, readonly) GLKVector3 startingPosition;
@property (nonatomic, readonly) BOOL isDead;
@property (nonatomic, readonly) GLKVector3 *vectors;
@property (nonatomic, readonly) GLKVector3 *positionHistory;
@property (nonatomic, assign) int generation;
@property (nonatomic, assign) WallSide wallContact;

- (void)mutate;
- (BOOL)canProcreate;
- (void)didProcreate;
- (NOCBeing *)presentOpportunityToProcreateWithMate:(NOCBeing *)mate;
- (NOCBeing *)crossover:(NOCBeing *)mate;
- (void)randomizeDNA;
- (void)glColor:(GLfloat *)components;
- (void)renderHistory:(BOOL)colored;

+ (void)calculateGeometry;
+ (float)mutationRate;
+ (void)setMutationRate:(float)newRate;

@end

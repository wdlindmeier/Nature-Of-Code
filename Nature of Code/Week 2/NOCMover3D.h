//
//  NOCMover3D.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCParticle3D.h"
#import "NOCPositionedMass.h"
#import "NOCOpenGLTypes.h"

@interface NOCMover3D : NOCParticle3D <NOCPositionedMass3D>

@property (nonatomic, assign) GLKVector3 velocity;
@property (nonatomic, assign) GLKVector3 acceleration;
@property (nonatomic, assign) float mass;
@property (nonatomic, assign) float maxVelocity;

- (id)initWithSize:(GLKVector3)size position:(GLKVector3)position mass:(float)mass;
- (void)stepInBox:(NOCBox3D)box shouldWrap:(BOOL)shouldWrap;
- (void)applyForce:(GLKVector3)vecForce;

@end

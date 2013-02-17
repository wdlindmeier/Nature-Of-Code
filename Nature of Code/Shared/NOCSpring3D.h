//
//  NOCSpring3D.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/17/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@class NOCMover3D;

@interface NOCSpring3D : NSObject

@property (nonatomic, assign) GLKVector3 anchor;
@property (nonatomic, assign) float minLength;
@property (nonatomic, assign) float restLength;
@property (nonatomic, assign) float maxLength;
@property (nonatomic, assign) float springiness;
@property (nonatomic, assign) float dampening; // Dampening should be less than 0 (e.g. -0.05)

- (id)initWithAnchor:(GLKVector3)anchor restLength:(float)restLength;
- (void)applySpringToMover:(NOCMover3D *)mover;
- (void)constrainMover:(NOCMover3D *)mover;
- (void)renderToMover:(NOCMover3D *)mover;

@end

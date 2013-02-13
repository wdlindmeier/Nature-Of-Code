//
//  NOCPositionedMass.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/12/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@protocol NOCMassiveObject <NSObject>

@property (nonatomic, assign) float mass;

@end

@protocol NOCPositionedMass2D <NOCMassiveObject>

@property (nonatomic, assign) GLKVector2 position;

- (GLKVector2)forceOnPositionedMass:(id<NOCPositionedMass2D>)positionedMass;

@end

@protocol NOCPositionedMass3D <NOCMassiveObject>

@property (nonatomic, assign) GLKVector3 position;

- (GLKVector3)forceOnPositionedMass:(id<NOCPositionedMass3D>)positionedMass;

@end

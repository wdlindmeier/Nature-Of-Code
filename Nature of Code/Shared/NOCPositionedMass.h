//
//  NOCPositionedMass.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/12/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@protocol NOCPositionedMass <NSObject>

@property (nonatomic, assign) float mass;
@property (nonatomic, assign) GLKVector2 position;

- (GLKVector2)forceOnPositionedMass:(id<NOCPositionedMass>)positionedMass;

@end

//
//  NOCBeing.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCMover3D.h"

@interface NOCBeing : NOCMover3D

// NOTE: We'll treat beings as spheres, so "size" doesn't really apply
- (id)initWithRadius:(float)radius position:(GLKVector3)position mass:(float)mass;

@property (nonatomic, assign) float radius;

@end

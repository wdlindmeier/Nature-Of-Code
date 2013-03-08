//
//  NOCSpring3D.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSpring.h"

@interface NOCSpring3D : NOCSpring

- (id)initWithParicle:(NOCParticle *)p
               anchor:(GLKVector3)anchor
           restLength:(float)restLength;

@property (nonatomic, assign) GLKVector3 anchor;

@end

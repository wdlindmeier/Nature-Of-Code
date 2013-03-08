//
//  NOCSpring2D.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSpring.h"

@interface NOCSpring2D : NOCSpring

- (id)initWithParicle:(NOCParticle *)p
               anchor:(GLKVector2)anchor
           restLength:(float)restLength;

@property (nonatomic, assign) GLKVector2 anchor;

@end

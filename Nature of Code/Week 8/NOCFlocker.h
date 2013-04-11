//
//  NOCFlocker.h
//  Nature of Code
//
//  Created by William Lindmeier on 4/10/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCCubeMover.h"

@class NOCOBJ;

@interface NOCFlocker : NOCMover3D


@property (nonatomic, strong) NOCOBJ *objBody;
@property (nonatomic, strong) UIColor *color;

- (id)initWithSize:(GLKVector3)size
          position:(GLKVector3)position
              mass:(float)mass
              body:(NOCOBJ *)objBody;
- (void)renderHistory;
- (void)glColor:(GLfloat *)components;

@end

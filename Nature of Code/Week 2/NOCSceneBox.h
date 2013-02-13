//
//  NOCSceneBox.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NOCSceneBox : NSObject

- (id)initWithAspect:(float)aspect;
- (void)resizeWithAspect:(float)aspect;
- (void)render;

@end

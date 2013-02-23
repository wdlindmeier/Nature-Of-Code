//
//  NOCParticle.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface NOCParticle : NSObject

@property (nonatomic, assign) int stepCount;
@property (nonatomic, assign) int stepLimit;

- (GLKMatrix4)modelMatrix;
- (void)render;
- (void)step;
- (BOOL)isDead;

@end

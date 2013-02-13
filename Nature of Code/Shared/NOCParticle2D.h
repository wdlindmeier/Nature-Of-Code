//
//  NOCParticle.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface NOCParticle2D : NSObject

@property (nonatomic, assign) GLKVector2 position;
@property (nonatomic, assign) GLKVector2 size;

- (id)initWithSize:(GLKVector2)size position:(GLKVector2)position;
- (GLKMatrix4)modelMatrix;
- (void)render;

@end


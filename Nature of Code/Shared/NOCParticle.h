//
//  NOCParticle.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface NOCParticle : NSObject

@property (nonatomic, assign) GLKVector2 position;
@property (nonatomic, assign) CGSize size;

- (id)initWithSize:(CGSize)size position:(GLKVector2)position;
- (GLKMatrix4)modelMatrixForPixelUnit:(float)pxUnit;
- (void)render;

@end


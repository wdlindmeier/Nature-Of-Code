//
//  NOCWalker.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface NOCWalker : NSObject

@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGSize size;

- (id)initWithSize:(CGSize)size position:(CGPoint)position;
- (void)stepInRect:(CGRect)rect;
- (void)render;
- (GLKMatrix4)modelMatrixForPixelUnit:(float)pxUnit;

@end

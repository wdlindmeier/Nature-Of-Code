//
//  NOCFlowField.h
//  Nature of Code
//
//  Created by William Lindmeier on 4/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NOCFlowField : NSObject

@property (nonatomic, readonly) CGSize dimensions;

- (id)initWithWidth:(int)width height:(int)height;
- (void)generatePerlinWithAlpha:(float)alpha beta:(float)beta step:(float)magnitude;
- (GLKVector3)vectorAtX:(int)x y:(int)y;
- (GLKVector3)vectorAtIndex:(int)index;
- (void)setVector:(GLKVector3)vec atX:(int)x y:(int)y;
- (void)setVector:(GLKVector3)vec atIndex:(int)index;
- (void)renderInRect:(CGRect)rect lineWidth:(float)width weighted:(BOOL)isWeighted;
- (void)advance;

@end

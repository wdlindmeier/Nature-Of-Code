//
//  NOCSceneBox.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NOCSceneBox : NSObject

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *colorLeft;
@property (nonatomic, strong) UIColor *colorRight;
@property (nonatomic, strong) UIColor *colorTop;
@property (nonatomic, strong) UIColor *colorBottom;
@property (nonatomic, strong) UIColor *colorFront;
@property (nonatomic, strong) UIColor *colorBack;

- (id)initWithAspect:(float)aspect;
- (void)resizeWithAspect:(float)aspect;
- (void)render;
- (void)renderColoredWallsWithEdgeOffset:(float)offset;

@end

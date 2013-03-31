//
//  NOCUIKitHelpers.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UINavigationController (Interface)
@end

@interface UIImage (NOCHelpers)

+ (UIImage *)perlinMapOfSize:(CGSize)imgSize
                       alpha:(double)a
                        beta:(double)b
                     octaves:(int)octs
                      minVal:(int)minBrightness
                      maxVal:(int)maxBrightness;

+ (UIImage *)imageWithBuffer:(GLubyte *)buffer
                      ofSize:(CGSize)size;

@end


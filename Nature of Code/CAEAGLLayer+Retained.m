//
//  CAEAGLLayer+Retained.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/3/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "CAEAGLLayer+Retained.h"

#import <QuartzCore/QuartzCore.h>

@implementation CAEAGLLayer (Retained)

- (NSDictionary*) drawableProperties
{
    return @{kEAGLDrawablePropertyRetainedBacking : @(YES)};
}

@end

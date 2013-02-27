//
//  CAEAGLLayer+Retained.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/3/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "CAEAGLLayer+Retained.h"
#import <QuartzCore/QuartzCore.h>

// This is a bit hacky, but it lets us retain the screen buffer without flickering
// when the context isn't cleared
@implementation CAEAGLLayer (Retained)

- (NSDictionary*) drawableProperties
{
    return @{kEAGLDrawablePropertyRetainedBacking : @(YES)};
}
 
@end

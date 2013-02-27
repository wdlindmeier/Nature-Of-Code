//
//  NOCWalkerSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC2DSketchViewController.h"

@interface NOC2DSketchViewController ()

@end

@implementation NOC2DSketchViewController

- (void)resize
{
    [super resize];
    
    // Setup the 2D projection matrix that fits the screen.
    // We want a 1x1 object to be square rather than share the aspect of the screen.
    _projectionMatrix2D = GLKMatrix4MakeScale(1, 1 * _viewAspect, 1);
}

@end

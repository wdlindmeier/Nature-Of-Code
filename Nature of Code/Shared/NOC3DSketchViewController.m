//
//  NOC3DSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC3DSketchViewController.h"

@interface NOC3DSketchViewController ()

@end

@implementation NOC3DSketchViewController


- (void)resize
{
    [super resize];
    
    // Setup the 3D projection matrix that fits the screen.
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    _projectionMatrix3D = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
}

@end

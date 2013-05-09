//
//  NOCWalkerSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSketchViewController.h"
#ifdef USE_SKETCH_CONTROLS
#import "NOCControlsSketchViewController.h"
#endif
#import <GLKit/GLKit.h>

@interface NOC2DSketchViewController : NOCSketchViewControllerBase
{
    GLKMatrix4 _projectionMatrix2D;
}

@end

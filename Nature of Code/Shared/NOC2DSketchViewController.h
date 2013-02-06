//
//  NOCWalkerSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSketchViewController.h"
#import <GLKit/GLKit.h>

@interface NOC2DSketchViewController : NOCSketchViewController
{
    GLKMatrix4 _projectionMatrix2D;
    float _pxUnit;
}

@end

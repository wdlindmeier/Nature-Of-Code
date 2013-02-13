//
//  NOC3DSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSketchViewController.h"
#import <GLKit/GLKit.h>

@interface NOC3DSketchViewController : NOCSketchViewController
{
    GLKMatrix4 _projectionMatrix3D;
}
@end

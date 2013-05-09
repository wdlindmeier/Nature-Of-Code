//
//  NOC3DSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSketchViewController.h"
#ifdef USE_SKETCH_CONTROLS
#import "NOCControlsSketchViewController.h"
#endif
#import <GLKit/GLKit.h>

@interface NOC3DSketchViewController : NOCSketchViewControllerBase <UIGestureRecognizerDelegate>
{
    GLKMatrix4 _projectionMatrix3D;
    GLKMatrix4 _projectionMatrix3DStatic;
    float _cameraDepth;
    float _cameraDepthMin;
}

@property (nonatomic, assign) BOOL isArcballEnabled;
@property (nonatomic, assign) BOOL isGestureNavigationEnabled;
@property (nonatomic, readonly) float cameraDepth;
@property (nonatomic, readonly) GLKQuaternion quatArcball;

- (GLKMatrix4)rotateMatrixWithArcBall:(GLKMatrix4)matrix;

@end

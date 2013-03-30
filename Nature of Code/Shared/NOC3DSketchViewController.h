//
//  NOC3DSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSketchViewController.h"
#import <GLKit/GLKit.h>

@interface NOC3DSketchViewController : NOCSketchViewController <UIGestureRecognizerDelegate>
{
    GLKMatrix4 _projectionMatrix3D;
}

@property (nonatomic, assign) BOOL isArcballEnabled;
@property (nonatomic, assign) BOOL isGestureNavigationEnabled;
@property (nonatomic, readonly) float cameraDepth;

- (GLKMatrix4)rotateMatrixWithArcBall:(GLKMatrix4)matrix;

@end

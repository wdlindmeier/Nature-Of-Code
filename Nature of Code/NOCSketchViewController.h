//
//  WDLViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "NOCShaderProgram.h"
#import "NOCOpenGLHelpers.h"
#import "CAEAGLLayer+Retained.h"

@class CMMotionManager;

@interface NOCSketchViewController : GLKViewController
{
    // Geometry
    CGSize _sizeView;
    float _viewAspect;
    GLfloat _screen3DBillboardVertexData[12];
}

// Properties
@property (nonatomic, strong) NSDictionary *shaders;
@property (nonatomic, readonly) long frameCount;

// Outlets
@property (nonatomic, strong) IBOutlet UIView *viewControls;
@property (nonatomic, strong) IBOutlet UIButton *buttonHideControls;
@property (strong, nonatomic) EAGLContext *context;

// IBActions
- (IBAction)buttonHideControlsPressed:(id)sender;

// GUI
- (NSString *)nibNameForControlGUI;

// Motion
- (GLKVector2)motionVectorFromManager:(CMMotionManager *)motionManager;

// Loop
- (void)setup;
- (void)update;
- (void)resize;
- (void)draw;
- (void)teardown;

@end

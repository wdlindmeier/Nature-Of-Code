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
#import "NOCSketch.h"

@class CMMotionManager;

@interface NOCSketchViewController : GLKViewController <UIActionSheetDelegate>
{
    // Geometry
    CGSize _sizeView;
    float _viewAspect;
    GLfloat _screen3DBillboardVertexData[12];
}

// Properties
@property (nonatomic, readonly) long frameCount;

// Outlets
@property (nonatomic, strong) IBOutlet UIView *viewControls;
@property (nonatomic, strong) IBOutlet UIButton *buttonHideControls;
@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, strong) NOCSketch *sketch;

// IBActions
- (IBAction)buttonHideControlsPressed:(id)sender;
- (IBAction)buttonActionPressed:(id)sender;

// Shaders
- (NOCShaderProgram *)shaderNamed:(NSString *)shaderName;
- (void)addShader:(NOCShaderProgram *)shader named:(NSString *)shaderName;

// GUI
- (NSString *)nibNameForControlGUI;

// Motion
- (GLKVector2)motionVectorFromManager:(CMMotionManager *)motionManager;

// Loop
- (void)setup;
- (void)update;
- (void)resize;
- (void)draw;
- (void)clear;
- (void)teardown;

@end

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
#import "NOCOpenGLTypes.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface NOCSketchViewController : GLKViewController
{
}

// Properties
@property (nonatomic, strong) NSDictionary *shaders;

// Outlets
@property (nonatomic, strong) IBOutlet UIView *viewControls;
@property (nonatomic, strong) IBOutlet UIButton *buttonHideControls;
@property (strong, nonatomic) EAGLContext *context;

// IBActions
- (IBAction)buttonHideControlsPressed:(id)sender;

// GUI
- (NSString *)nibNameForControlGUI;

// Loop
- (void)setup;
- (void)update;
- (void)draw;
- (void)teardown;

@end

//
//  NOCSketchViewController+CourseApp.h
//  Nature of Code
//
//  Created by William Lindmeier on 5/9/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSketchViewController.h"

@class CMMotionManager;

@interface NOCControlsSketchViewController : NOCSketchViewController

@property (nonatomic, strong) IBOutlet UIView *viewControls;
@property (nonatomic, strong) IBOutlet UIButton *buttonHideControls;
@property (nonatomic, strong) NOCSketch *sketch;

// IBActions
- (IBAction)buttonHideControlsPressed:(id)sender;
- (IBAction)buttonActionPressed:(id)sender;

// GUI
- (NSString *)nibNameForControlGUI;

// Motion
- (GLKVector2)motionVectorFromManager:(CMMotionManager *)motionManager;

@end

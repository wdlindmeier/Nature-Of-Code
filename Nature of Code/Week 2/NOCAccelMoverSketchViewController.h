//
//  NOCAccelMoverSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC2DSketchViewController.h"

@interface NOCAccelMoverSketchViewController : NOC2DSketchViewController

@property (nonatomic, strong) IBOutlet UISlider *sliderAccelX;
@property (nonatomic, strong) IBOutlet UISlider *sliderAccelY;
@property (nonatomic, strong) IBOutlet UISlider *sliderMaxRandomAccel;
@property (nonatomic, strong) IBOutlet UISwitch *switchRandom;

- (IBAction)switchRandomChanged:(id)sender;

@end

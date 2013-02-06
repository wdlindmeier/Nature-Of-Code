//
//  NOCRandomWalkerSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC2DSketchViewController.h"

@interface NOCDirectedWalkerSketchViewController : NOC2DSketchViewController

// Variables GUI
@property (nonatomic, strong) IBOutlet UISlider *sliderPixelSize;
@property (nonatomic, strong) IBOutlet UISlider *sliderProbability;
@property (nonatomic, strong) IBOutlet UISwitch *switchClearBuffer;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControlMode;

- (IBAction)segmentedControlValueDidChange:(id)sender;

@end

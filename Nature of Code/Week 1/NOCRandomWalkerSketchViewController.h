//
//  NOCRandomWalkerSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC2DSketchViewController.h"

@interface NOCRandomWalkerSketchViewController : NOC2DSketchViewController

// Variables GUI
@property (nonatomic, strong) IBOutlet UISlider *sliderPixelSize;
@property (nonatomic, strong) IBOutlet UISwitch *switchClearBuffer;

@end

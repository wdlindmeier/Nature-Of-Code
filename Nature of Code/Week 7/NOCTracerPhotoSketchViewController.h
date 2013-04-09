//
//  NOCTracerPhotoSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 4/4/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC2DSketchViewController.h"

@interface NOCTracerPhotoSketchViewController : NOC2DSketchViewController

@property (nonatomic, strong) IBOutlet UISlider *sliderEvolutionRate;
@property (nonatomic, strong) IBOutlet UISlider *sliderMutationRate;
@property (nonatomic, strong) IBOutlet UILabel *labelGeneration;
/*
@property (nonatomic, strong) IBOutlet UISwitch *switchDrawFittestLines;
@property (nonatomic, strong) IBOutlet UISwitch *switchRenderColoredHistory;
*/
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControlContrastMethod;
@property (nonatomic, strong) IBOutlet UISlider *sliderSampleSize;

@end

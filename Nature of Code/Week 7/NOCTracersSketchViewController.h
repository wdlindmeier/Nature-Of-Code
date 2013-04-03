//
//  NOCTracersSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 4/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC3DSketchViewController.h"

@interface NOCTracersSketchViewController : NOC3DSketchViewController

@property (nonatomic, strong) IBOutlet UISlider *sliderEvolutionRate;
@property (nonatomic, strong) IBOutlet UISlider *sliderMutationRate;
@property (nonatomic, strong) IBOutlet UILabel *labelGeneration;
@property (nonatomic, strong) IBOutlet UISwitch *switchDrawFittestLines;
@property (nonatomic, strong) IBOutlet UISwitch *switchRenderColoredHistory;

@end

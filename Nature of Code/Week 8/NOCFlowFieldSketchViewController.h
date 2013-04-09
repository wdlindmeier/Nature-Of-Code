//
//  NOCFlowFieldSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 4/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC2DSketchViewController.h"

@interface NOCFlowFieldSketchViewController : NOC2DSketchViewController

@property (nonatomic, strong) IBOutlet UISlider *sliderAlpha;
@property (nonatomic, strong) IBOutlet UISlider *sliderBeta;
@property (nonatomic, strong) IBOutlet UISlider *sliderStep;

@end

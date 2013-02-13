//
//  NOCMultiMoverSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/7/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC2DSketchViewController.h"

@interface NOCMultiMoverSketchViewController : NOC2DSketchViewController

@property (nonatomic, strong) IBOutlet UISlider *sliderGravity;
@property (nonatomic, strong) IBOutlet UISlider *sliderRepulsion;
@property (nonatomic, strong) IBOutlet UISlider *sliderDistThreshold;
@property (nonatomic, strong) IBOutlet UISlider *sliderVectorScale;

@end

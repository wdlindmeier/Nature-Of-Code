//
//  NOCMovers3DViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC3DSketchViewController.h"

@interface NOCMovers3DSketchViewController : NOC3DSketchViewController

@property (nonatomic, strong) IBOutlet UISlider *sliderGravity;
@property (nonatomic, strong) IBOutlet UISlider *sliderRepulsion;
@property (nonatomic, strong) IBOutlet UISlider *sliderDistThreshold;
@property (nonatomic, strong) IBOutlet UISlider *sliderCameraDepth;

@end

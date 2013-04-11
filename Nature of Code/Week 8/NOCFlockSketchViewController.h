//
//  NOCFlockSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 4/10/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC3DSketchViewController.h"

@interface NOCFlockSketchViewController : NOC3DSketchViewController

@property (nonatomic, strong) IBOutlet UISlider *sliderAttraction;
@property (nonatomic, strong) IBOutlet UISlider *sliderRepulsion;
@property (nonatomic, strong) IBOutlet UISlider *sliderAlignment;

@end

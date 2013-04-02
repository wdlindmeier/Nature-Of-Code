//
//  NOCFollowersSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/31/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC3DSketchViewController.h"

@interface NOCShapeFollowersSketchViewController : NOC3DSketchViewController

@property (nonatomic, strong) IBOutlet UISlider *sliderEvolutionRate;
@property (nonatomic, strong) IBOutlet UISlider *sliderMutationRate;
@property (nonatomic, strong) IBOutlet UILabel *labelGeneration;

@end

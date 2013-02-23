//
//  NOCParticleSystemSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC2DSketchViewController.h"

@interface NOCParticleSystemSketchViewController : NOC2DSketchViewController

@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControlSrcBlend;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControlDstBlend;

@end

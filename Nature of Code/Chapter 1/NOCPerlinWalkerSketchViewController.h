//
//  NOCPerlinWalkerSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/4/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC2DSketchViewController.h"

@interface NOCPerlinWalkerSketchViewController : NOC2DSketchViewController

@property (nonatomic, strong) IBOutlet UISlider *sliderTimestep;
@property (nonatomic, strong) IBOutlet UISlider *sliderAlpha;
@property (nonatomic, strong) IBOutlet UISlider *sliderBeta;
@property (nonatomic, strong) IBOutlet UISlider *sliderNumOctaves;

@property (nonatomic, strong) IBOutlet UILabel *labelTimestep;
@property (nonatomic, strong) IBOutlet UILabel *labelAlpha;
@property (nonatomic, strong) IBOutlet UILabel *labelBeta;
@property (nonatomic, strong) IBOutlet UILabel *labelNumOctaves;

- (IBAction)buttonClearPressed:(id)sender;

@end

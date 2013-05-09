//
//  NOCTableOfContentsViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NOCTableOfContentsCell.h"

@interface NOCTableOfContentsViewController : UITableViewController <
NOCTableOfContentsCellSelectionDelegate
>

@property (nonatomic, strong) IBOutlet UITextView *textViewSketchDescription;
@property (nonatomic, strong) IBOutlet UILabel *labelSketchName;
@property (nonatomic, strong) IBOutlet UIImageView *imageViewSketchThumbnail;
@property (nonatomic, strong) IBOutlet UIView *viewSketchInfoContainer;

@property (nonatomic, strong) IBOutlet UIView *viewInfo;

- (IBAction)buttonRunSketchPressed:(id)sender;
- (IBAction)buttonCancelSketchPressed:(id)sender;
- (IBAction)buttonCloseInfoPressed:(id)sender;
- (IBAction)buttonInfoPressed:(id)sender;

@end

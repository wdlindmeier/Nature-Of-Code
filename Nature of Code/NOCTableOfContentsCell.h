//
//  NOCTableOfContentsCell.h
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NOCChapter.h"
#import "NOCSketch.h"

@protocol NOCTableOfContentsCellSelectionDelegate;

@interface NOCTableOfContentsCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *labelChapterName;
@property (nonatomic, strong) NOCChapter *chapter;
@property (nonatomic, assign) id <NOCTableOfContentsCellSelectionDelegate> delegate;

@end


@protocol NOCTableOfContentsCellSelectionDelegate

- (void)chapterCell:(NOCTableOfContentsCell *)cell
     selectedSketch:(NOCSketch *)sketch
          inChapter:(NOCChapter *)chapter;

@end
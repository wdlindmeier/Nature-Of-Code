//
//  NOCTableOfContentsCell.m
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTableOfContentsCell.h"

@implementation NOCTableOfContentsCell
{
    void *_kvoContextChapter;
    UIScrollView *_scrollView;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initNOCTableOfContentsCell];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self){
        [self initNOCTableOfContentsCell];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        [self initNOCTableOfContentsCell];
    }
    return self;
}

- (void)initNOCTableOfContentsCell
{
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_scrollView];
    
    _labelChapterName = [[UILabel alloc] initWithFrame:CGRectMake(20, 12, 300, 300)];
    _labelChapterName.backgroundColor = [UIColor blackColor];
    _labelChapterName.font = [UIFont systemFontOfSize:24.0f];
    _labelChapterName.textColor = [UIColor whiteColor];
    [self.contentView addSubview:_labelChapterName];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self addObserver:self
           forKeyPath:@"chapter"
              options:NSKeyValueObservingOptionNew
              context:&_kvoContextChapter];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"chapter"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context == &_kvoContextChapter){
        // Update the view w/ the new chapter
        if(self.chapter){
            if(self.chapter){
                [self updateViewWithCurrentChapter];
            }
        }
    }
}

#pragma mark - Layout / Drawing

- (void)updateViewWithCurrentChapter
{
    
    _labelChapterName.text = self.chapter.name;
    CGRect labelFrame = _labelChapterName.frame;
    labelFrame.size.width = 9999;
    _labelChapterName.frame = labelFrame;
    [_labelChapterName sizeToFit];
    
    // Remove previous buttons
    for(UIView *v in _scrollView.subviews){
        if([v isKindOfClass:[UIButton class]]){
            [v removeFromSuperview];
        }
    }
    
    // Create some buttons
    for(int i=0;i<self.chapter.sketches.count;i++){
        NOCSketch *sketch = self.chapter.sketches[i];
        UIButton *btnSketch = [[UIButton alloc] initWithFrame:CGRectZero];
        btnSketch.tag = i;
        [btnSketch setTitle:sketch.name forState:UIControlStateNormal];
        [btnSketch setTitleColor:[UIColor colorWithWhite:0.8 alpha:1]
                        forState:UIControlStateNormal];
        float randBGWhite = (arc4random() % 50) * 0.01;
        btnSketch.backgroundColor = [UIColor colorWithWhite:randBGWhite
                                                      alpha:1.0];
        // Get the thumbnail
        NSString *nameTitleized = [sketch.name stringByReplacingOccurrencesOfString:@" "
                                                                         withString:@""];
        NSString *thumbName = [NSString stringWithFormat:@"thumb_%@", nameTitleized];
        [btnSketch setBackgroundImage:[UIImage imageNamed:thumbName]
                             forState:UIControlStateNormal];
        [btnSketch addTarget:self
                      action:@selector(buttonSketchPressed:)
            forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:btnSketch];
    }
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _scrollView.frame = self.contentView.bounds;

    // Resize the buttons
    CGSize sizeContent = self.contentView.frame.size;

    float buttonHeight = sizeContent.height;
    float buttonWidth = 140.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        buttonWidth = 240.0f;
    }

    for(UIView *v in _scrollView.subviews){
        if([v isKindOfClass:[UIButton class]]){
            int buttonIdx = v.tag;
            v.frame = CGRectMake((buttonWidth*buttonIdx) + buttonIdx, 0, buttonWidth, buttonHeight);
            // Can I push the label down a bit?
            ((UIButton *)v).titleEdgeInsets = UIEdgeInsetsMake(buttonHeight * 0.6,
                                                               0, 0, 0);
        }
    }
    
    // Set the content size
    int buttonCount = self.chapter.sketches.count;
    _scrollView.contentSize = CGSizeMake(buttonWidth * buttonCount, sizeContent.height);
    _scrollView.contentOffset = CGPointMake(0, 0);
}

#pragma mark - Selection

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    // Do nothing
    // [super setSelected:selected animated:animated];
}

#pragma mark - IBOutlets

- (void)buttonSketchPressed:(UIButton *)sender
{
    NOCSketch *sketch = self.chapter.sketches[sender.tag];
    [self.delegate chapterCell:self
                selectedSketch:sketch
                     inChapter:self.chapter];
}

@end

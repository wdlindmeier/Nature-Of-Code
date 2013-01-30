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
    // Remove previous buttons
    for(UIView *v in _scrollView.subviews){
        if([v isKindOfClass:[UIButton class]]){
            [v removeFromSuperview];
        }
    }
    //[_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // Create some buttons
    for(int i=0;i<self.chapter.sketches.count;i++){
        NOCSketch *sketch = self.chapter.sketches[i];
        UIButton *btnSketch = [[UIButton alloc] initWithFrame:CGRectZero];
        btnSketch.tag = i;
        [btnSketch setTitle:sketch.name forState:UIControlStateNormal];
        [btnSketch setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        float randBGWhite = (arc4random() % 50) * 0.01;
        btnSketch.backgroundColor = [UIColor colorWithWhite:randBGWhite
                                                      alpha:1.0];
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
    float buttonWidth = sizeContent.width * 0.4;
    for(UIView *v in _scrollView.subviews){
        if([v isKindOfClass:[UIButton class]]){
            int buttonIdx = v.tag;
            v.frame = CGRectMake(buttonWidth*buttonIdx, 0, buttonWidth, sizeContent.height);
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

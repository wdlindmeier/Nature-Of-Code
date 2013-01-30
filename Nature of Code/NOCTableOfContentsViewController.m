//
//  NOCTableOfContentsViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTableOfContentsViewController.h"
#import "NOCChapter.h"
#import "NOCSketch.h"

@interface NOCTableOfContentsViewController ()
{
    NSArray *_tableOfContents;
}
@end

@implementation NOCTableOfContentsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        NSString *tocPlistPath = [[NSBundle mainBundle] pathForResource:@"TableOfContents" ofType:@"plist"];
        
        NSMutableArray *chapters = [NSMutableArray arrayWithCapacity:20];
        NSArray *tocData = [NSArray arrayWithContentsOfFile:tocPlistPath];
        for(NSDictionary *chInfo in tocData){
            NOCChapter *chapter = [[NOCChapter alloc] initWithDictionary:chInfo];
            [chapters addObject:chapter];
        }
        _tableOfContents = [NSArray arrayWithArray:chapters];
        NSLog(@"_tableOfContents: %@", _tableOfContents);
    }
    return self;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.directionalLockEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: This should probably not be dynamic
    return self.view.frame.size.height * 0.1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tableOfContents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    NOCTableOfContentsCell *cell = (NOCTableOfContentsCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[NOCTableOfContentsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NOCChapter *chapter = _tableOfContents[indexPath.row];
    cell.chapter = chapter;
    cell.delegate = self;
    return cell;
}

- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGSize sizeView = self.view.frame.size;
    return sizeView.height * 0.2;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGSize sizeView = self.view.frame.size;
    CGRect rectLabel = CGRectMake(0, 0, sizeView.width, 0);
    rectLabel.size.height = [self tableView:tableView heightForHeaderInSection:section];
    
    UILabel *label = [[UILabel alloc] initWithFrame:rectLabel];
    label.backgroundColor = [UIColor colorWithRed:0.91
                                            green:0.1
                                             blue:0.36
                                            alpha:1.0];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:24.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    label.text = NSLocalizedString(@"NATURE OF CODE", @"Table of Contents Header");
    return label;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NOCChapter *chapter = _tableOfContents[indexPath.row];
    NSLog(@"Clicked CELL %@", chapter.name);
}

#pragma mark - NOCTableOfContentsCellSelectionDelegate

- (void)chapterCell:(NOCTableOfContentsCell *)cell selectedSketch:(NOCSketch *)sketch inChapter:(NOCChapter *)chapter
{
    NSLog(@"Selected sketch: %@ in chapter %@", sketch.name, chapter.name);
}

@end

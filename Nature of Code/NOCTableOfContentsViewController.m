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
#import "NOCSketchViewController.h"
#import "NOCSampleSketchViewController.h"

@interface NOCTableOfContentsViewController ()
{
    NSArray *_tableOfContents;
    NOCSketch *_selectedSketch;
}

@property (nonatomic, strong) IBOutlet UIView *selectedSketchView;

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

    }
    return self;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.directionalLockEnabled = YES;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return 120.0f;
    }
    return 60.0f;
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
    /*
    CGSize sizeView = self.view.frame.size;
    return sizeView.height * 0.2;
    */
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        return 200.0f;
    }
    return 100.0f;
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
    // Let the cell buttons handle this
}

#pragma mark - NOCTableOfContentsCellSelectionDelegate

- (void)chapterCell:(NOCTableOfContentsCell *)cell selectedSketch:(NOCSketch *)sketch inChapter:(NOCChapter *)chapter
{
    [self presentSelectedSketch:sketch];
}

#pragma mark - Selected Sketch View

#pragma mark - IBActions

- (IBAction)buttonRunSketchPressed:(id)sender
{
    NSString *sketchControllerName = [NSString stringWithFormat:@"NOC%@SketchViewController", _selectedSketch.controllerName];
    Class ControllerClass = NSClassFromString(sketchControllerName);
    if(!ControllerClass){
        ControllerClass = [NOCSampleSketchViewController class];
    }
    
    NOCSampleSketchViewController *sketchViewController = [[ControllerClass alloc]
                                                           initWithNibName:@"NOCSketchViewController"
                                                           bundle:nil];
    sketchViewController.title = _selectedSketch.name;
    
    // Remove the sketch
    [self dismissSelectedSketch:NO];

    [self.navigationController pushViewController:sketchViewController animated:YES];
    
}

- (IBAction)buttonCancelSketchPressed:(id)sender
{
    [self dismissSelectedSketch:YES];
}

#pragma mark - View State

- (void)presentSelectedSketch:(NOCSketch *)sketch
{
    _selectedSketch = sketch;
    
    if(!self.selectedSketchView){
        [[NSBundle mainBundle] loadNibNamed:@"NOCSketchDescriptionView"
                                      owner:self
                                    options:0];
    }else{
        [self.selectedSketchView removeFromSuperview];
    }
    
    self.textViewSketchDescription.text = _selectedSketch.description;
    self.labelSketchName.text = _selectedSketch.name;
    UIImage *thumbnail = [UIImage imageNamed:[NSString stringWithFormat:@"thumb_%@", _selectedSketch.controllerName]];
    self.imageViewSketchThumbnail.image = thumbnail;
    
    self.selectedSketchView.alpha = 0;
    self.selectedSketchView.frame = self.view.bounds;
    
    CGSize sizeSketchView = self.selectedSketchView.frame.size;
    self.viewSketchInfoContainer.center = CGPointMake(sizeSketchView.width * 0.5,
                                                      sizeSketchView.width * 0.5);

    // Make sure the frame doesn't land on a 1/2 pixel
    CGRect framePopup = self.viewSketchInfoContainer.frame;
    framePopup.origin.x = round(framePopup.origin.x);
    framePopup.origin.y = round(framePopup.origin.y);
    self.viewSketchInfoContainer.frame = framePopup;
    
    [self.view addSubview:self.selectedSketchView];
    
    [UIView animateWithDuration:0.35
                     animations:^{
                         self.selectedSketchView.alpha = 1;
                     }
                     completion:nil];
}

- (void)dismissSelectedSketch:(BOOL)animated
{
    if(animated){
        [UIView animateWithDuration:0.35
                         animations:^{
                             self.selectedSketchView.alpha = 0;
                         }
                         completion:^(BOOL finished) {
                             [self.selectedSketchView removeFromSuperview];
                             _selectedSketch = nil;
                         }];
    }else{
        self.selectedSketchView.alpha = 0;
        [self.selectedSketchView removeFromSuperview];
        _selectedSketch = nil;
    }
}

@end

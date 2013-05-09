//
//  NOCSketchViewController+CourseApp.m
//  Nature of Code
//
//  Created by William Lindmeier on 5/9/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCControlsSketchViewController.h"
#import <CoreMotion/CoreMotion.h>

static const float DrawerRevealHeight = 20.0f;

@interface NOCSketchViewController(Private)

- (void)setupGL;

@end

@implementation NOCControlsSketchViewController
{    
    BOOL _isDraggingDrawer;
    CGPoint _posDrawerClosed;
    CGPoint _posDrawerOpen;
    BOOL _isDrawerOpen;
    UIPanGestureRecognizer *_gestureRecognizerDrawer;
    UIActionSheet *_actionSheet;
}

- (NSString *)nibNameForControlGUI
{
    return nil;
}

#pragma mark - View

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // Setup the GUI Drawer
    NSString *guiName = [self nibNameForControlGUI];
    if(guiName){
        
        _isDraggingDrawer = NO;
        _isDrawerOpen = NO;
        self.viewControls.hidden = YES;
        [self.view addSubview:self.viewControls];
        
        UIView *controlView = [[NSBundle mainBundle] loadNibNamed:guiName owner:self options:0][0];
        controlView.frame = self.viewControls.bounds;
        [self.viewControls insertSubview:controlView atIndex:0];
        
        // A gesture recognizer to handle opening/closing the drawer
        _gestureRecognizerDrawer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                           action:@selector(handleGesture:)];
        self.viewControls.gestureRecognizers = @[_gestureRecognizerDrawer];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self repositionDrawer:YES];
    [self teaseDrawer];
}


#pragma mark - Motion

- (GLKVector2)motionVectorFromManager:(CMMotionManager *)motionManager
{
    CMDeviceMotion *motion = [motionManager deviceMotion];
    CMAcceleration gravity = motion.gravity;
    
    float halfWidth = 1;
    float halfHeight = 1 / _viewAspect;
    
    // Calibrate for the amount of tilt by eyeballing
    const static float GravityMultiplier = 2.0f;
    
    float x = gravity.x * halfWidth * GravityMultiplier;
    float y = gravity.y * halfHeight * GravityMultiplier;
    float swap = x;
    
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            x = y;
            y = swap * -1;
            break;
        case UIInterfaceOrientationLandscapeRight:
            x = y * -1;
            y = swap;
            break;
        case UIInterfaceOrientationPortrait:
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            x = x * -1;
            y = y * -1;
            break;
    }
    
    return GLKVector2Make(x, y);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self repositionDrawer:NO];
}

#pragma mark - Gesture Recognizer

- (void)handleGesture:(UIPanGestureRecognizer *)gr
{
    BOOL shouldOpenDrawer = NO;
    BOOL shouldCloseDrawer = NO;
    CGPoint grPos = [gr locationInView:self.view];
    CGPoint grTrans = [gr translationInView:self.view];
    CGSize sizeDrawer = self.viewControls.frame.size;
    
    switch (gr.state) {
            
        case UIGestureRecognizerStateBegan:
            _isDraggingDrawer = NO;
            if(fabs(grTrans.y) > fabs(grTrans.x * 2)){
                // This is a vertical swipe
                _isDraggingDrawer = YES;
            }
            break;
        case UIGestureRecognizerStateChanged:
            
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            if(_isDraggingDrawer){
                float minTravelDist = sizeDrawer.height * 0.25;
                shouldCloseDrawer = grTrans.y > minTravelDist;
                if(!shouldCloseDrawer){
                    shouldOpenDrawer = fabs(grTrans.y) > minTravelDist;
                }
                if(!shouldCloseDrawer && !shouldOpenDrawer){
                    if(_isDrawerOpen){
                        shouldOpenDrawer = YES;
                    }else{
                        shouldCloseDrawer = YES;
                    }
                }
            }
            _isDraggingDrawer = NO;
            break;
        default:
            break;
    }
    
    if(_isDraggingDrawer){
        
        self.viewControls.center = CGPointMake(_posDrawerClosed.x,
                                               MAX(grPos.y + (sizeDrawer.height*0.5),
                                                   _posDrawerOpen.y));
        
    }else{
        
        if(shouldCloseDrawer){
            [self closeDrawer];
        }else if(shouldOpenDrawer){
            [self openDrawer];
        }
    }
}

#pragma mark - View States

- (void)repositionDrawer:(BOOL)setViewCenter
{
    CGSize sizeView = self.view.frame.size;
    CGSize sizeViewDrawer = self.viewControls.frame.size;
    
    _posDrawerOpen = CGPointMake(sizeView.width * 0.5,
                                 sizeView.height - (sizeViewDrawer.height * 0.5));
    _posDrawerClosed = CGPointMake(sizeView.width * 0.5,
                                   sizeView.height + (sizeViewDrawer.height * 0.5) - DrawerRevealHeight);
    if(setViewCenter){
        self.viewControls.center = _posDrawerClosed;
        self.viewControls.hidden = NO;
    }
}

- (void)closeDrawer
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.viewControls.center = _posDrawerClosed;
                     }
                     completion:^(BOOL finished) {
                         _isDrawerOpen = NO;
                         self.buttonHideControls.layer.transform = CATransform3DMakeScale(1, 1, 1);
                     }];
}

- (void)openDrawer
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.viewControls.center = _posDrawerOpen;
                     }
                     completion:^(BOOL finished) {
                         _isDrawerOpen = YES;
                         // Flip the toggle button so it's facing down
                         self.buttonHideControls.layer.transform = CATransform3DMakeScale(1, -1, 1);
                     }];
}

- (void)teaseDrawer
{
    [UIView animateWithDuration:0.35
                     animations:^{
                         self.viewControls.center = CGPointMake(_posDrawerClosed.x,
                                                                _posDrawerClosed.y - 50.0f);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.25
                                               delay:0.3
                                             options:0
                                          animations:^{
                                              self.viewControls.center = _posDrawerClosed;
                                          } completion:^(BOOL finished) {
                                              //...
                                          }];
                     }];
}

#pragma mark - IBActions

- (IBAction)buttonHideControlsPressed:(id)sender
{
    if(_isDrawerOpen){
        [self closeDrawer];
    }else{
        [self openDrawer];
    }
}

static NSString *const NOCActionButtonTitleReadMore = @"Read About This Topic";
static NSString *const NOCActionButtonTitleViewCode = @"View Code";

- (IBAction)buttonActionPressed:(UIBarButtonItem *)sender
{
    if(_actionSheet){
        [_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex
                                           animated:NO];
    }
    _actionSheet = [[UIActionSheet alloc] initWithTitle:@"Online Resources"
                                               delegate:self
                                      cancelButtonTitle:@"Cancel"
                                 destructiveButtonTitle:nil
                                      otherButtonTitles:NOCActionButtonTitleReadMore,
                    NOCActionButtonTitleViewCode,
                    nil];
    [_actionSheet showFromBarButtonItem:sender
                               animated:YES];
}

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(actionSheet == _actionSheet){
        if(buttonIndex != [actionSheet cancelButtonIndex]){
            if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NOCActionButtonTitleReadMore]){
                [[UIApplication sharedApplication] openURL:self.sketch.URLReadMore];
            }else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NOCActionButtonTitleViewCode]){
                [[UIApplication sharedApplication] openURL:self.sketch.URLCode];
            }
        }
        _actionSheet = nil;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(actionSheet == _actionSheet){
        _actionSheet = nil;
    }
}


@end

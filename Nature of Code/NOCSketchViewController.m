//
//  WDLViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSketchViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface NOCSketchViewController ()
{
    BOOL _isDraggingDrawer;
    CGPoint _posDrawerClosed;
    CGPoint _posDrawerOpen;
    BOOL _isDrawerOpen;
    UIPanGestureRecognizer *_gestureRecognizerDrawer;
}
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;
- (BOOL)loadShaders;

@end

static const float DrawerRevealHeight = 20.0f;

@implementation NOCSketchViewController

#pragma mark Memory

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [self setupGL];
    
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
        _gestureRecognizerDrawer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        self.viewControls.gestureRecognizers = @[_gestureRecognizerDrawer];
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self resize];
    [self repositionDrawer:YES];
    [self teaseDrawer];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self repositionDrawer:NO];
    [self resize];
}

#pragma mark - Accessors

- (NSString *)nibNameForControlGUI
{
    return nil;
}

#pragma mark - Gesture Recognizer

- (void)handleGesture:(UIPanGestureRecognizer *)gr
{
    if(!_isDrawerOpen){
        
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
                if(_isDraggingDrawer){
                    if(grTrans.y * -1 > sizeDrawer.height * 0.25){
                        shouldOpenDrawer = YES;
                    }else{
                        shouldCloseDrawer = YES;
                    }
                }
                _isDraggingDrawer = NO;
                break;
            case UIGestureRecognizerStateCancelled:
                shouldCloseDrawer = _isDraggingDrawer;
                _isDraggingDrawer = NO;
                break;
            case UIGestureRecognizerStateFailed:
                shouldCloseDrawer = _isDraggingDrawer;
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
                         self.viewControls.gestureRecognizers = @[_gestureRecognizerDrawer];
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
                         self.viewControls.gestureRecognizers = @[];
                     }];
}

- (void)teaseDrawer
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.viewControls.center = CGPointMake(_posDrawerClosed.x,
                                                                _posDrawerClosed.y - 50.0f);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.5
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
    [self closeDrawer];
}

#pragma mark - GL

- (void)setupGL
{
    NSLog(@"setupGL");
    [EAGLContext setCurrentContext:self.context];
    [self setup];
    [self loadShaders];
}

- (void)tearDownGL
{
    NSLog(@"tearDownGL");
    [self teardown];
    for(NSString *shaderName in self.shaders){
        NOCShaderProgram *shader = self.shaders[shaderName];
        [shader unload];
    }
    [EAGLContext setCurrentContext:self.context];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self draw];
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    for(NSString *shaderName in self.shaders){
        
        NOCShaderProgram *shader = self.shaders[shaderName];
        BOOL didLoad = [shader load];
        if(!didLoad){
            return NO;
        }

    }
    
    return YES;
}

#pragma mark - Subclass Loop

- (void)setup
{
    //..
}

- (void)update
{
    //...
}

- (void)resize
{
    //...
}

- (void)draw
{
    //...
}

- (void)teardown
{
    //...
}

@end

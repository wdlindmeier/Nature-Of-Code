//
//  WDLViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSketchViewController.h"

@interface NOCSketchViewController ()
{    
}
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

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
    _isDraggingDrawer = NO;
    _isDrawerOpen = NO;
    self.viewControls.hidden = YES;
    [self.view addSubview:self.viewControls];
    
    // A gesture recognizer to handle opening/closing the drawer
    UIPanGestureRecognizer *gr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    self.view.gestureRecognizers = @[gr];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self repositionDrawer:YES];
    [self teaseDrawer];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self repositionDrawer:NO];
}

#pragma mark - Gesture Recognizer

- (void)handleGesture:(UIPanGestureRecognizer *)gr
{
    if(!_isDrawerOpen){
        CGPoint grPos = [gr locationInView:self.view];
        CGPoint grTrans = [gr translationInView:self.view];
        float startingY = grPos.y - grTrans.y;

        BOOL shouldOpenDrawer = NO;
        BOOL shouldCloseDrawer = NO;
        CGSize sizeDrawer = self.viewControls.frame.size;
        CGSize sizeView = self.view.frame.size;

        switch (gr.state) {
            case UIGestureRecognizerStateBegan:
                _isDraggingDrawer = NO;
                // Check if it started at the bottom of the screen
                if(fabs(grTrans.y) > fabs(grTrans.x * 2)){
                    // This is a vertical swipe
                    if(startingY > (sizeView.height - 40)){
                        _isDraggingDrawer = YES;
                    }
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
                _isDraggingDrawer = NO;
                shouldCloseDrawer = YES;
                break;
            case UIGestureRecognizerStateFailed:
                _isDraggingDrawer = NO;
                shouldCloseDrawer = YES;
                break;
            default:
                break;
        }

        if(_isDraggingDrawer){
            self.viewControls.center = CGPointMake(_posDrawerClosed.x,
                                                   MAX(grPos.y + (sizeDrawer.height*0.5),
                                                       _posDrawerClosed.y - sizeDrawer.height));
        }else{
            if(shouldCloseDrawer){
                [self closeDrawer];
            }else{
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
    _posDrawerClosed = CGPointMake(sizeView.width * 0.5, sizeView.height + (sizeViewDrawer.height * 0.5));
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
                     }];
}

- (void)openDrawer
{
    CGSize sizeDrawer = self.viewControls.frame.size;
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.viewControls.center = CGPointMake(_posDrawerClosed.x,
                                                                _posDrawerClosed.y - sizeDrawer.height);
                     }
                     completion:^(BOOL finished) {
                         _isDrawerOpen = YES;
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
    for(NOCShaderProgram *program in self.shaders){
        [program unload];
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
        
        /*
        GLuint vertShader, fragShader;
        NSString *vertShaderPathname, *fragShaderPathname;
        
        // Create shader program.
        _program = glCreateProgram();
        
        // Create and compile vertex shader.
        vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
        if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
            NSLog(@"Failed to compile vertex shader");
            return NO;
        }
        
        // Create and compile fragment shader.
        fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
        if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
            NSLog(@"Failed to compile fragment shader");
            return NO;
        }
        
        // Attach vertex shader to program.
        glAttachShader(_program, vertShader);
        
        // Attach fragment shader to program.
        glAttachShader(_program, fragShader);
        
        // Bind attribute locations.
        // This needs to be done prior to linking.
        glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
        glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
        
        // Link program.
        if (![self linkProgram:_program]) {
            NSLog(@"Failed to link program: %d", _program);
            
            if (vertShader) {
                glDeleteShader(vertShader);
                vertShader = 0;
            }
            if (fragShader) {
                glDeleteShader(fragShader);
                fragShader = 0;
            }
            if (_program) {
                glDeleteProgram(_program);
                _program = 0;
            }
            
            return NO;
        }
        
        // Get uniform locations.
        uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
        uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
        
        // Release vertex and fragment shaders.
        if (vertShader) {
            glDetachShader(_program, vertShader);
            glDeleteShader(vertShader);
        }
        if (fragShader) {
            glDetachShader(_program, fragShader);
            glDeleteShader(fragShader);
        }
         */

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

- (void)draw
{
    //...
}

- (void)teardown
{
    //...
}

@end

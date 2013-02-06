//
//  NOCRandomWalkerSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCDirectedWalkerSketchViewController.h"
#import "NOCDirectedWalker.h"
#import <CoreMotion/CoreMotion.h>

enum {
    FollowModeTouch = 0,
    FollowModeGravity
};

@interface NOCDirectedWalkerSketchViewController ()
{
    NOCShaderProgram *_shader;
    NOCDirectedWalker *_walker;
    GLKVector2 _positionFollow;
    CMMotionManager *_motionManager;
}

@end

static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * NOCShaderNameDirectedWalker = @"RandomWalker"; // We'll use the same shader

@implementation NOCDirectedWalkerSketchViewController

#pragma mark - Interface Orientation

// If we're tracking motion, don't allow autorotation
- (NSUInteger)supportedInterfaceOrientations
{
    if(_motionManager){
        switch (self.interfaceOrientation) {
            case UIInterfaceOrientationPortrait:
                return UIInterfaceOrientationMaskPortrait;
            case UIInterfaceOrientationLandscapeLeft:
                return UIInterfaceOrientationMaskLandscapeLeft;
            case UIInterfaceOrientationLandscapeRight:
                return UIInterfaceOrientationMaskLandscapeRight;
            case UIInterfaceOrientationPortraitUpsideDown:
                return UIInterfaceOrientationMaskPortraitUpsideDown;
        }
    }
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if(_motionManager){
        return toInterfaceOrientation == self.interfaceOrientation;
    }
    return YES;
}

#pragma mark - GUI

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiDirectedWalker";
}

#pragma mark - IBActions

- (IBAction)segmentedControlValueDidChange:(id)sender
{
    int followMode = self.segmentedControlMode.selectedSegmentIndex;
    
    switch (followMode) {
        case FollowModeTouch:
            [_motionManager stopDeviceMotionUpdates];
            _motionManager = nil;
            break;
        case FollowModeGravity:
            _motionManager = [[CMMotionManager alloc] init];
            [_motionManager startDeviceMotionUpdates];
            break;
    }
}

#pragma mark - Draw Loop

- (void)setup
{
     
    // Setup the shader
    _shader = [[NOCShaderProgram alloc] initWithName:NOCShaderNameDirectedWalker];
    
    _shader.attributes = @{
        @"position" : @(GLKVertexAttribPosition),
        @"color" : @(GLKVertexAttribColor)
    };
    
    _shader.uniformNames = @[
        UniformMVProjectionMatrix,
    ];
    
    self.shaders = @{ NOCShaderNameDirectedWalker : _shader };
    
    // Setup the Walker
    _positionFollow = GLKVector2Make(0, 0);
    _walker = [[NOCDirectedWalker alloc] initWithSize:CGSizeMake(10, 10)
                                             position:_positionFollow];
    
    // Call this to trigger the initial mode
    [self segmentedControlValueDidChange:self.segmentedControlMode];
    
}

- (void)resize
{
    [super resize];
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)update
{
    [super update];
    
    if(_motionManager){
        [self getFollowPointFromGravity];
    }
    
    // Update the walker size according to the slider.
    float walkerSize = self.sliderPixelSize.value;
    _walker.size = CGSizeMake(walkerSize, walkerSize);
    
    // Step w/in the bounds
    CGSize sizeView = self.view.frame.size;
    CGRect walkerBounds = CGRectMake(sizeView.width * -0.5,
                                     sizeView.height * -0.5,
                                     sizeView.width,
                                     sizeView.height);

    _walker.probabilityOfFollowingPoint = self.sliderProbability.value;
    
    [_walker stepInRect:walkerBounds toward:_positionFollow];
    
}

- (void)draw
{
    
    if(self.switchClearBuffer.on){
        // Clear to gray
        glClearColor(0.2, 0.2, 0.2, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    
    [_shader use];
    
    // Create the Model View Projection matrix for the shader
    NSNumber *projMatLoc = _shader.uniformLocations[UniformMVProjectionMatrix];
    
    // Get the model matrix
    GLKMatrix4 modelMat = [_walker modelMatrixForPixelUnit:_pxUnit];

    // Multiply by the projection matrix
    GLKMatrix4 mvProjMat = GLKMatrix4Multiply(_projectionMatrix2D, modelMat);
    
    // Pass mvp into shader
    glUniformMatrix4fv([projMatLoc intValue], 1, 0, mvProjMat.m);

    [_walker render];
    
}

- (void)teardown
{
    [_motionManager stopDeviceMotionUpdates];
    _motionManager = nil;
}

#pragma mark - Device motion

- (void)getFollowPointFromGravity
{
    CGSize sizeView = self.view.frame.size;
    CMDeviceMotion *motion = [_motionManager deviceMotion];
    CMAcceleration gravity = motion.gravity;
    float halfWidth = sizeView.width * 0.5;
    float halfHeight = sizeView.height * 0.5;

    // Calibrate for the amount of tily by eyeballing 
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
    
    _positionFollow = GLKVector2Make(x, y);

}

#pragma mark - Touch

- (void)followTouches:(NSSet *)touches
{
    CGSize sizeView = self.view.frame.size;
    
    for(UITouch *t in touches){
        
        // We have to map this touch onto a -1..1 coord system
        CGPoint posTouch = [t locationInView:self.view];
        
        float halfWidth = sizeView.width * 0.5;
        float halfHeight = sizeView.height * 0.5;
        float x = posTouch.x - halfWidth;
        float y = (posTouch.y - halfHeight) * -1;
        
        _positionFollow = GLKVector2Make(x, y);
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self followTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self followTouches:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self followTouches:touches];
}

@end

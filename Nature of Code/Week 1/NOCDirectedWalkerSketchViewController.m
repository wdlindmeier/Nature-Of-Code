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
static NSString * ShaderNameDirectedWalker = @"RandomWalker"; // We'll use the same shader

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
    _shader = [[NOCShaderProgram alloc] initWithName:ShaderNameDirectedWalker];
    
    _shader.attributes = @{
        @"position" : @(GLKVertexAttribPosition),
        @"color" : @(GLKVertexAttribColor)
    };
    
    _shader.uniformNames = @[
        UniformMVProjectionMatrix,
    ];
    
    self.shaders = @{ ShaderNameDirectedWalker : _shader };
    
    // Setup the Walker
    _positionFollow = GLKVector2Make(0, 0);
    _walker = [[NOCDirectedWalker alloc] initWithSize:GLKVector2Make(0.01, 0.01)
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
    _walker.size = GLKVector2Make(walkerSize, walkerSize);
    
    // Step w/in the bounds
    CGSize sizeView = self.view.frame.size;
    float aspect = sizeView.width / sizeView.height;
    CGRect walkerBounds = CGRectMake(-1, -1 / aspect,
                                     2, 2 / aspect);

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
    GLKMatrix4 modelMat = [_walker modelMatrix];

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
    _positionFollow = [self motionVectorFromManager:_motionManager];
}

#pragma mark - Touch

- (void)followTouches:(NSSet *)touches
{
    CGSize sizeView = self.view.frame.size;
    float halfWidth = (sizeView.width * 0.5);
    float halfHeight =  (sizeView.height * 0.5);
    float aspect = sizeView.width / sizeView.height;
    
    for(UITouch *t in touches){
        
        CGPoint posTouch = [t locationInView:self.view];
        
        // Convert to GL coords -1..1
        float x = (posTouch.x - halfWidth) / halfWidth;
        float y = ((posTouch.y - halfHeight) / halfHeight) * -1 / aspect;
        
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

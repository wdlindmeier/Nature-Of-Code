//
//  NOC3DSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC3DSketchViewController.h"

@interface NOC3DSketchViewController ()
{
    float _radiansPerPixel;
    CGPoint _posTouchInit;
	GLKQuaternion _quatArcball;
    float _camDepthScalingBegan;
    UIPinchGestureRecognizer *_depthGestureRecognizer;
    UIRotationGestureRecognizer *_rotationGestureRecognizer;
    float _lastRotationRadians;
    
}
@end

@implementation NOC3DSketchViewController

@synthesize cameraDepth = _cameraDepth;
@synthesize quatArcball = _quatArcball;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self){
        [self initNOC3DSketchViewController];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self){
        [self initNOC3DSketchViewController];
    }
    return self;
}

- (void)initNOC3DSketchViewController
{
    self.isArcballEnabled = NO;
    self.isGestureNavigationEnabled = NO;
    _cameraDepth = -3.0f;
    _cameraDepthMin = -100.0f;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    _depthGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(handleDepthGesture:)];
    _depthGestureRecognizer.delegate = self;
    
    _rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(handleRotationGesture:)];
    _rotationGestureRecognizer.delegate = self;
    
    self.view.gestureRecognizers = @[_rotationGestureRecognizer, _depthGestureRecognizer];
}

#pragma mark - Gesture Recognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)handleDepthGesture:(UIPinchGestureRecognizer *)gr
{
    switch (gr.state) {
        case UIGestureRecognizerStateBegan:
            _camDepthScalingBegan = _cameraDepth;
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            
            break;
        default:
            break;
    }
    _cameraDepth = MAX(_cameraDepthMin, _camDepthScalingBegan * (1.0f/gr.scale));
}

- (void)handleRotationGesture:(UIRotationGestureRecognizer *)gr
{
    float deltaRads = gr.rotation - _lastRotationRadians;
    _lastRotationRadians = gr.rotation;
    
    switch (gr.state) {
        case UIGestureRecognizerStateBegan:
            break;
        case UIGestureRecognizerStateChanged:
        {
            GLKVector3 zAxis = GLKVector3Make(0.f, 0.f, -1.f);
            zAxis = GLKQuaternionRotateVector3( GLKQuaternionInvert(_quatArcball), zAxis );
            GLKQuaternion quatZ = GLKQuaternionMakeWithAngleAndVector3Axis(deltaRads, zAxis);
            _quatArcball = GLKQuaternionMultiply(_quatArcball, quatZ);
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            
            break;
        default:
            break;
    }
}

#pragma mark - App Loop

- (void)resize
{
    [super resize];    
    // Setup the 3D projection matrix that fits the screen.
    _projectionMatrix3D = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), _viewAspect, 0.1f, 100.0f);
    _projectionMatrix3DStatic = _projectionMatrix3D;
    _radiansPerPixel = M_PI / _sizeView.width;
    
    _depthGestureRecognizer.enabled = self.isGestureNavigationEnabled;
    _rotationGestureRecognizer.enabled = self.isGestureNavigationEnabled;
    
    [self initArcBall];
}

- (void)update
{
    [super update];
    
    GLKMatrix4 matCam = GLKMatrix4MakeTranslation(0, 0, self.cameraDepth);
    GLKMatrix4 matScene = GLKMatrix4Multiply(_projectionMatrix3DStatic, matCam);
    

    if(self.isArcballEnabled){
        
        _projectionMatrix3D = [self rotateMatrixWithArcBall:matScene];
        
    }
    
    if(self.isGestureNavigationEnabled){
        
        _projectionMatrix3D = [self rotateMatrixWithArcBall:matScene];
        
    }
    
}

#pragma mark - Arcball rotation

// http://thestrangeagency.com/arcball-rotation-with-glkit/

- (void) initArcBall
{
	_quatArcball = GLKQuaternionMake(0.f, 0.f, 0.f, 1.f);
    _posTouchInit = CGPointZero;
}

- (GLKMatrix4)rotateMatrixWithArcBall:(GLKMatrix4)matrix
{
	GLKVector3 axis = GLKQuaternionAxis(_quatArcball);
	float angle = GLKQuaternionAngle(_quatArcball);
	if( angle != 0.f ){
		return GLKMatrix4Rotate(matrix, angle, axis.x, axis.y, axis.z);
    }
    return matrix;
}

- (void)rotateQuaternionWithVector:(CGPoint)delta
{
	GLKVector3 up = GLKVector3Make(0.f, 1.f, 0.f);
	GLKVector3 right = GLKVector3Make(-1.f, 0.f, 0.f);
    
	up = GLKQuaternionRotateVector3( GLKQuaternionInvert(_quatArcball), up );
    GLKQuaternion quatUp = GLKQuaternionMakeWithAngleAndVector3Axis(delta.x * _radiansPerPixel, up);
	_quatArcball = GLKQuaternionMultiply(_quatArcball, quatUp);
    
	right = GLKQuaternionRotateVector3( GLKQuaternionInvert(_quatArcball), right );
    GLKQuaternion quatRight = GLKQuaternionMakeWithAngleAndVector3Axis(delta.y * _radiansPerPixel, right);
	_quatArcball = GLKQuaternionMultiply(_quatArcball, quatRight);
}

#pragma mark - Touch

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	_posTouchInit = [touch locationInView:self.view];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self.view];
    
	// get touch delta
	CGPoint delta = CGPointMake(location.x - _posTouchInit.x, -(location.y - _posTouchInit.y));
	_posTouchInit = location;
    
	// rotate
	[self rotateQuaternionWithVector:delta];
}

@end

//
//  NOCVideoSession.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCVideoSession.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <CoreVideo/CoreVideo.h>

/* kCGImagePropertyOrientation values
 The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
 by the TIFF and EXIF specifications -- see enumeration of integer constants.
 The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
 
 used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
 If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */

enum {
    PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
    PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
    PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
    PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
    PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
    PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
    PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
    PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
};

@implementation NOCVideoSession
{
    AVCaptureSession *_session;
    AVCaptureVideoDataOutput *_videoDataOutput;
    NSTimeInterval _timeAVSessionStarted;
    CIDetector *_faceDetector;
    AVCaptureVideoPreviewLayer *_previewLayer;
    CVOpenGLESTextureRef _videoTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    BOOL _isUsingGLOutput;
}

@synthesize previewLayer = _previewLayer;

#pragma mark - Init

- (id)initWithDelegate:(id<NOCVideoSessionFaceDelegate>)faceDelegate
{
    self = [super init];
    if(self){
        self.faceDelegate = faceDelegate;
        self.shouldOutlineFaces = YES;
        
        NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                           context:nil
                                           options:detectorOptions];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(avSessionError:)
                                                     name:AVCaptureSessionRuntimeErrorNotification
                                                   object:nil];
        
    }
    return self;
}

#pragma mark - Notifications

- (void)avSessionError:(NSNotification *)note
{
    NSLog(@"AVSession Error: note: %@", note);
}

#pragma mark - Video Session

- (AVCaptureSession *)setupWithDevice:(AVCaptureDevice *)device format:(int)format
{
    _timeAVSessionStarted = [NSDate timeIntervalSinceReferenceDate];
    
	NSError *error = nil;
	
	AVCaptureSession *session = [AVCaptureSession new];
    [session beginConfiguration];
    
    [session setSessionPreset:AVCaptureSessionPresetLow];
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                              error:&error];
    if(error){
        NSLog(@"ERROR: %@", error);
        return nil;
    }
    
	if ( [session canAddInput:deviceInput] ){
        [session addInput:deviceInput];
    }else{
        NSLog(@"ERROR: Couldnt add input");
        return nil;
    }
	
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    [_videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:format]
                                                                   forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    // Doh. This seems to kill the GLKit draw loop
	[_videoDataOutput setSampleBufferDelegate:self
                                        queue:dispatch_get_main_queue()];
    if ([session canAddOutput:_videoDataOutput] ){
		[session addOutput:_videoDataOutput];
    }else{
        NSLog(@"ERROR: Couldn't add output");
    }

    [session commitConfiguration];

    return session;
}

- (void)setupWithDevice:(AVCaptureDevice *)device inContext:(EAGLContext *)context
{
    _isUsingGLOutput = YES;
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &_videoTextureCache);
    if (err){
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }

    _session = [self setupWithDevice:device format:kCMPixelFormat_32BGRA];// kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];

    [_session startRunning];

}

- (AVCaptureVideoPreviewLayer *)setupForPreviewWithDevice:(AVCaptureDevice *)device
{
    _session = [self setupWithDevice:device format:kCMPixelFormat_32BGRA];
    
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
	[_previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    _isUsingGLOutput = NO;

	[_session startRunning];
    
    return _previewLayer;
}

- (void)teardown
{
    self.faceDelegate = nil;
    _videoDataOutput = nil;
	[_previewLayer removeFromSuperlayer];
    _previewLayer = nil;

    [self cleanUpTextures];
    
    [_session stopRunning];

    
    CFRelease(_videoTextureCache);
}

- (void)cleanUpTextures
{
    if (_videoTexture){
        CFRelease(_videoTexture);
        _videoTexture = NULL;
    }
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

#pragma mark - Accessors

- (BOOL)isMirrored
{
    return [_previewLayer.connection isVideoMirrored];
}

#pragma mark - Video Processing
/*
- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //...
}
*/
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // CVPixelBufferRef seems to be the same as CVImageBufferRef
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if(_isUsingGLOutput){
        
        [self bindCameraImageToGLTexture:pixelBuffer];
        
    }
    
    if(self.faceDelegate){
        
        [self performFacialDetectionWithSample:sampleBuffer pixels:pixelBuffer];
        
    }
}

- (void)bindCameraImageToGLTexture:(CVImageBufferRef)pixelBuffer
{
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    if (!_videoTextureCache)
    {
        NSLog(@"ERROR: No video texture cache");
        return;
    }
    
    [self cleanUpTextures];

    CVReturn err;
    glActiveTexture(GL_TEXTURE0);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       width,
                                                       height,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &_videoTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    if(!err){
  
        glBindTexture(CVOpenGLESTextureGetTarget(_videoTexture), CVOpenGLESTextureGetName(_videoTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    }

}

- (void)bindTexture:(int)texLoc
{
    glActiveTexture(texLoc);
    glBindTexture(CVOpenGLESTextureGetTarget(_videoTexture), CVOpenGLESTextureGetName(_videoTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)performFacialDetectionWithSample:(CMSampleBufferRef)sampleBuffer pixels:(CVPixelBufferRef)pixelBuffer
{
    if(pixelBuffer == NULL){
        pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    }
    
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    if (attachments)
        CFRelease(attachments);
    NSDictionary *imageOptions = nil;
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    int exifOrientation;
    
    
    switch (curDeviceOrientation) {
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
            break;
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            //if (isUsingFrontFacingCamera)
            exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            //else
            //	exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            //if (isUsingFrontFacingCamera)
            exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            //else
            //	exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            break;
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
        default:
            exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
            break;
    }
    
    imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
    NSArray *features = [_faceDetector featuresInImage:ciImage options:imageOptions];
    
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false);

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self handleFaceFeatures:features
                     forVideoBox:clap
                     orientation:curDeviceOrientation];
    });
    
}

- (void)handleFaceFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
    if(self.faceDelegate){
        if(_previewLayer.superlayer){
            
            CGSize parentFrameSize = _previewLayer.superlayer.bounds.size;
            NSString *gravity = [_previewLayer videoGravity];
            CGRect previewRect = [NOCVideoSession videoPreviewBoxForGravity:gravity
                                                                  frameSize:parentFrameSize
                                                               apertureSize:clap.size];
            
            CGFloat widthScaleBy = previewRect.size.width / clap.size.height;
            CGFloat heightScaleBy = previewRect.size.height / clap.size.width;
            CGSize sizeScale = CGSizeMake(widthScaleBy, heightScaleBy);
            
            if(self.shouldOutlineFaces){
                if(!_isUsingGLOutput){
                    [self drawFaces:features inFrame:previewRect orientation:orientation scale:sizeScale];
                }else{
                    // OpenGL frame drawing not supported yet
                }
            }
            if(self.faceDelegate){
                [self.faceDelegate videoSession:self detectedFaces:features inFrame:previewRect orientation:orientation scale:sizeScale];
            }
            
        }
    }
}

- (void)drawFaces:(NSArray *)faceFeatures
          inFrame:(CGRect)previewFrame
      orientation:(UIDeviceOrientation)orientation
            scale:(CGSize)videoScale
{
    
    NSArray *previewSublayers = [NSArray arrayWithArray:[_previewLayer sublayers]];
	NSInteger sublayersCount = [previewSublayers count], currentSublayer = 0;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// Initially hide all the face layers
	for ( CALayer *layer in previewSublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES];
	}
    
    for ( CIFaceFeature *ff in faceFeatures ) {
        // find the correct position for the square layer within the previewLayer
        // the feature box originates in the bottom left of the video frame.
        // (Bottom right if mirroring is turned on)
        CGRect faceRect = [ff bounds];
        
        // flip preview width and height
        CGFloat temp = faceRect.size.width;
        faceRect.size.width = faceRect.size.height;
        faceRect.size.height = temp;
        temp = faceRect.origin.x;
        faceRect.origin.x = faceRect.origin.y;
        faceRect.origin.y = temp;
        
        // scale coordinates so they fit in the preview box, which may be scaled
        faceRect.size.width *= videoScale.width;
        faceRect.size.height *= videoScale.height;
        faceRect.origin.x *= videoScale.width;
        faceRect.origin.y *= videoScale.height;
        
        if ([self isMirrored])
            faceRect = CGRectOffset(faceRect,
                                    previewFrame.origin.x + previewFrame.size.width - faceRect.size.width - (faceRect.origin.x * 2),
                                    previewFrame.origin.y);
        else
            faceRect = CGRectOffset(faceRect,
                                    previewFrame.origin.x,
                                    previewFrame.origin.y);
        
        CALayer *featureLayer = nil;
        
        // re-use an existing layer if possible
        while ( !featureLayer && (currentSublayer < sublayersCount) ) {
            CALayer *currentLayer = [previewSublayers objectAtIndex:currentSublayer++];
            if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
                featureLayer = currentLayer;
                [currentLayer setHidden:NO];
            }
        }
        
        // create a new one if necessary
        if ( !featureLayer ) {
            featureLayer = [CALayer new];
            featureLayer.borderColor = [UIColor redColor].CGColor;
            featureLayer.borderWidth = 2.0f;
            [featureLayer setName:@"FaceLayer"];
            [_previewLayer addSublayer:featureLayer];
        }
        [featureLayer setFrame:faceRect];
        
        switch (orientation) {
            case UIDeviceOrientationPortrait:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
                break;
            case UIDeviceOrientationLandscapeLeft:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
                break;
            case UIDeviceOrientationLandscapeRight:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
                break;
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationFaceDown:
            default:
                break; // leave the layer in its last known orientation
        }

    }
    
	[CATransaction commit];
    
}

#pragma mark - Class Methods


+ (AVCaptureDevice *)frontFacingCamera
{
    return [self deviceWithPosition:AVCaptureDevicePositionFront];
}

+ (AVCaptureDevice *)rearFacingCamera
{
    return [self deviceWithPosition:AVCaptureDevicePositionBack];
}

+ (AVCaptureDevice *)deviceWithPosition:(AVCaptureDevicePosition)position
{
    //  look at all the video devices and get the first one that's on the front
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == position)
        {
            captureDevice = device;
            break;
        }
    }
    
    //  couldn't find one on the front, so just get the default video device.
    if ( ! captureDevice)
    {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return captureDevice;
}


// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}

@end

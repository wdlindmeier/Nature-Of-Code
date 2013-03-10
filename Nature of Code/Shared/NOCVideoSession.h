//
//  NOCVideoSession.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "NOCShaderProgram.h"

@protocol NOCVideoSessionFaceDelegate;

@interface NOCVideoSession : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
{
}

@property (nonatomic, weak) id<NOCVideoSessionFaceDelegate> faceDelegate;
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) BOOL shouldDetectFacesInBackground;

- (BOOL)isMirrored;
- (id)initWithFaceDelegate:(id<NOCVideoSessionFaceDelegate>)faceDelegate;

- (AVCaptureVideoPreviewLayer *)setupForPreviewWithDevice:(AVCaptureDevice *)device;
- (void)setupWithDevice:(AVCaptureDevice *)device inContext:(EAGLContext *)context;
- (void)teardown;
- (GLuint)bindTexture:(int)texLoc;
+ (AVCaptureDevice *)frontFacingCamera;
+ (AVCaptureDevice *)rearFacingCamera;
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize;

@end


@protocol NOCVideoSessionFaceDelegate <NSObject>

- (void)videoSession:(NOCVideoSession *)videoSession
       detectedFaces:(NSArray *)faceFeatures
             inFrame:(CGRect)previewFrame
         orientation:(UIDeviceOrientation)orientation
               scale:(CGSize)videoScale;

- (CGSize)sizeVideoFrameForSession:(NOCVideoSession *)session;

@end
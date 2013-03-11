//
//  NOCBeardMatrixViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/9/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NOC2DSketchViewController.h"
#import "NOCVideoSession.h"

@interface NOCBeardlySketchViewController : NOC2DSketchViewController <NOCVideoSessionFaceDelegate>
{
    NOCVideoSession *_videoSession;
}

- (IBAction)buttonCameraPressed:(id)sender;
- (IBAction)buttonResetPressed:(id)sender;

- (IBAction)buttonBeardStandardPressed:(id)sender;
- (IBAction)buttonBeardLincolnPressed:(id)sender;
- (IBAction)buttonBeardHoganPressed:(id)sender;
- (IBAction)buttonBeardGoteePressed:(id)sender;
- (IBAction)buttonBeardWolverinePressed:(id)sender;
- (IBAction)buttonBeardMuttonPressed:(id)sender;

@end

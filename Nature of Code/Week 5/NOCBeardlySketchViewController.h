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

@end

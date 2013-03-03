//
//  NOCFaceCapSketchViewController.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOC2DSketchViewController.h"
#import "NOCVideoSession.h"

@interface NOCFaceMeshSketchViewController : NOC2DSketchViewController <NOCVideoSessionFaceDelegate>
{
    NOCVideoSession *_videoSession;
}

@end

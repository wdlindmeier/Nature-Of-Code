//
//  NOCSharedFollowerTrail.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/31/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    int x;
    int y;
    int z;
} FollowerGridPosition;

const static int FollowerGridResolution = 100;
const static float GridHeightMulti = 1/0.75;

typedef int FollowerTrail[FollowerGridResolution][(int)(FollowerGridResolution*GridHeightMulti)][FollowerGridResolution];

@interface NOCSharedFollowerTrail : NSObject

- (void)addToHistoryToGridPosition:(FollowerGridPosition)position;
- (int)historyAtGridPosition:(FollowerGridPosition)position;
- (void)reset;

@end

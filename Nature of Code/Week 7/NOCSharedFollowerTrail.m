//
//  NOCSharedFollowerTrail.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/31/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSharedFollowerTrail.h"

@implementation NOCSharedFollowerTrail
{
    FollowerTrail _trail;
}

- (void)addToHistoryToGridPosition:(FollowerGridPosition)position
{
    _trail[position.x][position.y][position.z] += 1;
}

- (int)historyAtGridPosition:(FollowerGridPosition)position
{
    return _trail[position.x][position.y][position.z];
}

- (void)reset
{
    for(int x=0;x<FollowerGridResolution;x++){
        for(int y=0;y<(int)(FollowerGridResolution*GridHeightMulti);y++){
            for(int z=0;z<FollowerGridResolution;z++){
                _trail[x][y][z] = 0;
            }
        }
    }
}

@end

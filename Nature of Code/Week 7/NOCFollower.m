//
//  NOCFollower.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/31/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFollower.h"
#import "NOCColorHelpers.h"

@implementation NOCFollower
{
}

- (id)initWithRadius:(float)radius position:(GLKVector3)position mass:(float)mass
{
    self = [super initWithRadius:radius position:position mass:mass];
    if(self){
        self.fitness = 0;
    }
    return self;
}

- (void)glColor:(GLfloat *)components
{
    NOCColorComponentsForColor(components, self.color);
}

- (void)step
{
    int x = floor(((self.position.x + 1.0) / 2) * FollowerGridResolution);
    int y = floor(((self.position.y + (1.0*GridHeightMulti)) / (2*GridHeightMulti)) *
                  (FollowerGridResolution*GridHeightMulti));
    int z = floor(((self.position.z + 1.0) / 2) * FollowerGridResolution);
    
    x = CONSTRAIN(x, 0, FollowerGridResolution-1);
    y = CONSTRAIN(y, 0, (int)(FollowerGridResolution*GridHeightMulti)-1);
    z = CONSTRAIN(z, 0, FollowerGridResolution-1);
    
    FollowerGridPosition prevPosition = self.gridPosition;
    
    if(x != prevPosition.x ||
       y != prevPosition.y ||
       z != prevPosition.z){
        
        // The position has changed.
        // Update the history.
        
        FollowerGridPosition newPosition;
        newPosition.x = x;
        newPosition.y = y;
        newPosition.z = z;
        self.gridPosition = newPosition;
        
        if(!self.sharedTrail){
            NSLog(@"ERROR: Follower does not have a shared trail");
        }
        [self.sharedTrail addToHistoryToGridPosition:newPosition];
    }
    
    [super step];
}

- (void)updateFitnessWithTrailValue:(int)globalTrailValue
{
    int myTrailWeight = [self.sharedTrail historyAtGridPosition:self.gridPosition];
    // Play around w/ the weights a bit
    self.fitness += pow(globalTrailValue, 2) - pow(myTrailWeight, 3);
}

@end

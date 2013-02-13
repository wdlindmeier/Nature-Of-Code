//
//  NOCSensorWalker.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCDirectedWalker.h"
#import "CGGeometry.h"

@implementation NOCDirectedWalker

- (id)initWithSize:(CGSize)size position:(GLKVector2)position
{
    self = [super initWithSize:size position:position];
    if(self){
        self.probabilityOfFollowingPoint = 0.5f;
    }
    return self;
}

- (void)stepInRect:(CGRect)rect toward:(GLKVector2)followPoint
{
    
    // Account for the walker scale
    float followX = followPoint.x;
    float followY = followPoint.y;
    
    float xDelta = followX - self.position.x;
    float yDelta = followY - self.position.y;

    GLKVector2 vecFollow = GLKVector2Make(xDelta, yDelta);
    if(xDelta != 0 || yDelta != 0 ){
        vecFollow = GLKVector2Normalize(vecFollow);
    }
    
    // If our random number falls within the probability of following the point,
    // follow it. Otherwise chose another direction.
    float direction = RAND_SCALAR;
    if(direction > self.probabilityOfFollowingPoint){
        
        // Choose another direction
        int wasX = round(vecFollow.x);
        int wasY = round(vecFollow.y);
        int otherX = wasX;
        int otherY = wasY;
        while (otherX == wasX &&
               otherY == wasY) {
            otherX = (int)(arc4random() % 2) - 1;
            otherY = (int)(arc4random() % 2) - 1;
        }
        vecFollow.x = otherX;
        vecFollow.y = otherY;

    }
    
    // Move on pixel units
    float x = self.position.x + (round(vecFollow.x) * self.size.width);
    float y = self.position.y + (round(vecFollow.y) * self.size.height);

    // Dont let the walker move outside of the rect.
    float minX = rect.origin.x;
    float minY = rect.origin.y;
    float maxX = rect.origin.x + rect.size.width;
    float maxY = rect.origin.y + rect.size.height;
    
    // Dont let the walker move outside of the rect.
    // Also scale the rect to the size of the pixel.
    x = CONSTRAIN(x,minX,maxX);
    y = CONSTRAIN(y,minY,maxY);
    
    self.position = GLKVector2Make(x,y);

}

@end

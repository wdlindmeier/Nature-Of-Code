//
//  NOCSensorWalker.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCDirectedWalker.h"

@implementation NOCDirectedWalker

- (void)stepInRect:(CGRect)rect toward:(CGPoint)followPoint
{
    // Account for the walker scale
    float followX = followPoint.x / self.size.width;
    float followY = followPoint.y / self.size.height;
    
    float xDelta = followX - self.position.x;
    float yDelta = followY - self.position.y;

    GLKVector2 vecFollow = GLKVector2Make(xDelta, yDelta);
    if(xDelta != 0 || yDelta != 0 ){
        vecFollow = GLKVector2Normalize(vecFollow);
    }
    
    float x = self.position.x + round(vecFollow.x);
    float y = self.position.y + round(vecFollow.y);
    
    // Dont let the walker move outside of the rect.
    // Also scale the rect to the size of the pixel.
    x = CONSTRAIN(x,
                  rect.origin.x / self.size.width,
                  (rect.origin.x + rect.size.width) / self.size.width);
    y = CONSTRAIN(y,
                  rect.origin.y / self.size.height,
                  (rect.origin.y + rect.size.height) / self.size.height);
    
    self.position = CGPointMake(round(x),round(y));

}

@end

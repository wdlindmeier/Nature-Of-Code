//
//  NOCRandomWalker.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCRandomWalker.h"

@implementation NOCRandomWalker

- (void)stepInRect:(CGRect)rect
{
    int moveX = (arc4random() % 3) - 1;
    int moveY = (arc4random() % 3) - 1;
    
    // Move on pixel units
    float x = self.position.x + (moveX * self.size.width);
    float y = self.position.y + (moveY * self.size.height);
    
    // Dont let the walker move outside of the rect.
    float minX = rect.origin.x;
    float minY = rect.origin.y;
    float maxX = rect.origin.x + rect.size.width;
    float maxY = rect.origin.y + rect.size.height;
    
    x = CONSTRAIN(x,minX,maxX);
    y = CONSTRAIN(y,minY,maxY);
    
    self.position = GLKVector2Make(x, y);
}

@end

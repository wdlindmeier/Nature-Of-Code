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
    
    float x = self.position.x + moveX;
    float y = self.position.y + moveY;
    
    // Dont let the walker move outside of the rect.
    // Also scale the rect to the size of the pixel.
    x = CONSTRAIN(x,
                  rect.origin.x / self.size.width,
                  (rect.origin.x + rect.size.width) / self.size.width);
    y = CONSTRAIN(y,
                  rect.origin.y / self.size.height,
                  (rect.origin.y + rect.size.height) / self.size.height);
    
    self.position = GLKVector2Make(round(x),round(y));
}

@end

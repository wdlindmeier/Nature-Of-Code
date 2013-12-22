//
//  NOCMover.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCMover2D.h"
#import "NOCGeometryHelpers.h"

@implementation NOCMover2D

#pragma mark - Init

- (id)initWithSize:(GLKVector2)size position:(GLKVector2)position
{
    self = [super initWithSize:size position:position];
    if(self){
        self.velocity = GLKVector2Zero;
        self.acceleration = GLKVector2Zero;
        self.maxVelocity = 5.0f;
    }
    return self;
}

#pragma mark - Accessors

- (GLKVector2)forceOnPositionedMass:(id<NOCPositionedMass2D>)positionedMass
{
    GLKVector2 vecDir = GLKVector2Subtract(positionedMass.position, self.position);
    float magnitude = GLKVector2Length(vecDir);
    vecDir = GLKVector2Normalize(vecDir);
    float forceMagnitude = (kGravity * self.mass * positionedMass.mass) / (magnitude * magnitude);
    GLKVector2 vecForce = GLKVector2MultiplyScalar(vecDir, forceMagnitude);
    return vecForce;
}

#pragma mark - Movement / Update

- (void)stepInRect:(CGRect)rect shouldWrap:(BOOL)shouldWrap
{
    [self step];
    
    float x = self.position.x;
    float y = self.position.y;

    float minX = rect.origin.x;
    float maxX = (rect.origin.x + rect.size.width);
    float minY = rect.origin.y;
    float maxY = (rect.origin.y + rect.size.height);

    if(shouldWrap){
        // Wrap the mover around the rect
        if(x < minX) x = maxX + (x - minX);
        else if(x > maxX) x = minX + (x - maxX);
        
        if(y < minY) y = maxY + (y - minY);
        else if(y > maxY) y = minY + (y - maxY);
    }else{
        // Constrain
        // Dont let the walker move outside of the rect.
        x = CONSTRAIN(x, minX, maxX);
        y = CONSTRAIN(y, minY, maxY);
    }
    
    self.position = GLKVector2Make(x, y);

}

@end

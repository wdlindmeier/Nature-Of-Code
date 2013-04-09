//
//  NOCMover.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOCParticle2D.h"
#import "NOCPositionedMass.h"

@interface NOCMover2D : NOCParticle2D <NOCPositionedMass2D>

- (void)stepInRect:(CGRect)rect shouldWrap:(BOOL)shouldWrap;

@property (nonatomic, assign) float mass;

@end

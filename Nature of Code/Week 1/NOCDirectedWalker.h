//
//  NOCSensorWalker.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCWalker.h"

@interface NOCDirectedWalker : NOCWalker

@property (nonatomic, assign) float probabilityOfFollowingPoint;

- (void)stepInRect:(CGRect)rect toward:(GLKVector2)followPoint;

@end
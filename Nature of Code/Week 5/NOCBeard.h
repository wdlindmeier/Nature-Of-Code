//
//  NOCBeard.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/10/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum NOCBeardTypes {
    
    NOCBeardTypeNone = 0,
    NOCBeardTypeStandard
    
} NOCBeardType;

@interface NOCBeard : NSObject

@property (nonatomic, assign) GLKVector2 position;
@property (nonatomic, assign) float scale;

- (id)initWithBeardType:(NOCBeardType)type position:(GLKVector2)position;

- (NSArray *)hairs;
- (void)updateWithOffset:(GLKVector2)offset;

@end

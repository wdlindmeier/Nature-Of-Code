//
//  NOCBeard.h
//  Nature of Code
//
//  Created by William Lindmeier on 3/10/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOCVideoSession.h"

typedef enum NOCBeardTypes {
    
    NOCBeardTypeNone = 0,
    NOCBeardTypeStandard,
    NOCBeardTypeLincoln,
    NOCBeardTypeGotee,
    NOCBeardTypeWolverine,
    NOCBeardTypeHogan,
    NOCBeardTypeMutton
    
} NOCBeardType;

@interface NOCBeard : NSObject

@property (nonatomic, assign) GLKVector2 position;

- (id)initWithBeardType:(NOCBeardType)type
               position:(GLKVector2)position
                texture:(GLKTextureInfo *)texture;
- (void)reset;
- (NSArray *)hairs;
- (void)updateWithOffset:(GLKVector2)offset;
- (void)renderInMatrix:(GLKMatrix4)matrix;

@end

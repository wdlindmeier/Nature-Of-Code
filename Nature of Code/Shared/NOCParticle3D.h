//
//  NOCParticle3D.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NOCParticle3D : NSObject

@property (nonatomic, assign) GLKVector3 position;
@property (nonatomic, assign) GLKVector3 size;

- (id)initWithSize:(GLKVector3)size position:(GLKVector3)position;
- (GLKMatrix4)modelMatrix;
- (void)render;

@end

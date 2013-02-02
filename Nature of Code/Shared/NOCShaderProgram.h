//
//  NOCShaderProgram.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface NOCShaderProgram : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) GLuint glPointer;
@property (nonatomic, strong) NSDictionary *attributes;
@property (nonatomic, strong) NSArray *uniformNames;
@property (nonatomic, readonly) NSDictionary *uniformLocations;

- (id)initWithName:(NSString *)name;
- (BOOL)load;
- (void)unload;

@end

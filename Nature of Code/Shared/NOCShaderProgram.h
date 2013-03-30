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
- (void)use;

// Helpers
- (void)setFloat:(const GLfloat)f forUniform:(NSString *)uniformName;
- (void)setInt:(const GLint)i forUniform:(NSString *)uniformName;
- (void)setMatrix3:(const GLKMatrix3)mat forUniform:(NSString *)uniformName;
- (void)setMatrix4:(const GLKMatrix4)mat forUniform:(NSString *)uniformName;
- (void)set1DFloatArray:(const GLfloat[])array withNumElements:(int)num forUniform:(NSString *)uniformName;
- (void)set2DFloatArray:(const GLfloat[])array withNumElements:(int)num forUniform:(NSString *)uniformName;
- (void)set3DFloatArray:(const GLfloat[])array withNumElements:(int)num forUniform:(NSString *)uniformName;
- (void)set4DFloatArray:(const GLfloat[])array withNumElements:(int)num forUniform:(NSString *)uniformName;

@end

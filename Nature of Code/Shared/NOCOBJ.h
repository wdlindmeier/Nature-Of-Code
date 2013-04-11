//
//  WFObject.h
//  ObjLoader
//
//  Created by William Lindmeier on 8/27/12.
//  Copyright (c) 2012 William Lindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NOCOBJ : NSObject

@property (nonatomic, readonly) int numVerts;
@property (nonatomic, readonly) GLfloat *verts;
@property (nonatomic, readonly) GLfloat *normals;
@property (nonatomic, readonly) GLfloat *texCoords;
@property (nonatomic, readonly) GLfloat *vertsAndNormals;

- (id)initWithFilename:(NSString *)filename;

- (BOOL)parseObjFileAtPath:(NSString *)filePath;

@end

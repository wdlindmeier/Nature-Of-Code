//
//  WFObject.m
//  ObjLoader
//
//  Created by William Lindmeier on 8/27/12.
//  Copyright (c) 2012 William Lindmeier. All rights reserved.
//

#import "NOCOBJ.h"

@implementation NOCOBJ

- (id)initWithFilename:(NSString *)filename
{
    self = [super init];
    if(self){
        _verts = NULL;
        _texCoords = NULL;
        _normals = NULL;
        _vertsAndNormals = NULL;
        // Parse it on up
        NSString *objPath = [[NSBundle mainBundle] pathForResource:filename ofType:@"obj"];
        [self parseObjFileAtPath:objPath];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if(self){
        _verts = NULL;
        _texCoords = NULL;
        _normals = NULL;
        _vertsAndNormals = NULL;
    }
    return self;
}

- (void)dealloc
{
    [self clearArrays];
}

- (void)clearArrays
{
    if(_verts){
        free(_verts);
        _verts = NULL;
    }
    if(_texCoords){
        free(_texCoords);
        _texCoords = NULL;
    }
    if(_normals){
        free(_normals);
        _normals = NULL;
    }
    if(_vertsAndNormals){
        free(_vertsAndNormals);
        _vertsAndNormals = NULL;
    }
}

- (BOOL)parseObjFileAtPath:(NSString *)filePath
{
    [self clearArrays];
    
    NSError *loadError = nil;
    NSString *objContents = [NSString stringWithContentsOfFile:filePath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&loadError];
    objContents = [objContents stringByReplacingOccurrencesOfString:@"\\\n" withString:@""];
    
    if(loadError){
        NSLog(@"ERROR: Could not load obj file: %@", loadError);
        return NO;
    }else{
        // NSLog(@"Loaded OBJ File:\n%@", objContents);
    }
    
    NSError *expressionError = nil;
    NSRegularExpression *lineExp = [[NSRegularExpression alloc] initWithPattern:@"^(v|vn|vt|f)\\s+([e\\-\\d\\.\\s\\/]+)$"
                                                                        options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines
                                                                          error:&expressionError];
    if(!lineExp){
        
        NSLog(@"Regexp error: %@", expressionError);
        
    }else{

        NSMutableArray *verts = [NSMutableArray array];
        NSMutableArray *texs = [NSMutableArray array];
        NSMutableArray *normals = [NSMutableArray array];
        
        NSMutableArray *triangleStripVerts = [NSMutableArray array];
        NSMutableArray *triangleStripTexs = [NSMutableArray array];
        NSMutableArray *triangleStripNormals = [NSMutableArray array];
        
        // NOTE:
        // We're making 2 big assumptions here:
        // 1) That the regex results will come back in order and appending them to an array will retain their index.
        // 2) That the face list will come after all of the other arrays have been populated.
        [lineExp enumerateMatchesInString:objContents
                                  options:0
                                    range:NSMakeRange(0, objContents.length)
                               usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                   
                                   if(result.numberOfRanges > 2){
                                       NSString *lineType = [[objContents substringWithRange:[result rangeAtIndex:1]] lowercaseString];
                                       NSString *lineValue = [objContents substringWithRange:[result rangeAtIndex:2]];
                                       NSCharacterSet *deliniations = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                                       NSArray *values = [lineValue componentsSeparatedByCharactersInSet:deliniations];
                                       
                                       // NSLog(@"lineType %@", lineType);
                                       
                                       if([lineType isEqualToString:@"f"]){
                                           
                                           // Face
                                           // int numVerts = values.count;
                                           
                                           // Create degenerate triangles because we'll be drawing in triangle fans.
                                           // TODO: Make this an option?
                                           
                                           NSMutableArray *degenerateValues = [NSMutableArray arrayWithArray:values];
                                           
                                           // Creating invisible triangles to connect the faces
                                           
                                           [degenerateValues insertObject:[values objectAtIndex:0]
                                                                  atIndex:0];
                                           [degenerateValues addObject:[values objectAtIndex:0]];
                                           [degenerateValues addObject:[values objectAtIndex:0]];
                                                                                   
                                           for(NSString *pointVals in degenerateValues){
                                               
                                               if(pointVals.length == 0) continue; // I guess this can be empty
                                               
                                               // Split these into constituent parts
                                               // 0==vert,1==tex,2==normal
                                               NSArray *indexes = [pointVals componentsSeparatedByString:@"/"];
                                               for(int j=0;j<indexes.count;j++){
                                                   NSString *val = [indexes objectAtIndex:j];
                                                   int idx = [val integerValue];
                                                   // NOTE: OBJ files have 1 based indexes
                                                   idx-=1;
                                                   switch (j) {
                                                       case 0: // Vertex
                                                           if(verts.count > idx){
                                                               [triangleStripVerts addObject:[verts objectAtIndex:idx]];
                                                           }else{
                                                               NSLog(@"ERROR verts.count (%i) <= idx (%i) val (%@) pointVals (%@)",
                                                                     verts.count,
                                                                     idx,
                                                                     val,
                                                                     pointVals);
                                                           }
                                                           break;
                                                       case 1: // Texture
                                                           if(texs.count > idx){
                                                               [triangleStripTexs addObject:[texs objectAtIndex:idx]];
                                                           }else{
                                                               NSLog(@"ERROR texs.count (%i) <= idx (%i) val (%@)",
                                                                     texs.count,
                                                                     idx,
                                                                     val);
                                                           }
                                                           break;
                                                       case 2: // Normal
                                                           if(normals.count > idx){
                                                               [triangleStripNormals addObject:[normals objectAtIndex:idx]];
                                                           }else{
                                                               NSLog(@"ERROR normals.count (%i) <= idx (%i) val (%@)",
                                                                     normals.count,
                                                                     idx,
                                                                     val);
                                                           }
                                                           break;
                                                   }
                                               }
                                           }
                                           
                                       }else{

                                           NSMutableArray *valNumbers = [NSMutableArray array];
                                           for(NSString *valString in values){
                                               [valNumbers addObject:[NSNumber numberWithFloat:[valString floatValue]]];
                                           }
                                           
                                           if([lineType isEqualToString:@"v"]){
                                               // Vertex
                                               [verts addObject:valNumbers];
                                           }else if([lineType isEqualToString:@"vt"]){
                                               // Tex Coord
                                               [texs addObject:valNumbers];
                                           }else if([lineType isEqualToString:@"vn"]){
                                               // Normal
                                               [normals addObject:valNumbers];
                                           }
                                       }
                                   }

                               }];
        
        // Convert the NSArrays into GLFloat arrays
        // NOTE: The NSArrays are collections of 3

        _verts = malloc(sizeof(GLfloat) * triangleStripVerts.count * 3);
        _texCoords = malloc(sizeof(GLfloat) * triangleStripTexs.count * 2);
        _normals = malloc(sizeof(GLfloat) * triangleStripNormals.count * 3);
        _vertsAndNormals = malloc(sizeof(GLfloat) * ((triangleStripVerts.count * 3) + (triangleStripNormals.count * 3)));

        int idx=0;
        for(NSArray *coords in triangleStripVerts){
            for(NSNumber *coord in coords){
                int row = idx/3;
                int column = idx%3;
                float val = [coord floatValue];
                _verts[idx++] = val;
                _vertsAndNormals[(row*6)+column] = val;
            }
        }


        idx=0;
         // Crazy. There can be 3 tex coords. Just truncating the last one.
        for(NSArray *coords in triangleStripTexs){
            for(int t=0;t<2;t++){
                NSNumber *coord = [coords objectAtIndex:t];
                _texCoords[idx++] = [coord floatValue];
            }
        }
        
        idx=0;
        for(NSArray *coords in triangleStripNormals){
            for(NSNumber *coord in coords){
                int row = idx/3;
                int column = idx%3;
                float val = [coord floatValue];
                _normals[idx++] = val;
                _vertsAndNormals[(row*6)+column+3] = val;
            }
        }
         
         _numVerts = triangleStripVerts.count; 
        
    }
    
    return YES;
}


@end

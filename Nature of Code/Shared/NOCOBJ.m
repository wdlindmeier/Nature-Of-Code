//
//  WFObject.m
//  ObjLoader
//
//  Created by William Lindmeier on 8/27/12.
//  Copyright (c) 2012 William Lindmeier. All rights reserved.
//

#import "NOCOBJ.h"
#import "NOCOpenGLHelpers.h"
#import "NOCGeometryHelpers.h"

@implementation NOCOBJ
{
    int *_faceIdxs;
    int _numFaces;
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}

- (id)initWithFilename:(NSString *)filename
{
    self = [super init];
    if(self){
        [self initNOCOBJ];
        // Parse it on up
        NSString *objPath = [[NSBundle mainBundle] pathForResource:filename ofType:@"obj"];
        if(objPath){
            [self parseObjFileAtPath:objPath];
        }else{
            return nil;
        }
    }
    return self;
}

- (id)init
{
    self = [super init];
    if(self){
        [self initNOCOBJ];
    }
    return self;
}

- (void)initNOCOBJ
{
    _verts = NULL;
    _texCoords = NULL;
    _normals = NULL;
    _vertsAndNormals = NULL;
    _faceIdxs = NULL;
    _vertexArray = 0;
    _vertexBuffer = 0;
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
    if(_faceIdxs){
        free(_faceIdxs);
        _faceIdxs = NULL;
    }
    if(_vertexBuffer){
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    if(_vertexArray){
        glDeleteVertexArraysOES(1, &_vertexArray);
        _vertexArray = 0;
    }
}

- (void)recalculateNormals
{
    int i=0;
    while(i<_numVerts){
        int startVertIdx = i;
        GLKVector3 face[3];
        int idxV=0;
        int attempt=0;
        GLKVector3 lastVec;
        while (idxV < 3) {
            attempt++;        
            GLKVector3 vec = GLKVector3Make(_verts[(i*3)+0],
                                            _verts[(i*3)+1],
                                            _verts[(i*3)+2]);
            if(idxV == 0 || !GLKVector3Equal(lastVec, vec) || attempt > 10){
                face[idxV] = vec;
                lastVec = vec;
                idxV++;
            } // else skip
            i++;
            if(i>=_numVerts-1){
                break;
            }
        }
        
        // Keep rolling until we hit 2 degenerate triangles that match the first.
        // This assumes the specific triangle strip implementation that this class is using.
        int numDG = 0;
        while (numDG<2 && i<_numVerts) {
            GLKVector3 nextVec = GLKVector3Make(_verts[(i*3)+0],
                                                _verts[(i*3)+1],
                                                _verts[(i*3)+2]);
            if(GLKVector3Equal(nextVec, face[0])){
                numDG++;
            }
            i++;
        }        
        
        // We're going to pick whichever normal is further from the center.
        // Total hack brah.
        GLKVector3 norm = NOCSurfaceNormalForTriangle(face[0], face[1], face[2]);
        GLKVector3 normNeg = GLKVector3MultiplyScalar(norm, -1);
        
        GLKVector3 faceCenter = GLKVector3Make((face[0].x + face[1].x + face[2].x) / 3.0,
                                               (face[0].y + face[1].y + face[2].y) / 3.0,
                                               (face[0].z + face[1].z + face[2].z) / 3.0);
        
        GLKVector3 vNeg = GLKVector3Add(faceCenter, normNeg);
        GLKVector3 vPos = GLKVector3Add(faceCenter, norm);
        
        norm = GLKVector3Length(vNeg) > GLKVector3Length(vPos) ? normNeg : norm;
        
        for(int n=startVertIdx;n<i;n++){
            _normals[n*3] = norm.x;
            _normals[n*3+1] = norm.y;
            _normals[n*3+2] = norm.z;
        }
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
        
        NSMutableArray *faceIndexes = [NSMutableArray array];
        
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
                                           
                                           // This is the start of the "face" (ignoring the degen triangles)
                                           [faceIndexes addObject:@(triangleStripVerts.count)];
                                           
                                           [degenerateValues addObject:[values objectAtIndex:0]];
                                           [degenerateValues addObject:[values objectAtIndex:0]];
#define RECALCULATE_NORMALS 0
#if RECALCULATE_NORMALS
                                           GLKVector3 faceVecs[degenerateValues.count];
                                           int iVec = 0;
#endif
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
                                                               NSArray *idxVerts = [verts objectAtIndex:idx];
                                                               [triangleStripVerts addObject:idxVerts];
#if RECALCULATE_NORMALS
                                                               if(idxVerts.count == 3){
                                                                   faceVecs[iVec] = GLKVector3Make([idxVerts[0] floatValue],
                                                                                                   [idxVerts[1] floatValue],
                                                                                                   [idxVerts[2] floatValue]);
                                                                   iVec++;
                                                               }else{
                                                                   NSLog(@"WARNING: Can't recompute face normals for verts with %i count",
                                                                         idxVerts.count);
                                                               }
#endif
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
#if !RECALCULATE_NORMALS
                                                           if(normals.count > idx){
                                                               [triangleStripNormals addObject:[normals objectAtIndex:idx]];
                                                           }else{
                                                               NSLog(@"ERROR normals.count (%i) <= idx (%i) val (%@)",
                                                                     normals.count,
                                                                     idx,
                                                                     val);
                                                           }
#endif
                                                           break;
                                                   }
                                               }
                                           }
#if RECALCULATE_NORMALS
                                           // Just use the first 3 non-degenerate verts
                                           GLKVector3 faceNormal = NOCSurfaceNormalForTriangle(faceVecs[1],
                                                                                               faceVecs[2],
                                                                                               faceVecs[3]);
                                           NSArray *normArray = @[@(faceNormal.x),
                                                                  @(faceNormal.y),
                                                                  @(faceNormal.z)];
                                           for(int n=0;n<degenerateValues.count;n++){
                                               [triangleStripNormals addObject:normArray];
                                           }
#endif
                                           
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
        _numFaces = [faceIndexes count];
        _faceIdxs = malloc(sizeof(int) * faceIndexes.count);

        int idx=0;
        for(NSArray *coords in triangleStripVerts){
            for(NSNumber *coord in coords){
                int row = idx/3;
                int column = idx%3;
                float val = [coord floatValue];
                _verts[idx] = val;
                _vertsAndNormals[(row*6)+column] = val;
                idx++;
            }
        }
        
        idx=0;
        for(NSNumber *n in faceIndexes){
            _faceIdxs[idx] = [n intValue];
            idx++;
        }

        idx=0;
         // Crazy. There can be 3 tex coords. Just truncating the last one.
        for(NSArray *coords in triangleStripTexs){
            for(int t=0;t<2;t++){
                NSNumber *coord = [coords objectAtIndex:t];
                _texCoords[idx] = [coord floatValue];
                idx++;
            }
        }

        idx=0;
        for(NSArray *coords in triangleStripNormals){
            for(NSNumber *coord in coords){
                int row = idx/3;
                int column = idx%3;
                float val = [coord floatValue];
                _normals[idx] = val;
                _vertsAndNormals[(row*6)+column+3] = val;
                idx++;
            }
        }         
        _numVerts = triangleStripVerts.count;
        
    }
    
    [self genBuffer];
    
    return YES;
}

- (void)genBuffer
{ 
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);

    glBufferData(GL_ARRAY_BUFFER,
                 //sizeof(GLfloat) * _numVerts * 3 * 2, // *2 for verts & normals
                 sizeof(GLfloat) * ((_numVerts * 3) + (_numVerts * 3)),
                 _vertsAndNormals,
                 GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArrayOES(0);

}

@end

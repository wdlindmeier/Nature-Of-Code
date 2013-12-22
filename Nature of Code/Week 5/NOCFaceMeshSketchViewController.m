//
//  NOCFaceCapSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#define USE_SERIALIZED_TRIANGLES  1

#import "NOCFaceMeshSketchViewController.h"
#import "Edgy.h"
#import "NOCFrameBuffer.h"

#if USE_SERIALIZED_TRIANGLES
    #import "NOCCannedTriangles.h"
#endif

const static int NumPoints = 50;
const static int NumTriangulations = 5;

@interface NOCFaceMeshSketchViewController ()
{
    NSArray *_faceRects;
    float _curveStep;
    float _distStep;
    GLfloat* _meshVerts[NumTriangulations];
    GLfloat* _meshTex[NumTriangulations];
    int _numMeshVerts[NumTriangulations];
    float _unitMesh;
    int _numFramesWithoutFace;

#if USE_SERIALIZED_TRIANGLES
    BOOL _didTriangulate;
#endif
    
}

@end

static NSString * TextureShaderName = @"Texture";
static NSString * BlendShaderName = @"TextureBlend";
static NSString * ColorShaderName = @"ColoredVerts";
static NSString * FaceShaderName = @"Triangulation";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformTexture = @"texture";
static NSString * UniformTextureA = @"textureA";
static NSString * UniformTextureB = @"textureB";
static NSString * UniformAlphaBlend = @"alphaB";
static NSString * UniformTranslation = @"translation";
static NSString * UniformScale = @"scale";

// NOTE:
// This doesn't have to be very big, because the video is small
static const int FBODimension = 128;

@implementation NOCFaceMeshSketchViewController

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - App Loop

- (void)setup
{
    // Shaders    
    NOCShaderProgram *texShader = [[NOCShaderProgram alloc] initWithName:TextureShaderName];
    texShader.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                              @"texCoord" : @(GLKVertexAttribTexCoord0) };
    texShader.uniformNames = @[ UniformMVProjectionMatrix, UniformTexture ];
    [self addShader:texShader named:TextureShaderName];
    
    NOCShaderProgram *blendShader = [[NOCShaderProgram alloc] initWithName:BlendShaderName];
    blendShader.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                @"texCoordA" : @(GLKVertexAttribTexCoord0),
                                @"texCoordB" : @(GLKVertexAttribTexCoord1)};
    blendShader.uniformNames = @[ UniformMVProjectionMatrix, UniformTextureA, UniformTextureB, UniformAlphaBlend ];
    [self addShader:blendShader named:BlendShaderName];
    
    NOCShaderProgram *shaderFace = [[NOCShaderProgram alloc] initWithName:FaceShaderName];
    shaderFace.attributes = @{@"position" : @(GLKVertexAttribPosition), @"texCoord" : @(GLKVertexAttribTexCoord0)};
    shaderFace.uniformNames = @[UniformMVProjectionMatrix, UniformTexture, UniformTranslation, UniformScale];
    [self addShader:shaderFace named:FaceShaderName];
    
    NOCShaderProgram *colorShader = [[NOCShaderProgram alloc] initWithName:ColorShaderName];
    colorShader.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                @"color" : @(GLKVertexAttribColor) };
    colorShader.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:colorShader named:ColorShaderName];

    // Triangles
    _curveStep = 0.415365;
    _distStep  = 0.019092;
    
    for(int i=0;i<NumTriangulations;i++){
        _meshVerts[i] = NULL;
        _meshTex[i] = NULL;
    }
    
    // Video
    _videoSession = [[NOCVideoSession alloc] initWithFaceDelegate:self];
    [_videoSession setupWithDevice:[NOCVideoSession frontFacingCamera] inContext:self.context];
    
    [self reTriangulate];
    
}

- (void)resize
{
    [super resize];
}

- (void)update
{
    //...
}

- (void)clear
{
    glClearColor(0,0,0,1);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)draw
{
    
    [self clear];
    
    // Account for camera texture orientation
    float scaleX = [_videoSession isMirrored] ? -1 : 1;
    float scaleY = -1;
    
    GLKMatrix4 matTexture = GLKMatrix4MakeScale(scaleX, scaleY, 1);
    matTexture = GLKMatrix4RotateZ(matTexture, M_PI * 0.5);
    matTexture = GLKMatrix4Multiply(matTexture, _projectionMatrix2D);
    
    // Draw the video background
    
    NOCShaderProgram *texShader = [self shaderNamed:TextureShaderName];
    [texShader use];
    [texShader setMatrix4:matTexture forUniform:UniformMVProjectionMatrix];
    [_videoSession bindTexture:0];
    [texShader setInt:0 forUniform:UniformTexture];
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_screen3DBillboardVertexData);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &kSquare3DTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    [self renderFaceMeshInMat:matTexture];
    
}

- (void)renderFaceMeshInMat:(GLKMatrix4)mat
{
    // Draw the mesh
    
    if(_faceRects.count > 0){
        
        NOCShaderProgram *shaderFace = [self shaderNamed:FaceShaderName];
        [shaderFace use];
        
        [_videoSession bindTexture:0];
        [shaderFace setInt:0 forUniform:UniformTexture];
        
        for(NSValue *v in _faceRects){
            
            CGRect faceRect = [v CGRectValue];
            CGPoint posFace = CGPointMake(CGRectGetMidX(faceRect), CGRectGetMidY(faceRect));
            float widthFace = CGRectGetWidth(faceRect);
            
            GLKMatrix4 matMesh = mat;
            
            matMesh = GLKMatrix4Scale(matMesh, 1.0, 1.0/_viewAspect, 1.0);
            
            float scale = widthFace / _unitMesh * 1.75; // Eyeballing the amount of coverage
            
            [shaderFace setFloat:scale
                      forUniform:UniformScale];
            
            GLfloat translate[] = { posFace.x, // This is actually y
                posFace.y * _viewAspect, // This is actually x
                0.0
            };
            
            [shaderFace set3DFloatArray:translate
                        withNumElements:1
                             forUniform:UniformTranslation];
            
            // Loop over the triangulations
            int meshNum = (self.frameCount / NumTriangulations) % NumTriangulations; // slows it down a bit so each frame gets NumTriangulations frames
            GLfloat *meshVerts = _meshVerts[meshNum];
            GLfloat *meshTex = _meshTex[meshNum];
            int numVerts = _numMeshVerts[meshNum];
            
            if(meshVerts){
                
                [shaderFace setMatrix4:matMesh forUniform:UniformMVProjectionMatrix];
                
                glEnableVertexAttribArray(GLKVertexAttribPosition);
                glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, meshVerts);
                
                glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
                glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, meshTex);
                
                glDrawArrays(GL_TRIANGLES, 0, numVerts);
                
            }else{
                
                NSLog(@"NO MESH VERTS");
                
            }
            
        }
        
    }
}

- (void)teardown
{
    [super teardown];
    
#if !USE_SERIALIZED_TRIANGLES
    for(int i=0;i<NumTriangulations;i++){
        GLfloat *meshVerts = _meshVerts[i];
        if(meshVerts) free(meshVerts);
        GLfloat *meshTex = _meshTex[i];
        if(meshTex) free(meshTex);
    }
#endif
    
    [_videoSession teardown];
    _videoSession = nil;
}

#pragma mark - Video 

- (CGSize)sizeVideoFrameForSession:(NOCVideoSession *)session
{
    return _sizeView;
}

- (void)videoSession:(NOCVideoSession *)videoSession
       detectedFaces:(NSArray *)faceFeatures
             inFrame:(CGRect)previewFrame
         orientation:(UIDeviceOrientation)orientation
               scale:(CGSize)videoScale
{

    static const int NumEmptyFramesForClearingFaces = 5;
    
    if(faceFeatures.count == 0){
        
        _numFramesWithoutFace++;
        
        if(_numFramesWithoutFace > NumEmptyFramesForClearingFaces){
            
            // Only reset if the face is gone for a bit.
            // The detector can be a little choppy.
            _faceRects = nil;
        }
        // otherwise, just keep the current rect
        
    }else{
        
        _numFramesWithoutFace = 0;
    
        NSMutableArray *rects = [NSMutableArray arrayWithCapacity:faceFeatures.count];

        for ( CIFaceFeature *ff in faceFeatures ) {

            CGRect faceRect = [ff bounds];
            
            // Scale up from image size to view size
            faceRect = CGRectApplyAffineTransform(faceRect, CGAffineTransformMakeScale(videoScale.width, videoScale.height));

            // Mirror if source is mirrored
            if ([_videoSession isMirrored])
                faceRect = CGRectApplyAffineTransform(faceRect, CGAffineTransformMakeScale(-1, 1));
            
            // Translate the rect origin
            faceRect = CGRectApplyAffineTransform(faceRect, CGAffineTransformMakeTranslation(previewFrame.origin.x, previewFrame.origin.y));

            // Convert to GL space
            GLKVector2 glPos = NOCGLPositionFromCGPointInRect(faceRect.origin, previewFrame);
            float scale = 2.0f / previewFrame.size.width;
            GLKVector2 glSize = GLKVector2Make(faceRect.size.width * scale,
                                               faceRect.size.height * scale);
            
            [rects addObject:[NSValue valueWithCGRect:CGRectMake(glPos.x, glPos.y,
                                                                 glSize.x, glSize.y)]];

        }

        _faceRects = [NSArray arrayWithArray:rects];
        
    }

}


#pragma mark - Triangulation

- (BOOL)shouldDrawTriangle:(DelaunayTriangle *)t
{
    float aspectY = 1.0f / _viewAspect;
    for(DelaunayEdge *edge in t.edges)
    {
        for(DelaunayPoint *p in edge.points){
            if(fabs(p.x) >= 1.0 || fabs(p.y) >= aspectY){
                return NO;
            }
        }
    }
    
    return YES;
}

- (void)reTriangulate
{

#if !USE_SERIALIZED_TRIANGLES
    
    float minX = 0;
    float maxX = 0;
    float minY = 0;
    float maxY = 0;
    
    NSMutableArray *serializedVerts = [NSMutableArray arrayWithCapacity:500];
    NSMutableArray *serializedTex = [NSMutableArray arrayWithCapacity:500];
    
    for(int t=0;t<NumTriangulations;t++){
        
        DelaunayTriangulation *triangulation = [DelaunayTriangulation triangulationWithGLSize:CGSizeMake(2.0, 2.0/_viewAspect)];
        
        float stepAllowance = _curveStep * NumPoints;
        
        for(int i=0;i<NumPoints;i++){
            
            float amtDone = (float)i/NumPoints;
            float additionalStep = stepAllowance * amtDone;
            
            int stepper = i;//+self.frameCount;
            float cStep = stepper*_curveStep;
            
            cStep += additionalStep;
            
            float dStep = i*_distStep;
            
            // Randomize the distance for a jittery effect
            dStep *= 1.0 + ((RAND_SCALAR * 0.5) - 0.25);
            
            float x = cosf(cStep) * dStep;
            float y = sinf(cStep) * dStep / _viewAspect;
            
            // If we're outside of the bounds, lets just quit.
            float maxBounds = 1.0;
            if(fabs(x) > maxBounds && fabs(y) > maxBounds){
                
                NSLog(@"quitting at %i points", i);
                break;
                
            }else{
                
                DelaunayPoint *newPoint = [DelaunayPoint pointAtX:x
                                                             andY:y];
                
                [triangulation addPoint:newPoint withColor:nil];
                
            }
            
        }
        
        int numVerts = 0;
        for (DelaunayTriangle *triangle in triangulation.triangles){
            if([self shouldDrawTriangle:triangle]){
                int edgeCount = triangle.edges.count;
                int numPoints = edgeCount;
                numVerts += numPoints;
            }
        }
        
        _numMeshVerts[t] = numVerts;
        
        GLfloat *meshVerts = _meshVerts[t];
        if(meshVerts) free(meshVerts);
        meshVerts = malloc(sizeof(GLfloat) * numVerts * 3);
        _meshVerts[t] = meshVerts;
        
        GLfloat *meshTex = _meshTex[t];
        if(meshTex) free(meshTex);
        meshTex = malloc(sizeof(GLfloat) * numVerts * 2);
        _meshTex[t] = meshTex;
        
        int idxVert = 0;
        int idxTex = 0;
        
        [serializedVerts addObject:[NSString stringWithFormat:@"static float NOCDelaunayVerts%i[] = {", t]];
        [serializedTex addObject:[NSString stringWithFormat:@"static float NOCDelaunayTex%i[] = {", t]];
        
        for (DelaunayTriangle *triangle in triangulation.triangles)
        {
            if([self shouldDrawTriangle:triangle]){
                
                int edgeCount = triangle.edges.count;
                int numPoints = edgeCount;
                
                GLKVector2 texCoordAvg = GLKVector2Zero;
                
                DelaunayPoint *prevPoint = triangle.startPoint;
                
                for(int i=0;i<edgeCount;i++)
                {
                    DelaunayEdge *edge = triangle.edges[i];
                    DelaunayPoint *p2 = [edge otherPoint:prevPoint];
                    
                    float x = p2.x;
                    float y = p2.y;
                    float z = 0;
                    
                    if(x < minX) minX = x;
                    if(x > maxX) maxX = x;
                    if(y < minY) minY = y;
                    if(y > maxY) maxY = y;
                    
                    // Verts
                    meshVerts[idxVert+0] = x;
                    meshVerts[idxVert+1] = y;
                    meshVerts[idxVert+2] = z;
                    idxVert+=3;
                    // Serialize the data
                    [serializedVerts addObject:[NSString stringWithFormat:@"%f,%f,%f", x, y, z]];
                    
                    // Text coords
                    float texCoordX = 0.5 + (x * 0.5);
                    vertTextCoordAvg.x += texCoordX;
                    
                    float texCoordY = 0.5 + (y * -0.5);
                    vertTextCoordAvg.y += texCoordY;
                    
                    prevPoint = p2;
                    
                }
                
                // Average the text coords.
                // These are unevenly weighted when
                // drawing triangle edges, but we're not using
                // the texture in that case
                texCoordAvg = GLKVector2DivideScalar(texCoordAvg, numPoints);
                
                // Poor mans triangle color average.
                for(int i=0;i<numPoints;i++){
                    meshTex[idxTex+0] = texCoordAvg.x;
                    meshTex[idxTex+1] = texCoordAvg.y;
                    idxTex+=2;
                    
                    [serializedTex addObject:[NSString stringWithFormat:@"%f,%f", texCoordAvg.x, texCoordAvg.y]];
                }
            }
        }
        [serializedVerts addObject:@"};"];
        [serializedTex addObject:@"};"];
    }
    
    // NOTE: These have to be cleaned up a bit for consumption
    NSLog(@"\n%@\n;", [serializedVerts componentsJoinedByString:@",\n"]);
    NSLog(@"\n%@\n", [serializedTex componentsJoinedByString:@",\n"]);
    
    _unitMesh = maxY - minY;
    
#else
    
    if(!_didTriangulate){
        
        for(int t=0;t<NumTriangulations;t++){

            float *vertCoords;
            float *texCoords;
            int numVerts = 0;
            switch (t) {
                case 0:
                    vertCoords = NOCDelaunayVerts0;
                    numVerts = sizeof(NOCDelaunayVerts0) / sizeof(float) / 3;
                    texCoords = NOCDelaunayTex0;
                    break;
                case 1:
                    vertCoords = NOCDelaunayVerts1;
                    numVerts = sizeof(NOCDelaunayVerts1) / sizeof(float) / 3;
                    texCoords = NOCDelaunayTex1;
                    break;
                case 2:
                    vertCoords = NOCDelaunayVerts2;
                    numVerts = sizeof(NOCDelaunayVerts2) / sizeof(float) / 3;
                    texCoords = NOCDelaunayTex2;
                    break;
                case 3:
                    vertCoords = NOCDelaunayVerts3;
                    numVerts = sizeof(NOCDelaunayVerts3) / sizeof(float) / 3;
                    texCoords = NOCDelaunayTex3;
                    break;
                case 4:
                    vertCoords = NOCDelaunayVerts4;
                    numVerts = sizeof(NOCDelaunayVerts4) / sizeof(float) / 3;
                    texCoords = NOCDelaunayTex4;
                    break;
                default:
                    @throw @"ERROR: There are only 5 serialized triangle meshes";
                    return;
            }

            _numMeshVerts[t] = numVerts;
            
            float maxY = 0;
            float minY = 0;
            for(int i=0;i<numVerts;i++){
                float y = vertCoords[i*3+1];
                if(y < minY) minY = y;
                if(y > maxY) maxY = y;
            }
            
            _unitMesh = maxY - minY;
            _meshVerts[t] = vertCoords;
            _meshTex[t] = texCoords;

        }
        
        _didTriangulate = YES;
        
    }
    
#endif
        
}

#pragma mark - Touch

#if !USE_SERIALIZED_TRIANGLES

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        if(t.tapCount > 1){
            CGPoint posTouch = [t locationInView:self.view];
            float scalarX = posTouch.x / _sizeView.width;
            float scalarY = posTouch.y / _sizeView.height;
            _curveStep = scalarX * 0.5;
            _distStep = scalarY * 0.1;
            NSLog(@"_curveStep %f _distStep %f", _curveStep, _distStep);
            [self reTriangulate];
        }
    }
}

#endif

@end

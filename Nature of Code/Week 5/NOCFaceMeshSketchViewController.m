//
//  NOCFaceCapSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFaceMeshSketchViewController.h"
#import "Edgy.h"

const static int NumPoints = 50;

@interface NOCFaceMeshSketchViewController ()
{
    UIView *_viewVideoPreview;
    NSArray *_faceRects;
    
    // For the triangle mesh
    float _curveStep;
    float _distStep;
    GLfloat *_meshVecs;
    GLfloat *_meshTex;
    int _numVerts;
    float _unitMesh;
    DelaunayTriangulation *_triangulation;
    int _numFramesWithoutFace;
}

@end

static NSString * TextureShaderName = @"Texture";
static NSString * FaceShaderName = @"Triangulation";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformTexture = @"texture";
static NSString * UniformTranslation = @"translation";
static NSString * UniformScale = @"scale";

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
    

    NOCShaderProgram *shaderFace = [[NOCShaderProgram alloc] initWithName:FaceShaderName];
    shaderFace.attributes = @{@"position" : @(GLKVertexAttribPosition), @"texCoord" : @(GLKVertexAttribTexCoord0)};
    shaderFace.uniformNames = @[UniformMVProjectionMatrix, UniformTexture, UniformTranslation, UniformScale];

    self.shaders = @{ FaceShaderName : shaderFace, TextureShaderName : texShader };
    
    // Triangles
    _curveStep = 0.415365;
    _distStep  = 0.019092;
    
    _meshVecs = NULL;
    _meshTex = NULL;
    
    // Video
    _videoSession = [[NOCVideoSession alloc] initWithFaceDelegate:self];
    [_videoSession setupWithDevice:[NOCVideoSession frontFacingCamera] inContext:self.context];

}

- (void)resize
{
    [super resize];
    [self reTriangulate];
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
    
    NOCShaderProgram *texShader = self.shaders[TextureShaderName];
    [texShader use];
    [texShader setMatrix:matTexture forUniform:UniformMVProjectionMatrix];
    [_videoSession bindTexture:0];
    [texShader setInt:0 forUniform:UniformTexture];
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_screen3DBillboardVertexData);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &Square3DTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // Draw the mesh
    
    if(_faceRects.count > 0){
        
        NOCShaderProgram *shaderFace = self.shaders[FaceShaderName];
        [shaderFace use];

        [_videoSession bindTexture:0];
        [shaderFace setInt:0 forUniform:UniformTexture];
        
        for(NSValue *v in _faceRects){
            
            CGRect faceRect = [v CGRectValue];
            CGPoint posFace = CGPointMake(CGRectGetMidX(faceRect), CGRectGetMidY(faceRect));
            float widthFace = CGRectGetWidth(faceRect);
    
            GLKMatrix4 matMesh = matTexture;
            matMesh = GLKMatrix4Scale(matMesh, 1.0, 1.0/_viewAspect, 1.0);
            
            float scale = widthFace / _unitMesh;

            [shaderFace setFloat:scale
                      forUniform:UniformScale];
            
            GLfloat translate[] = { posFace.x, // This is actually y
                                    posFace.y * _viewAspect, // This is actually x
                                    0.0
                                   };

            [shaderFace set3DFloatArray:translate
                        withNumElements:1
                             forUniform:UniformTranslation];

            if(_meshVecs){
                
                [shaderFace setMatrix:matMesh forUniform:UniformMVProjectionMatrix];

                glEnableVertexAttribArray(GLKVertexAttribPosition);
                glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, _meshVecs);

                glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
                glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, _meshTex);
                
                glDrawArrays(GL_TRIANGLES, 0, _numVerts);
                
            }
            
        }
        
    }

}

- (void)teardown
{
    [super teardown];
    
    if(_meshVecs) free(_meshVecs);
    if(_meshTex) free(_meshTex);

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
    _triangulation = [DelaunayTriangulation triangulationWithGLSize:CGSizeMake(2.0, 2.0/_viewAspect)];
    
    float minX = 0;
    float maxX = 0;
    float minY = 0;
    float maxY = 0;
    
    float stepAllowance = _curveStep * NumPoints;
    
    for(int i=0;i<NumPoints;i++){
        
        float amtDone = (float)i/NumPoints;
        float additionalStep = stepAllowance * amtDone;
        
        int stepper = i;//+self.frameCount;
        float cStep = stepper*_curveStep;
        
        cStep += additionalStep;
        
        float dStep = i*_distStep;
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
            
            [_triangulation addPoint:newPoint withColor:nil];
            
        }
        
    }
    
    _numVerts = 0;
    
    for (DelaunayTriangle *triangle in _triangulation.triangles){
        if([self shouldDrawTriangle:triangle]){
            int edgeCount = triangle.edges.count;
            int numPoints = edgeCount;
            _numVerts += numPoints;
        }
    }
    
    
    if(_meshVecs) free(_meshVecs);
    _meshVecs = malloc(sizeof(GLfloat) * _numVerts * 3);
    if(_meshTex) free(_meshTex);
    _meshTex = malloc(sizeof(GLfloat) * _numVerts * 2);
    
    int idxVec = 0;
    int idxTex = 0;
    
    for (DelaunayTriangle *triangle in _triangulation.triangles)
    {
        if([self shouldDrawTriangle:triangle]){
            
            int edgeCount = triangle.edges.count;
            int numPoints = edgeCount;
            
            GLKVector2 vecTextCoordAvg = GLKVector2Zero;
            
            DelaunayPoint *prevPoint = triangle.startPoint;
            
            for(int i=0;i<edgeCount;i++)
            {
                DelaunayEdge *edge = triangle.edges[i];
                DelaunayPoint *p2 = [edge otherPoint:prevPoint];
                
                float x = p2.x;
                float y = p2.y;
                
                if(x < minX) minX = x;
                if(x > maxX) maxX = x;
                if(y < minY) minY = y;
                if(y > maxY) maxY = y;
                
                // Verts
                _meshVecs[idxVec+0] = x;
                _meshVecs[idxVec+1] = y;
                _meshVecs[idxVec+2] = 0;
                idxVec+=3;
                
                // Text coords
                float texCoordX = 0.5 + (x * 0.5);
                vecTextCoordAvg.x += texCoordX;
                
                float texCoordY = 0.5 + (y * -0.5);
                vecTextCoordAvg.y += texCoordY;
                
                prevPoint = p2;
                
            }
            
            // Average the text coords.
            // These are unevenly weighted when
            // drawing triangle edges, but we're not using
            // the texture in that case
            vecTextCoordAvg = GLKVector2DivideScalar(vecTextCoordAvg, numPoints);
            
            // Poor mans triangle color average.
            for(int i=0;i<numPoints;i++){
                _meshTex[idxTex+0] = vecTextCoordAvg.x;
                _meshTex[idxTex+1] = vecTextCoordAvg.y;
                idxTex+=2;
            }
        }
    }
    
    _unitMesh = maxY - minY;
    
}

#pragma mark - Touch

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        if(t.tapCount > 0){
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

@end

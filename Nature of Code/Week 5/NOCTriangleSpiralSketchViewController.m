//
//  NOCPointTestSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/3/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTriangleSpiralSketchViewController.h"
#import "Edgy.h"

const static int NumPoints = 50;
const static BOOL DrawTriangleEdges = YES;

@interface NOCTriangleSpiralSketchViewController ()
{
    float _curveStep;
    float _distStep;
    GLfloat *_meshVecs;
    GLfloat *_meshTex;
    GLfloat *_meshColors;
    int _numVerts;
    DelaunayTriangulation *_triangulation;
    UIView *_viewLoading;
}

@end

@implementation NOCTriangleSpiralSketchViewController

static NSString * TriangleShader = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    _viewLoading = [[UIView alloc] initWithFrame:self.view.bounds];
    _viewLoading.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityIndicator startAnimating];
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                         UIViewAutoresizingFlexibleTopMargin |
                                         UIViewAutoresizingFlexibleRightMargin |
                                         UIViewAutoresizingFlexibleBottomMargin;
    activityIndicator.hidesWhenStopped = NO;
    activityIndicator.center = CGPointMake(_sizeView.width * 0.5, _sizeView.height * 0.5);
    [_viewLoading addSubview:activityIndicator];
    
}

#pragma mark - App Loop

- (void)setup
{
    NOCShaderProgram *shader = [[NOCShaderProgram alloc] initWithName:TriangleShader];

    shader.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                           @"color" : @(GLKVertexAttribColor) };
    shader.uniformNames = @[ UniformMVProjectionMatrix ];
    [self addShader:shader named:TriangleShader];    

    _curveStep = 0.342448;
    _distStep = 0.02;
    
    _meshVecs = NULL;
    _meshTex = NULL;
    _meshColors = NULL;
    
    [self reTriangulate];
    
}

- (void)update
{
    //...
}

- (void)reTriangulate
{
    _triangulation = [DelaunayTriangulation triangulationWithGLSize:CGSizeMake(2.0, 2.0/_viewAspect)];
    
    float stepAllowance = _curveStep * NumPoints;
    
    for(int i=0;i<NumPoints;i++){
        
        float amtDone = (float)i/NumPoints;
        float additionalStep = stepAllowance * amtDone;
        
        int stepper = i;//+self.frameCount;
        float cStep = stepper*_curveStep;
        
        cStep += additionalStep;
        
        float dStep = i*_distStep;
        float x = cosf(cStep) * dStep;
        float y = sinf(cStep) * dStep;
        
        // If we're outside of the bounds, lets just quit.
        float maxBounds = 1.0 / _viewAspect;
        if(fabs(x) > maxBounds && fabs(y) > maxBounds){

            // That should be enough
            break;
            
        }else{
        
            DelaunayPoint *newPoint = [DelaunayPoint pointAtX:x
                                                         andY:y];
            
            [_triangulation addPoint:newPoint withColor:nil];
            
        }
        
    }
    
    _numVerts = 0;
    
    for (DelaunayTriangle *triangle in _triangulation.triangles){
        int edgeCount = triangle.edges.count;
        int numPoints = edgeCount;// + 1;
        if(DrawTriangleEdges){
            // NOTE:
            // We'll draw a degenerate line between the triangles
            numPoints += 3;
        }
        _numVerts += numPoints;
    }
    

    if(_meshVecs) free(_meshVecs);
    _meshVecs = malloc(sizeof(GLfloat) * _numVerts * 3);
    if(_meshTex) free(_meshTex);
    _meshTex = malloc(sizeof(GLfloat) * _numVerts * 2);
    if(_meshColors) free(_meshColors);
    if(DrawTriangleEdges){
        _meshColors = malloc(sizeof(GLfloat) * _numVerts * 4);
    }
    
    int idxVec = 0;
    int idxTex = 0;
    int idxColor = 0;
    
    for (DelaunayTriangle *triangle in _triangulation.triangles)
    {
        int edgeCount = triangle.edges.count;
        int numPoints = edgeCount;
        if(DrawTriangleEdges){
            // NOTE:
            // We'll draw a degenerate line between the triangles
            numPoints += 3;
        }

        GLKVector2 vecTextCoordAvg = GLKVector2Zero;
        
        DelaunayPoint *prevPoint = triangle.startPoint;
        
        for(int i=0;i<edgeCount;i++)
        {
            DelaunayEdge *edge = triangle.edges[i];
            DelaunayPoint *p2 = [edge otherPoint:prevPoint];

            // Verts
            _meshVecs[idxVec+0] = p2.x;
            _meshVecs[idxVec+1] = p2.y;
            _meshVecs[idxVec+2] = 0;
            idxVec+=3;
            
            // Text coords
            float texCoordX = 0.5 + (p2.x * 0.5);
            vecTextCoordAvg.x += texCoordX;
            
            float texCoordY = 0.5 + (p2.y * -0.5);
            vecTextCoordAvg.y += texCoordY;
            
            prevPoint = p2;
            
            if(DrawTriangleEdges){
                
                if(i==0){
                    
                    // The first color is black
                    _meshColors[idxColor+0] = 0.0f;
                    _meshColors[idxColor+1] = 0.0f;
                    _meshColors[idxColor+2] = 0.0f;
                    _meshColors[idxColor+3] = 0.0f;
                    idxColor += 4;

                    // Always draw 2 points in the beginning
                    _meshVecs[idxVec+0] = p2.x;
                    _meshVecs[idxVec+1] = p2.y;
                    _meshVecs[idxVec+2] = 0;
                    idxVec += 3;
                }
                
                // Yellow
                _meshColors[idxColor+0] = 1.0f;
                _meshColors[idxColor+1] = 1.0f;
                _meshColors[idxColor+2] = 0.0f;
                _meshColors[idxColor+3] = 1.0f;
                idxColor+= 4;
                
            }
            
        }
        
        if(DrawTriangleEdges){
            
            DelaunayEdge *edge = triangle.edges[0];
            DelaunayPoint *p2 = [edge otherPoint:triangle.startPoint];
            
            // Also circle back to the first point
            // at the end of the triangle.
            _meshVecs[idxVec+0] = p2.x;
            _meshVecs[idxVec+1] = p2.y;
            _meshVecs[idxVec+2] = 0;
            idxVec+=3;
            
            _meshColors[idxColor+0] = 1.0f;
            _meshColors[idxColor+1] = 1.0f;
            _meshColors[idxColor+2] = 0.0f;
            _meshColors[idxColor+3] = 1.0f;
            idxColor+=4;
            
            // Final point is degenerate
            _meshVecs[idxVec+0] = p2.x;
            _meshVecs[idxVec+1] = p2.y;
            _meshVecs[idxVec+2] = 0;
            idxVec+=3;
            
            // Black
            _meshColors[idxColor+0] = 0.0f;
            _meshColors[idxColor+1] = 0.0f;
            _meshColors[idxColor+2] = 0.0f;
            _meshColors[idxColor+3] = 0.0f;
            idxColor+=4;

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
 
    [_viewLoading removeFromSuperview];
}

- (void)draw
{
    glClearColor(0.3,0.3,0.3,1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

    NOCShaderProgram *shader = [self shaderNamed:TriangleShader];
    [shader use];
    
    GLKMatrix4 matScene = _projectionMatrix2D;
    
    [shader setMatrix4:matScene forUniform:UniformMVProjectionMatrix];

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, _meshVecs);
    if(DrawTriangleEdges){
        glEnableVertexAttribArray(GLKVertexAttribColor);
        glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, _meshColors);
        glDrawArrays(GL_LINE_LOOP, 0, _numVerts);
    }else{
        glDrawArrays(GL_TRIANGLES, 0, _numVerts);
    }

}

- (void)teardown
{
    if(_meshVecs) free(_meshVecs);
    if(_meshTex) free(_meshTex);
    if(_meshColors) free(_meshColors);
}

#pragma mark - Touches

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        if(t.tapCount > 0){
            CGPoint posTouch = [t locationInView:self.view];
            float scalarX = posTouch.x / _sizeView.width;
            float scalarY = posTouch.y / _sizeView.height;
            _curveStep = scalarX * 0.5;
            _distStep = scalarY * 0.1;
            [self startTriangulation];
        }
    }
}

- (void)startTriangulation
{
    _viewLoading.alpha = 0;
    _viewLoading.frame = self.view.bounds;
    [self.view addSubview:_viewLoading];
    [UIView animateWithDuration:0.25
                     animations:^{
                         _viewLoading.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         [self reTriangulate];
                     }];
}

@end

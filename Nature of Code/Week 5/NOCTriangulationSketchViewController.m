//
//  NOCTriangulationSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/27/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTriangulationSketchViewController.h"
#import "NOCOpenGLHelpers.h"
#import "Edgy.h"
#import "DelaunayTriangulation+NOCHelpers.h"

@interface NOCTriangulationSketchViewController ()
{
    DelaunayTriangulation *_triangulation;
    GLKTextureInfo *_textureFace;
}
@end

static NSString * TriangulationShaderName = @"Triangulation";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformTexture = @"texture";
static NSString * UniformTranslation = @"translation";
static NSString * UniformScale = @"scale";

@implementation NOCTriangulationSketchViewController

- (void)randomizeMeshWithNumPoints:(int)numPoints
{
    _triangulation = [DelaunayTriangulation triangulationWithGLSize:CGSizeMake(2.0, 2.0/_viewAspect)];
    for(int i=0;i<numPoints;i++){
        [self addRandomPoint];
    }
}

- (void)addRandomPoint
{
    float glX = (2.0 * RAND_SCALAR) - 1.0;
    float glY = ((2.0 * RAND_SCALAR) - 1.0) / _viewAspect;
    DelaunayPoint *newPoint = [DelaunayPoint pointAtX:glX
                                                 andY:glY];
    
    [_triangulation addPoint:newPoint withColor:nil];
}

#pragma mark - OpenGL Loop

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setup
{
    [super setup];
    
    NOCShaderProgram *shaderTriangles = [[NOCShaderProgram alloc] initWithName:TriangulationShaderName];
     
    shaderTriangles.attributes = @{@"position" : @(GLKVertexAttribPosition),
                                   @"texCoord" : @(GLKVertexAttribTexCoord0)};
    
    shaderTriangles.uniformNames = @[UniformMVProjectionMatrix, UniformTexture, UniformTranslation, UniformScale];
    [self addShader:shaderTriangles named:TriangulationShaderName];

    _textureFace = NOCLoadGLTextureWithName(@"face");

}

- (void)resize
{
    [super resize];
    [self randomizeMeshWithNumPoints:10];
}

- (void)update
{
    if(_triangulation.points.count < 2000){
        [self addRandomPoint];
    }else{
        [self randomizeMeshWithNumPoints:10];
    }
}

- (void)draw
{
    [self clear];
        
    GLKMatrix4 matView = _projectionMatrix2D;
    
    NOCShaderProgram *shader = [self shaderNamed:TriangulationShaderName];
    
    [shader use];
    [shader setMatrix4:matView forUniform:UniformMVProjectionMatrix];

    // NOTE: Translate and scale are not used in this sketch.
    // Just pass in Identity values.
    [shader setFloat:1.0 forUniform:UniformScale];
    GLfloat translate[] = {0,0,0};
    [shader set3DFloatArray:translate
            withNumElements:1
                 forUniform:UniformTranslation];
    
    
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, _textureFace.name);
    [shader setInt:0 forUniform:UniformTexture];

    for (DelaunayTriangle *triangle in _triangulation.triangles)
    {
        int edgeCount = triangle.edges.count;
        int numPoints = edgeCount + 1;
        GLfloat trianglePoints[numPoints*3];
        GLfloat triangleTexCoords[numPoints*2];
        
        GLKVector2 vecTextCoordAvg = GLKVector2Zero;
        
        DelaunayPoint *prevPoint = triangle.startPoint;

        for(int i=0;i<edgeCount;i++)
        {
            DelaunayEdge *edge = triangle.edges[i];
            DelaunayPoint *p2 = [edge otherPoint:prevPoint];
            trianglePoints[i*3+0] = p2.x;
            
            float texCoordX = 0.5 + (p2.x * 0.5);
            vecTextCoordAvg.x += texCoordX;
            
            trianglePoints[i*3+1] = p2.y;
            
            float texCoordY = 0.5 + (p2.y * -0.5);
            vecTextCoordAvg.y += texCoordY;
            
            trianglePoints[i*3+2] = 0;
            prevPoint = p2;
        }
        
        // Close
        trianglePoints[edgeCount*3+0] = prevPoint.x;
        float texCoordX = 0.5 + (prevPoint.x * 0.5);
        vecTextCoordAvg.x += texCoordX;
        
        trianglePoints[edgeCount*3+1] = prevPoint.y;
        float texCoordY = 0.5 + (prevPoint.y * -0.5);
        vecTextCoordAvg.y += texCoordY;
        
        trianglePoints[edgeCount*3+2] = 0;

        // Average the text coords.
        vecTextCoordAvg = GLKVector2DivideScalar(vecTextCoordAvg, edgeCount+1);
        
        // Poor mans triangle color average.
        for(int i=0;i<edgeCount+1;i++){
            triangleTexCoords[i*2+0] = vecTextCoordAvg.x;
            triangleTexCoords[i*2+1] = vecTextCoordAvg.y;
        }

        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &trianglePoints);
        
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &triangleTexCoords);

        int numCoords = sizeof(trianglePoints) / sizeof(GLfloat) / 3;
        
        glDrawArrays(GL_TRIANGLES, 0, numCoords);

    }
    
}

- (void)teardown
{
    //...
}

#pragma mark - Touch

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        if(t.tapCount > 0){
            CGPoint posTouch = [t locationInView:self.view];
            GLKVector2 glPos = NOCGLPositionFromCGPointInRect(posTouch, self.view.frame);
            DelaunayPoint *newPoint = [DelaunayPoint pointAtX:glPos.x
                                                         andY:glPos.y*-1];
            [_triangulation addPoint:newPoint withColor:nil];
        }
    }
}

@end

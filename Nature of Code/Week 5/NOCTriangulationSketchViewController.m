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
}
@end

static NSString * TriangulationShaderName = @"Triangulation";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";

@implementation NOCTriangulationSketchViewController

#pragma mark - OpenGL Loop

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setup
{
    [super setup];
    
    // Setup the shader
    NOCShaderProgram *shaderTriangles = [[NOCShaderProgram alloc] initWithName:TriangulationShaderName];
     
    shaderTriangles.attributes = @{@"position" : @(GLKVertexAttribPosition)};
    
    shaderTriangles.uniformNames = @[UniformMVProjectionMatrix];
     
    self.shaders = @{ TriangulationShaderName : shaderTriangles };

}

- (void)resize
{
    [super resize];
    
    _triangulation = [DelaunayTriangulation triangulationWithGLSize:CGSizeMake(2.0, 2.0/_viewAspect)];
    /*
    _triangulation = [[DelaunayTriangulation alloc] init];
    
    DelaunayPoint *p0 = [DelaunayPoint pointAtX:0 andY:1.0/_viewAspect*3];
    DelaunayPoint *p3 = [DelaunayPoint pointAtX:-3.0f andY:-1.0/_viewAspect*3];
    DelaunayPoint *p5 = [DelaunayPoint pointAtX:3.0f andY:-1.0/_viewAspect*3];
    
    DelaunayPoint *pf0 = [DelaunayPoint pointAtX:-1.0f andY:1.0f/_viewAspect];
    DelaunayPoint *pf1 = [DelaunayPoint pointAtX:1.0f andY:1.0f/_viewAspect];
    DelaunayPoint *pf2 = [DelaunayPoint pointAtX:1.0f andY:-1.0f/_viewAspect];
    DelaunayPoint *pf3 = [DelaunayPoint pointAtX:-1.0f andY:-1.0f/_viewAspect];
    
    DelaunayEdge *e1 = [DelaunayEdge edgeWithPoints:@[p0, p5]];
    DelaunayEdge *e2 = [DelaunayEdge edgeWithPoints:@[p5, p3]];
    DelaunayEdge *e3 = [DelaunayEdge edgeWithPoints:@[p3, p0]];

    DelaunayTriangle *triangle = [DelaunayTriangle triangleWithEdges:@[e1, e2, e3]
                                                        andStartPoint:p0
                                                             andColor:nil];

    _triangulation.frameTrianglePoints = [NSSet setWithObjects:p0, p5, p3, nil];
    
    // How much of this is actually needed?
    _triangulation.triangles = [NSMutableSet setWithObjects:triangle, nil];
    _triangulation.edges = [NSMutableSet setWithObjects:e1, e2, e3, nil];
    _triangulation.points = [NSMutableSet setWithObjects:p0, p5, p3, nil];

    // Now lets add a couple of points to create the view squre
    [_triangulation addPoint:pf0
                   withColor:nil];
    [_triangulation addPoint:pf1
                   withColor:nil];
    [_triangulation addPoint:pf2
                   withColor:nil];
    [_triangulation addPoint:pf3
                   withColor:nil];
    */
}

- (void)update
{
    //...
}

- (void)draw
{
    [self clear];
    
    NOCShaderProgram *shader = self.shaders[TriangulationShaderName];
    [shader use];
    
    // Step back
    //GLKMatrix4 matView = GLKMatrix4MakeScale(0.25, 0.25, 1.0);
    //matView = GLKMatrix4Multiply(_projectionMatrix2D, matView);
    
    GLKMatrix4 matView = _projectionMatrix2D;
    
    [shader setMatrix:matView forUniform:UniformMVProjectionMatrix];

    for (DelaunayTriangle *triangle in _triangulation.triangles)
    {
        int edgeCount = triangle.edges.count;
        int numPoints = 3 * (edgeCount + 1);
        GLfloat trianglePoints[numPoints];

        DelaunayPoint *prevPoint = triangle.startPoint;
        //for (DelaunayEdge *edge in triangle.edges)
        for(int i=0;i<edgeCount;i++)
        {
            DelaunayEdge *edge = triangle.edges[i];
            DelaunayPoint *p2 = [edge otherPoint:prevPoint];
            trianglePoints[i*3+0] = p2.x;
            trianglePoints[i*3+1] = p2.y;
            trianglePoints[i*3+2] = 0;
            prevPoint = p2;
        }
        
        // Close
        trianglePoints[edgeCount*3+0] = prevPoint.x;
        trianglePoints[edgeCount*3+1] = prevPoint.y;
        trianglePoints[edgeCount*3+2] = 0;

        // TODO: Pass in triangle.color;
        // TODO: Draw solid trangles w/ same geometry
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &trianglePoints);
        int numCoords = sizeof(trianglePoints) / sizeof(GLfloat) / 3;
        glDrawArrays(GL_LINE_LOOP, 0, numCoords);

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

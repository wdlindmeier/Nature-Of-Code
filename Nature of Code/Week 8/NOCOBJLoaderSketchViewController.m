//
//  NOCOBJLoaderSketchViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/10/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCOBJLoaderSketchViewController.h"
#import "NOCOBJ.h"

// TMP
#import "NOCBeing.h"

@interface NOCOBJLoaderSketchViewController ()
{
    NOCOBJ *_objCone;
    NOCOBJ *_objSphere;
    NOCBeing *_being;
}
@end

@implementation NOCOBJLoaderSketchViewController

static NSString * ShaderNameOBJ = @"Being";
static NSString * ShaderNameVecs = @"ColoredVerts";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformNormalMatrix = @"normalMatrix";
static NSString * UniformColor = @"color";

- (NSString *)nibNameForControlGUI
{
    return @"NOCGuiOBJLoader";
}

- (void)setup
{
    [super setup];
    
    NOCShaderProgram *shader = [[NOCShaderProgram alloc] initWithName:ShaderNameOBJ];
     
    shader.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                           @"normal" : @(GLKVertexAttribNormal) };
     
    shader.uniformNames = @[ UniformMVProjectionMatrix, UniformNormalMatrix, UniformColor ];
         
    [self addShader:shader named:ShaderNameOBJ];
    
    NOCShaderProgram *shaderVecs = [[NOCShaderProgram alloc] initWithName:ShaderNameVecs];
    
    shaderVecs.attributes = @{ @"position" : @(GLKVertexAttribPosition),
                                @"color" : @(GLKVertexAttribColor) };
    
    shaderVecs.uniformNames = @[ UniformMVProjectionMatrix ];
    
    [self addShader:shaderVecs named:ShaderNameVecs];

    _objCone = [[NOCOBJ alloc] initWithFilename:@"cone"];
    _objSphere = [[NOCOBJ alloc] initWithFilename:@"sharp_sphere"];

    /*
    NSString *path = [[NSBundle mainBundle] pathForResource:@"cone" ofType:@"obj"];
	_cone = [[OpenGLWaveFrontObject alloc] initWithPath:path];
    */
//    _cone.currentPosition = Vertex3DMake(1, -1, 1);
    
    /*
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);

    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, _cone.numberOfVertices * sizeof(Vector3D), _cone.vertices, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));

    glBindVertexArrayOES(0);
    */
    
    self.isArcballEnabled = NO;
    self.isGestureNavigationEnabled = NO;
    
    [NOCBeing calculateGeometry];
    
    glEnable(GL_DEPTH_TEST);
    
    _being = [[NOCBeing alloc] initWithRadius:0.2 position:GLKVector3Zero mass:1];
    
}

- (void)update
{
    [super update];
}

- (void)draw
{
    glClearColor(1,1,1,1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
    _projectionMatrix3D = GLKMatrix4Multiply(_projectionMatrix3DStatic, GLKMatrix4MakeTranslation(0, 0, -3));

    GLfloat colorVec[8];
    for(int i=0;i<2;i++){
        colorVec[4*i+0] = 0;
        colorVec[4*i+1] = 0.5;
        colorVec[4*i+2] = 1;
        colorVec[4*i+3] = 1;
    }
    
    GLKVector3 vec = GLKVector3Make(self.sliderX.value,
                                    self.sliderY.value,
                                    self.sliderZ.value);
    vec = GLKVector3Normalize(vec);
    float magnitude = 1.0f;
    vec = GLKVector3MultiplyScalar(vec, magnitude);

    GLKVector3 vecOrigin = GLKVector3Make(0, 0, 0);

    GLfloat vertsVec[] = {
        vecOrigin.x, vecOrigin.y, vecOrigin.z,
        vecOrigin.x + vec.x, vecOrigin.y + vec.y, vecOrigin.z + vec.z,
    };
        
    GLKMatrix4 modelMat = GLKMatrix4Identity;
    modelMat = GLKMatrix4Scale(modelMat, 0.5, 0.5, 0.5);
    GLKMatrix4 mvpMat = GLKMatrix4Multiply(modelMat, _projectionMatrix3D);
    
    NOCShaderProgram *shader = [self shaderNamed:ShaderNameOBJ];
    [shader use];

    mvpMat = GLKMatrix4AlignWithVector3Heading(mvpMat, vec);

    GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelMat), NULL);
    
    [shader setMatrix4:mvpMat
            forUniform:UniformMVProjectionMatrix];
    [shader setMatrix3:normalMatrix
            forUniform:UniformNormalMatrix];
    GLfloat coneColor[4] = {
        1.0, 0, 0, 1.0
    };
    [shader set4DFloatArray:coneColor withNumElements:1 forUniform:UniformColor];
        
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribNormal);

    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, _objCone.verts);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, _objCone.normals);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, _objCone.numVerts);

    NOCShaderProgram *shaderVerts = [self shaderNamed:ShaderNameVecs];
    [shaderVerts use];
    [shaderVerts setMatrix4:_projectionMatrix3D
                 forUniform:UniformMVProjectionMatrix];
        
    // Draw the vec
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, vertsVec);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, colorVec);
    glDrawArrays(GL_LINE_STRIP, 0, 2);
    
    return;
    
    /*
    NOCShaderProgram *shader = [self shaderNamed:ShaderNameOBJ];
    [shader use];
    
    GLKMatrix4 modelMat = GLKMatrix4Identity;
    modelMat = GLKMatrix4Scale(modelMat, 0.5, 0.5, 0.5);
    GLKMatrix4 mvpMat = GLKMatrix4Multiply(modelMat, _projectionMatrix3D);

    mvpMat = GLKMatrix4RotateX(mvpMat, M_PI * self.sliderX.value);
    mvpMat = GLKMatrix4RotateY(mvpMat, M_PI * self.sliderY.value);
    mvpMat = GLKMatrix4RotateZ(mvpMat, M_PI * self.sliderZ.value);

    GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelMat), NULL);
    
    [shader setMatrix4:mvpMat
            forUniform:UniformMVProjectionMatrix];
    [shader setMatrix3:normalMatrix
            forUniform:UniformNormalMatrix];
    
    GLfloat coneColor[4] = {
        1.0, 0, 0, 1.0
    };

    [shader set4DFloatArray:coneColor withNumElements:1 forUniform:UniformColor];
    

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribNormal);

    //glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, _objCone.verts);
    //glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, _objCone.normals);
    //glDrawArrays(GL_TRIANGLE_STRIP, 0, _objCone.numVerts);

    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, _objSphere.verts);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, _objSphere.normals);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, _objSphere.numVerts);
*/
}

- (void)teardown
{
    [super teardown];
}
@end

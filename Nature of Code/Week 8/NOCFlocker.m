//
//  NOCFlocker.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/10/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFlocker.h"
#import "NOCOBJ.h"
#import "NOCColorHelpers.h"

static const int HistoryLength = 20;

@implementation NOCFlocker
{
    GLKVector3 _positionHistory[HistoryLength];
    GLKVector3 _vecHeading;
    GLKVector3 _prevPosition;
}

- (id)initWithSize:(GLKVector3)size
          position:(GLKVector3)position
              mass:(float)mass
              body:(NOCOBJ *)objBody
{
    self = [super initWithSize:size position:position mass:mass];
    if(self){
        self.objBody = objBody;
        self.color = [UIColor redColor];
    }
    return self;
}

// This aligns the body of the flocker with it's current heading
- (GLKMatrix4)modelMatrix
{
    GLKMatrix4 modelMat = [super modelMatrix];
  
    GLKVector3 zAxis = GLKVector3Make(0, 0, -1);
    GLKVector3 vecAlign = GLKVector3Make(_vecHeading.x, _vecHeading.y, _vecHeading.z * -1);
    float rotRads = acos(GLKVector3DotProduct(vecAlign, zAxis));
    if( fabs(rotRads) > 0.00001 )
    {
        GLKVector3 rotAxis = GLKVector3Normalize(GLKVector3CrossProduct(vecAlign, zAxis));
        GLKQuaternion quat = GLKQuaternionMakeWithAngleAndAxis(rotRads, rotAxis.x, rotAxis.y, rotAxis.z);
        GLKMatrix4 matRot = GLKMatrix4MakeWithQuaternion(quat);
        modelMat = GLKMatrix4Multiply(modelMat, matRot);
    }

    return modelMat;
}

- (void)step
{
    _prevPosition = self.position;
    [super step];
    _vecHeading = GLKVector3Subtract(self.position, _prevPosition);
    _vecHeading = GLKVector3Normalize(_vecHeading);
    int histIdx = self.stepCount % HistoryLength;
    _positionHistory[histIdx] = self.position;
}

- (void)glColor:(GLfloat *)components
{
    NOCColorComponentsForColor(components, self.color);
}

- (void)render
{
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribNormal);

    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, self.objBody.verts);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, self.objBody.normals);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, self.objBody.numVerts);    
}

- (void)renderHistory
{
    int histLength = MIN(self.stepCount, HistoryLength);
    GLfloat historyColor[histLength*4];
    GLfloat historyVecs[histLength*3];
    
    for(int i=0;i<histLength;i++){
        historyColor[i*4+0] = 0.5;
        historyColor[i*4+1] = 0.5;
        historyColor[i*4+2] = 0.5;
        historyColor[i*4+3] = 1.0 - ((float)i / (float)histLength);
        int idx = (self.stepCount % HistoryLength) - i;
        if(idx < 0) idx = HistoryLength + idx;
        historyVecs[i*3] = _positionHistory[idx].x;
        historyVecs[i*3+1] = _positionHistory[idx].y;
        historyVecs[i*3+2] = _positionHistory[idx].z;
    }
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);

    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &historyVecs);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &historyColor);
    glDrawArrays( GL_LINE_STRIP, 0, histLength );
}

@end

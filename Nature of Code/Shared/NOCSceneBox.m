//
//  NOCSceneBox.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSceneBox.h"
#import "NOCColorHelpers.h"
#import "NOCGeometryHelpers.h"
#import "NOCOpenGLHelpers.h"

@implementation NOCSceneBox
{    
    void *_kvoContextColor;
    void *_kvoContextColorLeft;
    void *_kvoContextColorRight;
    void *_kvoContextColorTop;
    void *_kvoContextColorBottom;
    void *_kvoContextColorFront;
    void *_kvoContextColorBack;
    
    GLfloat _sceneBoxVertexData[48];
    GLfloat _sceneBoxColors[64];
    
    GLKVector3 _surfWalls[6][4];
    GLfloat _wallColors[6][20];
    
}

- (id)initWithAspect:(float)aspect
{
    self = [super init];
    if(self){
        [self resizeWithAspect:aspect];
        
        self.color = [UIColor whiteColor];
        self.colorLeft = [UIColor magentaColor];
        self.colorRight = [UIColor greenColor];
        self.colorTop = [UIColor cyanColor];
        self.colorBottom = [UIColor yellowColor];
        self.colorFront = [UIColor whiteColor];
        self.colorBack = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];

        [self addObserver:self
               forKeyPath:@"color"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextColor];
        [self addObserver:self
               forKeyPath:@"colorLeft"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextColorLeft];
        [self addObserver:self
               forKeyPath:@"colorRight"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextColorRight];
        [self addObserver:self
               forKeyPath:@"colorTop"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextColorTop];
        [self addObserver:self
               forKeyPath:@"colorBottom"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextColorBottom];
        [self addObserver:self
               forKeyPath:@"colorFront"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextColorFront];
        [self addObserver:self
               forKeyPath:@"colorBack"
                  options:NSKeyValueObservingOptionNew
                  context:&_kvoContextColorBack];
        
        [self generateColorArray];
        
        [self generateWallColorArrays];
        
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"color"];
    [self removeObserver:self forKeyPath:@"colorLeft"];
    [self removeObserver:self forKeyPath:@"colorRight"];
    [self removeObserver:self forKeyPath:@"colorTop"];
    [self removeObserver:self forKeyPath:@"colorBottom"];
    [self removeObserver:self forKeyPath:@"colorFront"];
    [self removeObserver:self forKeyPath:@"colorBack"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if(context == &_kvoContextColor){
        [self generateColorArray];
    }else{
        [self generateWallColorArrays];
    }
}

- (void)generateColorArray
{
    GLfloat segColors[4];
    NOCColorComponentsForColor(segColors, self.color);
    for(int i=0;i<16;i++){
        _sceneBoxColors[i*4+0] = segColors[0];
        _sceneBoxColors[i*4+1] = segColors[1];
        _sceneBoxColors[i*4+2] = segColors[2];
        _sceneBoxColors[i*4+3] = segColors[3];
    }
}

- (void)generateWallColorArrays
{
    for(int i=0;i<6;i++){
        GLfloat segColors[4];
        WallSide side = i+1;
        switch (side) {
            case WallSideNone:
                break;
            case WallSideBack:
                NOCColorComponentsForColor(segColors, self.colorFront);
                break;
            case WallSideFront:
                NOCColorComponentsForColor(segColors, self.colorBack);
                break;
            case WallSideLeft:
                NOCColorComponentsForColor(segColors, self.colorLeft);
                break;
            case WallSideRight:
                NOCColorComponentsForColor(segColors, self.colorRight);
                break;
            case WallSideTop:
                NOCColorComponentsForColor(segColors, self.colorTop);
                break;
            case WallSideBottom:
                NOCColorComponentsForColor(segColors, self.colorBottom);
                break;
        }
        for(int j=0;j<5;j++){
            _wallColors[i][j*4+0] = segColors[0];
            _wallColors[i][j*4+1] = segColors[1];
            _wallColors[i][j*4+2] = segColors[2];
            _wallColors[i][j*4+3] = segColors[3];
        }
    }
}

#pragma mark - Size / Update

- (void)resizeWithAspect:(float)aspect
{    
    for(int i =0;i<48;i++){
        float val = kCubeStrokedVertexData[i];
        val = val * 2;
        if(i%3==1){
            // This is Y. Scale by the aspect.
            val = val / aspect;
        }
        _sceneBoxVertexData[i] = val;
    }
    
    [self setupWallSurfacesWithAspect:aspect];
    
}

- (void)setupWallSurfacesWithAspect:(float)aspect
{
    float height = 1.0 / aspect;
    
    _surfWalls[WallSideLeft-1][0] = GLKVector3Make(-1, -1*height, -1);
    _surfWalls[WallSideLeft-1][1] = GLKVector3Make(-1, 1*height, -1);
    _surfWalls[WallSideLeft-1][2] = GLKVector3Make(-1, 1*height, 1);
    _surfWalls[WallSideLeft-1][3] = GLKVector3Make(-1, -1*height, 1);
    
    _surfWalls[WallSideRight-1][0] = GLKVector3Make(1, -1*height, -1);
    _surfWalls[WallSideRight-1][1] = GLKVector3Make(1, 1*height, -1);
    _surfWalls[WallSideRight-1][2] = GLKVector3Make(1, 1*height, 1);
    _surfWalls[WallSideRight-1][3] = GLKVector3Make(1, -1*height, 1);
    
    _surfWalls[WallSideFront-1][0] = GLKVector3Make(-1, -1*height, -1);
    _surfWalls[WallSideFront-1][1] = GLKVector3Make(-1, 1*height, -1);
    _surfWalls[WallSideFront-1][2] = GLKVector3Make(1, 1*height, -1);
    _surfWalls[WallSideFront-1][3] = GLKVector3Make(1, -1*height, -1);
    
    _surfWalls[WallSideBack-1][0] = GLKVector3Make(-1, -1*height, 1);
    _surfWalls[WallSideBack-1][1] = GLKVector3Make(-1, 1*height, 1);
    _surfWalls[WallSideBack-1][2] = GLKVector3Make(1, 1*height, 1);
    _surfWalls[WallSideBack-1][3] = GLKVector3Make(1, -1*height, 1);
    
    _surfWalls[WallSideTop-1][0] = GLKVector3Make(-1, 1*height, -1);
    _surfWalls[WallSideTop-1][1] = GLKVector3Make(1, 1*height, -1);
    _surfWalls[WallSideTop-1][2] = GLKVector3Make(1, 1*height, 1);
    _surfWalls[WallSideTop-1][3] = GLKVector3Make(-1, 1*height, 1);
    
    _surfWalls[WallSideBottom-1][0] = GLKVector3Make(-1, -1*height, -1);
    _surfWalls[WallSideBottom-1][1] = GLKVector3Make(1, -1*height, -1);
    _surfWalls[WallSideBottom-1][2] = GLKVector3Make(1, -1*height, 1);
    _surfWalls[WallSideBottom-1][3] = GLKVector3Make(-1, -1*height, 1);
    
}

#pragma mark - Drawing

- (void)render
{
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &_sceneBoxVertexData);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &_sceneBoxColors);
    
    int numCoords = sizeof(_sceneBoxVertexData) / sizeof(GLfloat) / 3;
    glDrawArrays(GL_LINE_LOOP, 0, numCoords);
    
}

- (void)renderColoredWallsWithEdgeOffset:(float)offset
{
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    for(int i=0;i<6;i++){
        
        GLfloat wallVerts[5*3];
        
        WallSide side = i+1;
        BOOL isXOffset = side != WallSideLeft && side != WallSideRight;
        BOOL isYOffset = side != WallSideTop && side != WallSideBottom;
        BOOL isZOffset = side != WallSideFront && side != WallSideBack;
        
        for(int j=0;j<5;j++){
            GLKVector3 corner = _surfWalls[i][j%4];
            wallVerts[j*3+0] = corner.x + (isXOffset * offset * (corner.x > 0 ? -1 : 1));
            wallVerts[j*3+1] = corner.y + (isYOffset * offset * (corner.y > 0 ? -1 : 1));
            wallVerts[j*3+2] = corner.z + (isZOffset * offset * (corner.z > 0 ? -1 : 1));
        }
        
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &wallVerts);
        glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &_wallColors[i]);
        glDrawArrays(GL_LINE_LOOP, 0, 5);
    }
}

@end

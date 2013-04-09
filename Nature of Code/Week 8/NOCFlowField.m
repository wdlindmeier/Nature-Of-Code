//
//  NOCFlowField.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/6/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFlowField.h"
#import "perlin.h"

@implementation NOCFlowField
{
    CGSize _dimensions;
    GLKVector3 *_vectors;
    long _frame;
    float _alpha;
    float _beta;
    float _step;
}

@synthesize dimensions = _dimensions;

- (id)initWithWidth:(int)width height:(int)height
{
    self = [super init];
    if(self){
        _dimensions = CGSizeMake(width, height);
        _vectors = malloc(sizeof(GLKVector3) * width * height);        
        [self generatePerlinWithAlpha:1.5 beta:1.2 step:0.1];
        _frame = 0;
    }
    return self;
}

- (void)dealloc
{
    if(_vectors){
        free(_vectors);
    }
}

#pragma mark - Accessors

- (GLKVector3)vectorAtIndex:(int)index
{
    return _vectors[index];
}

- (GLKVector3)vectorAtX:(int)x y:(int)y
{
    int idx = (_dimensions.width * y) + x;
    return [self vectorAtIndex:idx];
}

- (void)setVector:(GLKVector3)vec atX:(int)x y:(int)y
{
    int idx = (_dimensions.width * y) + x;
    [self setVector:vec atIndex:idx];
}

- (void)setVector:(GLKVector3)vec atIndex:(int)index
{
    _vectors[index] = vec;
}

#pragma mark - Generation

- (void)advance
{
    _frame += 1;
    [self generatePerlinWithAlpha:_alpha beta:_beta step:_step];
}

- (void)generatePerlinWithAlpha:(float)alpha beta:(float)beta step:(float)magnitude
{
    _alpha = alpha;
    _beta = beta;
    _step = magnitude;
    for(int x=0;x<_dimensions.width;x++){
        for(int y=0;y<_dimensions.height;y++){
            double angle = PerlinNoise3D(x*_step, y*_step, _frame*_step, _alpha, _beta, 4);
            float xx = cos(angle);
            float yy = sin(angle);
            float zz = 0;
            int idx = (y * _dimensions.width) + x;
            _vectors[idx] = GLKVector3Make(xx,yy,zz);
        }
    }
}

#pragma mark - Drawing

- (void)renderInRect:(CGRect)rect lineWidth:(float)width weighted:(BOOL)isWeighted
{
    // Draw a stroked cube
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    GLfloat color[16];
    for(int i=0;i<16;i++){
        color[i] = 1.0;
    }
    
    float plotWidth = rect.size.width / _dimensions.width;
    float plotHeight = rect.size.height / _dimensions.height;
    float halfWidth = plotWidth * 0.5;
    float halfHeight = plotHeight * 0.5;

    for(int x=0;x<_dimensions.width;x++){
        for(int y=0;y<_dimensions.height;y++){
            GLKVector3 plotVec = [self vectorAtX:x y:y];
            float plotX = rect.origin.x + (x*plotWidth);
            float plotY = rect.origin.y + (y*plotHeight);            
            GLKVector2 start = GLKVector2Make(plotX + halfWidth + (plotVec.x * halfWidth),
                                              plotY + halfHeight + (plotVec.y * halfHeight));
            GLKVector2 end = GLKVector2Make(plotX + halfWidth - (plotVec.x * halfWidth),
                                            plotY + halfHeight - (plotVec.y * halfHeight));
            
            GLKVector2 perpVec = GLKVector2Make(0, 1);
            if(!isWeighted){
                perpVec = NOCGLKVector2Normal(GLKVector2Subtract(start, end));
            }            

            GLfloat verts[] = {
                start.x - (perpVec.x * width * 0.5),
                start.y - (perpVec.y * width * 0.5),
                plotVec.z,
                start.x + (perpVec.x * width * 0.5),
                start.y + (perpVec.y * width * 0.5),
                plotVec.z,
                end.x - (perpVec.x * width * 0.5),
                end.y - (perpVec.y * width * 0.5),
                plotVec.z,
                end.x + (perpVec.x * width * 0.5),
                end.y + (perpVec.y * width * 0.5),
                plotVec.z
            };
            
            glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &verts);
            glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &color);
            int numCoords = 4;
            glDrawArrays(GL_TRIANGLE_STRIP, 0, numCoords);
        }
    }
    
}


@end

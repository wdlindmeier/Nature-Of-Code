//
//  NOCBeard.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/10/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCBeard.h"
#import "NOCBeardVerts.h"
#import "NOCHair.h"
#import "NOCShaderProgram.h"
#import "NOCParticle2D.h"

#define RENDER_WIREFRAME    0

@implementation NOCBeard
{
    NSMutableArray *_hairs;
    NOCBeardType _beardType;
    GLKVector2 _positionTo;
    NOCShaderProgram *_shader;
#if !RENDER_WIREFRAME
    GLKTextureInfo *_textureHair;
#endif
}

#if RENDER_WIREFRAME
static NSString * NOCWireframeShaderName = @"ColoredVerts";
#else
static NSString * NOCBeardShaderName = @"Texture";
static NSString * UniformTexture = @"texture";
#endif

static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";

- (id)initWithBeardType:(NOCBeardType)type position:(GLKVector2)position
{
    self = [super init];
    if(self){
        _beardType = type;
        [self createHairs];
        
#if RENDER_WIREFRAME

        _shader = [[NOCShaderProgram alloc] initWithName:NOCWireframeShaderName];
        
        _shader.attributes = @{@"position" : @(GLKVertexAttribPosition),
                               @"color" : @(GLKVertexAttribColor)};
        
        _shader.uniformNames = @[ UniformMVProjectionMatrix ];
        
#else
        _textureHair = NOCLoadGLTextureWithName(@"beard_hair");
        
        _shader = [[NOCShaderProgram alloc] initWithName:NOCBeardShaderName];
        
        _shader.attributes = @{@"position" : @(GLKVertexAttribPosition),
                               @"texCoord" : @(GLKVertexAttribTexCoord0)};
        
        _shader.uniformNames = @[ UniformMVProjectionMatrix,
                                  UniformTexture ];
        
#endif
        
        [_shader load];

    }
    return self;
}

- (void)createHairs
{
    int numHairs = 0;
    float *hairVerts = NULL;
    
    switch (_beardType) {
        case NOCBeardTypeStandard:
            numHairs = NumHairsBeard0;
            hairVerts = HairVertsBeard0;
            break;
        case NOCBeardTypeNone:
            break;
    }

    _hairs = [NSMutableArray arrayWithCapacity:numHairs];
    
    CGRect frameBeard = CGRectMake(-0.48,
                                   0.25, // This frame is relative to a face tracing region
                                   0.9,
                                   1.0);
    
    for(int i=0;i<NumHairsBeard0;i++){
        
        float x = hairVerts[i*2+0];
        float y = hairVerts[i*2+1];
        
        x = frameBeard.origin.x + (x * frameBeard.size.width);
        y = frameBeard.origin.y - (y * frameBeard.size.height);
        
        GLKVector2 posAnchor = GLKVector2Make(x, y);
        NOCHair *hair = [[NOCHair alloc] initWithAnchor:posAnchor
                                           numParticles:0
                                               ofLength:0.05];
        
        hair.growthRate = 0.0005;
        hair.maxNumParticles = 8;
        
        [_hairs addObject:hair];
    }
    
    // Sort them so the higher hairs are rendered first.
    [_hairs sortUsingComparator:^NSComparisonResult(NOCHair *h1, NOCHair *h2) {
        if(h1.anchor.y < h2.anchor.y){
            return NSOrderedAscending;
        }else if(h1.anchor.y > h2.anchor.y){
            return NSOrderedDescending;
        }else{
            // If they're the same height,
            // choose according to x position. Middle should be in front.
            if(fabs(0.5 - h1.anchor.x) < fabs(0.5 - h2.anchor.x)){
                return NSOrderedAscending;
            }else{
                return NSOrderedDescending;
            }
        }
        return NSOrderedSame;
    }];

}

- (NSArray *)hairs
{
    return _hairs;
}

- (void)setPosition:(GLKVector2)position
{
    [self setPosition:position shouldLerp:NO];
}

- (void)setPosition:(GLKVector2)position shouldLerp:(BOOL)shouldLerp
{
    
    _positionTo = position;
    GLKVector2 prevPosition = _position;
    
    if(shouldLerp){
        float distTravel = GLKVector2Distance(prevPosition, position);
        // Lerp more gradually if the distance is smaller
        float lerpAmt = MIN(1.0, distTravel * 1.5);
        _position = GLKVector2Lerp(_position, _positionTo, lerpAmt);
    }else{
        _position = _positionTo;
    }
    
    GLKVector2 offset = GLKVector2Subtract(_position, prevPosition);
    
    for(NOCHair *h in _hairs)
    {
        GLKVector2 anchorPoint = h.anchor;
        anchorPoint.x += offset.x;
        anchorPoint.y += offset.y;
        h.anchor = anchorPoint;
    }

}

- (void)updateWithOffset:(GLKVector2)offset
{
    [self setPosition:GLKVector2Add(_positionTo, offset)
           shouldLerp:YES];

    GLKVector2 gravity = GLKVector2Make(0, -0.05);
    for(NOCHair *h in _hairs)
    {
        [h applyForce:gravity];
        [h update];
    }
}

- (void)renderInMatrix:(GLKMatrix4)matrix
{
    [_shader use];
    [_shader setMatrix:matrix forUniform:UniformMVProjectionMatrix];
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
#if !RENDER_WIREFRAME
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, _textureHair.name);
    [_shader setInt:0 forUniform:UniformTexture];
#endif

    for(NOCHair *h in _hairs){
        
        NSArray *particles = [h particles];
        int numParticles = particles.count;
        int numVerts = (numParticles + 1) * 2; // +1 for the anchor
        GLfloat hairVerts[numVerts * 3];
        
#if RENDER_WIREFRAME
        // fill up the color array.
        GLfloat colorWireframe[numVerts * 4];
        for(int i=0;i<numVerts;i++){
            colorWireframe[i*4+0] = 1.0;
            colorWireframe[i*4+1] = 0.0;
            colorWireframe[i*4+2] = 0.0;
            colorWireframe[i*4+3] = 1.0;
        }
#else
        GLfloat texCoords[numVerts * 2];
        for(int i=0;i<(numParticles+1);i++){
            if(i ==0 || i == numParticles){
                texCoords[i*4+0] = 0.5;
                texCoords[i*4+1] = 1.0;
                texCoords[i*4+2] = 0.5;
                texCoords[i*4+3] = 1.0;
            }else if(i%2==0){
                texCoords[i*4+0] = 0.0;
                texCoords[i*4+1] = 1.0;
                texCoords[i*4+2] = 1.0;
                texCoords[i*4+3] = 1.0;
            }else{
                texCoords[i*4+0] = 0.0;
                texCoords[i*4+1] = 0.0;
                texCoords[i*4+2] = 1.0;
                texCoords[i*4+3] = 0.0;
            }
        }
#endif
        
        // The max width should be smaller for smaller hairs
        float minHairWidth = 0.01;
        float maxHairWidth = MIN(minHairWidth * numParticles, 0.025);
        
        hairVerts[0] = h.anchor.x - (minHairWidth*0.5);
        hairVerts[1] = h.anchor.y;
        hairVerts[2] = 0;
        hairVerts[3] = h.anchor.x + (minHairWidth*0.5);
        hairVerts[4] = h.anchor.y;
        hairVerts[5] = 0;
        
        GLKVector2 prevPoint = h.anchor;
        
        for(int i=0;i<numParticles;i++){

            NOCParticle2D *p = particles[i];
            GLKVector2 pPos = p.position;
            
            // TODO:
            // Account for the angle
            // ...
            // Then:
            prevPoint = pPos;
            
            float scalarSegment = (float)(i+1) / (float)(numParticles);
            float segmentWidth = MAX((1.0 - fabs((scalarSegment*2.0) - 1)) * maxHairWidth, minHairWidth);
            
            float pX1 = pPos.x - (segmentWidth * 0.5);
            float pX2 = pPos.x + (segmentWidth * 0.5);
            float pY1 = pPos.y;
            float pY2 = pPos.y;

            hairVerts[(i+1)*6+0] = pX1;
            hairVerts[(i+1)*6+1] = pY1;
            hairVerts[(i+1)*6+2] = 0;

            hairVerts[(i+1)*6+3] = pX2;
            hairVerts[(i+1)*6+4] = pY2;
            hairVerts[(i+1)*6+5] = 0;

        }

        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &hairVerts);

#if RENDER_WIREFRAME
        glEnableVertexAttribArray(GLKVertexAttribColor);
        glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, &colorWireframe);
        
        glDrawArrays(GL_LINE_STRIP, 0, numVerts);
#else
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &texCoords);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, numVerts);
#endif

    }
    
    glDisable(GL_BLEND);
}

@end

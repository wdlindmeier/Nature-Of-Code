//
//  NOCBeard.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/10/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCBeard.h"
#import "NOCHair.h"
#import "NOCShaderProgram.h"
#import "NOCParticle2D.h"
#import "NOCBeardVertFactory.h"

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

- (id)initWithBeardType:(NOCBeardType)type
               position:(GLKVector2)position
                texture:(GLKTextureInfo *)texture
{
    self = [super init];
    if(self){
        
        _beardType = type;

        [self reset];
        
#if RENDER_WIREFRAME

        _shader = [[NOCShaderProgram alloc] initWithName:NOCWireframeShaderName];
        
        _shader.attributes = @{@"position" : @(GLKVertexAttribPosition),
                               @"color" : @(GLKVertexAttribColor)};
        
        _shader.uniformNames = @[ UniformMVProjectionMatrix ];
        
#else

        _textureHair = texture;
        
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

- (void)reset
{
    [self createHairs];
    _position = GLKVector2Zero;
    _positionTo = GLKVector2Zero;
}

- (void)createHairs
{
    NSString *beardName = nil;
    
    switch (_beardType) {
        case NOCBeardTypeStandard:
            beardName = @"beard_mask_standard";
            break;
        case NOCBeardTypeLincoln:
            beardName = @"beard_mask_lincoln";
            break;
        case NOCBeardTypeWolverine:
            beardName = @"beard_mask_wolverine";
            break;
        case NOCBeardTypeHogan:
            beardName = @"beard_mask_hogan";
            break;
        case NOCBeardTypeGotee:
            beardName = @"beard_mask_gotee";
            break;
        case NOCBeardTypeMutton:
            beardName = @"beard_mask_mutton";
            break;
        case NOCBeardTypeNone:
            break;
    }
    
    if(!beardName) return;
    
    NSArray *hairPositions = [NOCBeardVertFactory hairPositionsForBeardNamed:beardName];
    
    int numHairs = hairPositions.count;
    
    _hairs = [NSMutableArray arrayWithCapacity:numHairs];
    
    CGRect frameBeard = CGRectMake(-0.48,
                                   0.25, // This frame is relative to a face tracing region
                                   0.9,
                                   1.0);
    
    for(int i=0;i<numHairs;i++){
        
        float x = [(NSNumber *)hairPositions[i][0] floatValue];
        float y = [(NSNumber *)hairPositions[i][1] floatValue];
        float z = [(NSNumber *)hairPositions[i][2] floatValue];
        
        x = frameBeard.origin.x + (x * frameBeard.size.width);
        y = frameBeard.origin.y - (y * frameBeard.size.height);
        
        GLKVector2 posAnchor = GLKVector2Make(x, y);
        NOCHair *hair = [[NOCHair alloc] initWithAnchor:posAnchor
                                           numParticles:0
                                               ofLength:0.05];
        
        // NOTE: The brighter the z component is, the less it grows
        const static float MaxGrowthRate = 0.001;
        const static float MaxNumParticles = 10;
        // NOTE: We want the dark areas to grow faster
        float darkness = 1.0 - z;
        hair.growthRate = darkness * MaxGrowthRate;
        hair.maxNumParticles = ceil(darkness * MaxNumParticles);
        
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
        
        float amtLastSegment = h.lastSegmentLength / h.distBetweenParticles;

        for(int i=0;i<(numParticles+1);i++){
                       
            if(i%2==0){
                if(i == numParticles){
                    texCoords[i*4+0] = 0.0;
                    texCoords[i*4+1] = amtLastSegment;
                    texCoords[i*4+2] = 1.0;
                    texCoords[i*4+3] = amtLastSegment;
                }else{
                    texCoords[i*4+0] = 0.0;
                    texCoords[i*4+1] = 1.0;
                    texCoords[i*4+2] = 1.0;
                    texCoords[i*4+3] = 1.0;
                }
            }else{
                if(i == numParticles){
                    texCoords[i*4+0] = 0.0;
                    texCoords[i*4+1] = 1.0-amtLastSegment;
                    texCoords[i*4+2] = 1.0;
                    texCoords[i*4+3] = 1.0-amtLastSegment;
                }else{
                    texCoords[i*4+0] = 0.0;
                    texCoords[i*4+1] = 0.0;
                    texCoords[i*4+2] = 1.0;
                    texCoords[i*4+3] = 0.0;                    
                }
            }
        }
#endif
        
        // The max width should be smaller for smaller hairs
        float minHairWidth = 0.005;
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
            
            // Account for the segment angle
            GLKVector2 perpVec = NOCGLKVector2Normal(GLKVector2Subtract(pPos, prevPoint));
            prevPoint = pPos;
            
            float scalarSegment = (float)(i+1) / (float)(numParticles);
            float segmentWidth = MAX(MIN(1.0, scalarSegment * maxHairWidth * 3.0), minHairWidth);
            //MAX((1.0 - fabs((scalarSegment*2.0) - 1)) * maxHairWidth, minHairWidth);
            
            float pX1 = pPos.x - (perpVec.x * segmentWidth * 0.5);
            float pX2 = pPos.x + (perpVec.x * segmentWidth * 0.5);
            float pY1 = pPos.y - (perpVec.y * segmentWidth * 0.5);
            float pY2 = pPos.y + (perpVec.y * segmentWidth * 0.5);

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

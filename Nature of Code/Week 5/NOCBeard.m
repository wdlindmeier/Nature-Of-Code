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

@implementation NOCBeard
{
    NSMutableArray *_hairs;
    NOCBeardType _beardType;
    GLKVector2 _positionTo;
}

- (id)initWithBeardType:(NOCBeardType)type position:(GLKVector2)position
{
    self = [super init];
    if(self){
        _beardType = type;
        [self createHairs];
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
    
    CGRect frameBeard = CGRectMake(-0.45,
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
                                           numParticles:2
                                               ofLength:0.1];
        // TMP
        //        hair.growthRate = 0.0005;
        hair.maxNumParticles = 8;
        
        [_hairs addObject:hair];
    }

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

    if(NO){//shouldLerp){
        _position = GLKVector2Lerp(_position, _positionTo, 0.5f);
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

@end

//
//  NOCFlameParticle.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/23/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCFlameParticle.h"

@implementation NOCFlameParticle

- (void)render
{
    // Bind the particle texture
    glBindTexture(GL_TEXTURE_2D, self.texture.name);
    [super render];
}

@end

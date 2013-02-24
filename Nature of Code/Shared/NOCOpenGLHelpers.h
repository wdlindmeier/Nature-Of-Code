//
//  NOCOpenGLHelpers.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

typedef struct {
    GLKVector3 size;
    GLKVector3 origin;
} NOCBox3D;


static inline GLKTextureInfo * NOCLoadGLTextureWithName(NSString *texName)
{
    UIImage *texImage = [UIImage imageNamed:texName];
    NSError *texError = nil;
    GLKTextureInfo *tex = [GLKTextureLoader textureWithCGImage:texImage.CGImage
                                                       options:nil
                                                         error:&texError];
    if(texError){
        NSLog(@"ERROR: Could not load the texture: %@", texError);
        return nil;
    }
    return tex;
}


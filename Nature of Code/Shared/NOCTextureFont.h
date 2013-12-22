//
//  BLGLFont.h
//  BLGLFont
//
//  Created by William Lindmeier on 12/21/13.
//  Copyright (c) 2013 William Lindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOCTexture.h"

// A simple font class for OpenGL rendering.
// Best when used with monospace fonts because
// it doesn't take kerning into account.

@interface NOCTextureFont : NOCTexture

- (id)initWithFontName:(NSString *)fontName;
- (void)renderString:(NSString *)string;

+ (UIImage *)imageMapForFontNamed:(NSString *)fontName;

@end

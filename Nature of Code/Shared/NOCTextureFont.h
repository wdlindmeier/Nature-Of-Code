//
//  BLGLFont.h
//  BLGLFont
//
//  Created by William Lindmeier on 12/21/13.
//  Copyright (c) 2013 William Lindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NOCTexture.h"

@interface NOCTextureFont : NOCTexture

- (void)renderString:(NSString *)string;

@end

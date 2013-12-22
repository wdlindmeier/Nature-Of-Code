//
//  NOCTexture.m
//  ARManhattan
//
//  Created by William Lindmeier on 12/22/13.
//  Copyright (c) 2013 William Lindmeier. All rights reserved.
//

#import "NOCTexture.h"
#import "NOCGeometryHelpers.h"

@implementation NOCTexture

- (id)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self)
    {
        self.vertAttribLocation = GLKVertexAttribPosition;
        self.texCoordAttribLocation = GLKVertexAttribTexCoord0;
        
        // Clear the error in case there's anything in the pipes.
        glGetError();
        NSError *texError = nil;
        _glTexture = [GLKTextureLoader textureWithCGImage:image.CGImage
                                                  options:nil
                                                    error:&texError];
        _size = CGSizeMake(_glTexture.width, _glTexture.height);
        if(texError)
        {
            NSLog(@"ERROR: Could not load the texture: %@", texError);
            return nil;
        }
    }
    return self;
}

- (id)initWithImageNamed:(NSString *)imageName
{
    UIImage *image = [UIImage imageNamed:imageName];
    if (!image)
    {
        NSLog(@"ERROR: Could not find the texture image: %@", imageName);
        return nil;
    }
    return [self initWithImage:image];
}

- (GLuint)textureID
{
    return _glTexture.name;
}

- (void)enableAndBind:(GLuint)uniformSamplerLocation
{
    // This is always texture 0
    glBindTexture(GL_TEXTURE_2D, [self textureID]);
    glActiveTexture(GL_TEXTURE0);
    glUniform1i(uniformSamplerLocation, 0);
}

- (void)unbind
{
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)render
{
    glVertexAttribPointer(self.vertAttribLocation, 3, GL_FLOAT, GL_FALSE, 0, &kSquare3DBillboardVertexData);
    glVertexAttribPointer(self.texCoordAttribLocation, 2, GL_FLOAT, GL_FALSE, 0, &kSquare3DTexCoords);
    glEnableVertexAttribArray(self.vertAttribLocation);
    glEnableVertexAttribArray(self.texCoordAttribLocation);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableVertexAttribArray(self.vertAttribLocation);
    glDisableVertexAttribArray(self.texCoordAttribLocation);
}
@end

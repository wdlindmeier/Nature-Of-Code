//
//  NOCTextureFont.m
//  NOCTextureFont
//
//  Created by William Lindmeier on 12/21/13.
//  Copyright (c) 2013 William Lindmeier. All rights reserved.
//

#import "NOCTextureFont.h"

// Hard-coded values that must correspond to the provided image
const static int kGlyphWidth = 64; // pixels
const static int kGlyphHeight = 126; // pixels
const static int kNumGlyphs = 95; // includes space, doesn't include line break etc.
const static int kCharsWide = 16;

const char kCharacters[] =
{
    '!', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', '/', '0',
    '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', ';', '<', '=', '>', '?', '@',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[', '\\', ']', '^', '_', '`',
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
    'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '{', '|', '}', '~', ' ', // space is last
};

static int indexOfChar(char a)
{
    for( int i = 0; i < kNumGlyphs; ++i)
    {
        if (kCharacters[i] == a)
        {
            return i;
        }
    }
    return -1;
}

static CGRect regionForChar(char c)
{
    CGRect rect = CGRectZero;
    int charIdx = indexOfChar(c);
    if (charIdx != -1)
    {
        int x = charIdx % kCharsWide;
        int y = charIdx / kCharsWide;
        rect = CGRectMake(x * kGlyphWidth, y * kGlyphHeight, kGlyphWidth, kGlyphHeight);
    }
    return rect;
}

@implementation NOCTextureFont

- (id)initWithImageNamed:(NSString *)imageName
{
    self = [super initWithImageNamed:imageName];
    if (self)
    {
        NSLog(@"NOCTextureFont Font: w %i h %i", (int)self.size.width, (int)self.size.height);
    }
    return self;
}

- (void)renderString:(NSString *)string
{    
    // Dynamically build the geometry
    // Each letter gets a quad
    
    long numChars = string.length;
    long drawNumVerts = numChars * 6;
    GLfloat verts[drawNumVerts * 3];
    GLfloat texCoords[drawNumVerts * 2];
    float x = 0;
    float y = 0;
    for (int i = 0; i < numChars; ++i)
    {
        char c = [string characterAtIndex:i];
        CGRect charRegion = CGRectZero;
        if (c == '\n')
        {
            y -= kGlyphHeight;
            x = 0;
            // Use a zero rect
            // This should create a degenerate triangle
        }
        else
        {
            charRegion = regionForChar(c);
            // Flip
            charRegion.origin.y = (float)_glTexture.height - charRegion.origin.y;
        }
        
        // Convert to unit.
        float scalarX1 = x / self.size.width;
        float scalarY1 = y / self.size.height;
        float scalarX2 = (x+charRegion.size.width) / self.size.width;
        float scalarY2 = (y-charRegion.size.height) / self.size.height;

        float texX1 = charRegion.origin.x / self.size.width;
        float texY1 = 1.0 - (charRegion.origin.y / self.size.height);
        float texX2 = (charRegion.origin.x + charRegion.size.width) / self.size.width;
        float texY2 = 1.0 - ((charRegion.origin.y - charRegion.size.height) / self.size.height);

        int charVert = 0;
        int charTex = 0;
        const int vertIncr = 18;
        const int texIncr = 12;
        
        // Add verts.
        // UL
        verts[i*vertIncr + charVert++] = scalarX1;
        verts[i*vertIncr + charVert++] = scalarY1;
        verts[i*vertIncr + charVert++] = 0;
        
        texCoords[i*texIncr + charTex++] = texX1;
        texCoords[i*texIncr + charTex++] = texY1;
        
        // UR
        verts[i*vertIncr + charVert++] = scalarX2;
        verts[i*vertIncr + charVert++] = scalarY1;
        verts[i*vertIncr + charVert++] = 0;
        
        texCoords[i*texIncr + charTex++] = texX2;
        texCoords[i*texIncr + charTex++] = texY1;
        
        // LL
        verts[i*vertIncr + charVert++] = scalarX1;
        verts[i*vertIncr + charVert++] = scalarY2;
        verts[i*vertIncr + charVert++] = 0;
        
        texCoords[i*texIncr + charTex++] = texX1;
        texCoords[i*texIncr + charTex++] = texY2;
        
        // UR
        verts[i*vertIncr + charVert++] = scalarX2;
        verts[i*vertIncr + charVert++] = scalarY1;
        verts[i*vertIncr + charVert++] = 0;
        
        texCoords[i*texIncr + charTex++] = texX2;
        texCoords[i*texIncr + charTex++] = texY1;

        // LL
        verts[i*vertIncr + charVert++] = scalarX1;
        verts[i*vertIncr + charVert++] = scalarY2;
        verts[i*vertIncr + charVert++] = 0;
        
        texCoords[i*texIncr + charTex++] = texX1;
        texCoords[i*texIncr + charTex++] = texY2;
        
        // LR
        verts[i*vertIncr + charVert++] = scalarX2;
        verts[i*vertIncr + charVert++] = scalarY2;
        verts[i*vertIncr + charVert++] = 0;
        
        texCoords[i*texIncr + charTex++] = texX2;
        texCoords[i*texIncr + charTex++] = texY2;

        x += charRegion.size.width;
    }

    glVertexAttribPointer(self.vertAttribLocation, 3, GL_FLOAT, GL_FALSE, 0, &verts);
    glVertexAttribPointer(self.texCoordAttribLocation, 2, GL_FLOAT, GL_FALSE, 0, &texCoords);
    glEnableVertexAttribArray(self.vertAttribLocation);
    glEnableVertexAttribArray(self.texCoordAttribLocation);

    glDrawArrays(GL_TRIANGLES, 0, (int)drawNumVerts);

    glDisableVertexAttribArray(self.vertAttribLocation);
    glDisableVertexAttribArray(self.texCoordAttribLocation);
}

@end

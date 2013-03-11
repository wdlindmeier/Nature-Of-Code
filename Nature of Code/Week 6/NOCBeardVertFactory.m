//
//  NOCBeardVertFactory.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/10/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCBeardVertFactory.h"

@implementation NOCBeardVertFactory

+ (NSArray *)hairPositionsForBeardNamed:(NSString *)beardName
{
    UIImage *beardImage = [UIImage imageNamed:beardName];
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(beardImage.CGImage));
    const UInt8* data = CFDataGetBytePtr(pixelData);
    CGSize sizeBeard = beardImage.size;
    
    int strideX = 8;
    int offsetX = -3;
    int strideY = 8;
    int offsetY = -3;
    int hairX = 0;
    
    NSMutableArray *outp = [NSMutableArray arrayWithCapacity:(sizeBeard.width * sizeBeard.height) / (strideX*strideY)];
    
    for(int x=0;x<sizeBeard.width;x+=1){
        hairX = 0;
        for(int y=0;y<sizeBeard.height;y+=1){
            if((offsetX+x) % strideX == 0 &&
               (offsetY+y) % strideY == 0){
                
                hairX++;
                
                // This gives it a staggered pattern
                float xOff = (hairX % 2) * ((float)strideY * 0.5);
                float yOff = 0;
                
                float pxX = CONSTRAIN(x + xOff, 0, sizeBeard.width-1);
                float pxY = CONSTRAIN(y + yOff, 0, sizeBeard.height-1);
                
                int pixelIdx = ((sizeBeard.width * pxY) + pxX) * 4;
                UInt8 r = data[pixelIdx + 0];
                UInt8 g = data[pixelIdx + 1];
                UInt8 b = data[pixelIdx + 2];
                UInt8 a = data[pixelIdx + 3];
                if(a > 240){
                    float scalarX = pxX / sizeBeard.width;
                    float scalarY = pxY / sizeBeard.height;
                    float scalarBrightness = (float)(r+g+b) / (255.0f*3);
                    // Using the z component for brightness.
                    [outp addObject:@[@(scalarX),@(scalarY), @(scalarBrightness)]];
                }
            }
        }
    }
    
    return [NSArray arrayWithArray:outp];
}

@end

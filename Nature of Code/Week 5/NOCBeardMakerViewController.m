//
//  NOCBeardMakerViewController.m
//  Nature of Code
//
//  Created by William Lindmeier on 3/9/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCBeardMakerViewController.h"

@interface NOCBeardMakerViewController ()
{
    UIImageView *_imgViewBeard;
}

@end

@implementation NOCBeardMakerViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIImage *imgMask0 = [UIImage imageNamed:@"beard_mask_0"];
    _imgViewBeard = [[UIImageView alloc] initWithImage:imgMask0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _imgViewBeard.center = CGPointMake(_sizeView.width * 0.5,
                                       _sizeView.height * 0.5);
    [self.view addSubview:_imgViewBeard];
    [self loadMatrix];
}

- (void)loadMatrix
{
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(_imgViewBeard.image.CGImage));
    const UInt8* data = CFDataGetBytePtr(pixelData);
    CGSize sizeBeard = _imgViewBeard.frame.size;
    
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
                //UInt8 r = data[pixelIdx + 0];
                //UInt8 g = data[pixelIdx + 1];
                //UInt8 b = data[pixelIdx + 2];
                UInt8 a = data[pixelIdx + 3];
                if(a > 50){
                    
                    float scalarX = pxX / sizeBeard.width;
                    float scalarY = pxY / sizeBeard.height;
                    [outp addObject:[NSString stringWithFormat:@"%f, %f,", scalarX, scalarY]];
                    // Add a dot
                    CALayer *l = [[CALayer alloc] init];
                    l.backgroundColor = [UIColor yellowColor].CGColor;
                    l.bounds = CGRectMake(0,0,4,4);
                    l.cornerRadius = 2;
                    l.position = CGPointMake(pxX,pxY);
                    [_imgViewBeard.layer addSublayer:l];
                }
            }
        }
    }
    NSLog(@"static int NumHairsBeard0 = %i;", outp.count);
    NSLog(@"\n%@", [outp componentsJoinedByString:@"\n"]);
    
}

- (void)draw
{
    glClearColor(0.5,0.5,0.5,1);
    glClear(GL_COLOR_BUFFER_BIT);
}

@end

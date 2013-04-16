//
//  NOCSketch.m
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCSketch.h"

@implementation NOCSketch

- (id)initWithSketchInfo:(NSDictionary *)sketchInfo
{
    self = [super init];
    if(self){
        self.name = [sketchInfo valueForKey:NOCTOCKeySketchName];
        self.description = [sketchInfo valueForKey:NOCTOCKeySketchDescription];
        self.controllerName = [sketchInfo valueForKey:NOCTOCKeySketchControllerName];
        NSString *codeURLString = [sketchInfo valueForKey:NOCTOCKeyCodeURL];
        self.URLCode = [NSURL URLWithString:codeURLString];
        NSString *readModeURLString = [sketchInfo valueForKey:NOCTOCKeyBookURL];
        self.URLReadMore = [NSURL URLWithString:readModeURLString];
    }
    return self;
}

@end

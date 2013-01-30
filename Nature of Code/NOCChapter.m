//
//  NOCChapter.m
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCChapter.h"
#import "NOCSketch.h"

@implementation NOCChapter

- (id)initWithDictionary:(NSDictionary *)chapterInfo
{
    self = [super init];
    if(self){
        self.name = [chapterInfo valueForKey:NOCTOCKeyChapterName];
        NSArray *sketchInfos = [chapterInfo valueForKey:NOCTOCKeyChapterSketches];
        NSMutableArray *chSketches = [NSMutableArray arrayWithCapacity:5];
        for(NSString *sketchName in sketchInfos){
            NOCSketch *s = [[NOCSketch alloc] init];
            s.name = sketchName;
            [chSketches addObject:s];
        }
        self.sketches = [NSArray arrayWithArray:chSketches];
    }
    return self;
}

@end

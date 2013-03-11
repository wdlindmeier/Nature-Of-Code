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
        self.weekNumber = [chapterInfo valueForKey:NOCTOCKeyWeekNumber];
        NSArray *sketchInfos = [chapterInfo valueForKey:NOCTOCKeyChapterSketches];
        NSMutableArray *chSketches = [NSMutableArray arrayWithCapacity:5];
        for(NSDictionary *sketchInfo in sketchInfos){
            NOCSketch *s = [[NOCSketch alloc] initWithSketchInfo:sketchInfo];
            [chSketches addObject:s];
        }
        self.sketches = [NSArray arrayWithArray:chSketches];
    }
    return self;
}

@end

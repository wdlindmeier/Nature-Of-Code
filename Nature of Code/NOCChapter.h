//
//  NOCChapter.h
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NOCChapter : NSObject

- (id)initWithDictionary:(NSDictionary *)chapterInfo;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *sketches;

@end

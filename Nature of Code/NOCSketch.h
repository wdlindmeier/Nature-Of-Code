//
//  NOCSketch.h
//  Nature of Code
//
//  Created by William Lindmeier on 1/30/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NOCSketch : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, copy) NSString *controllerName;
@property (nonatomic, strong) NSURL *URLReadMore;
@property (nonatomic, strong) NSURL *URLCode;

- (id)initWithSketchInfo:(NSDictionary *)sketchInfo;

@end

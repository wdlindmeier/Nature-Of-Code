//
//  NOCBreeder.h
//  Nature of Code
//
//  Created by William Lindmeier on 4/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NOCBreeder : NSObject
{
}

@property (nonatomic, assign) int DNALength;
@property (nonatomic, assign) float fitness;
@property (nonatomic, assign) int generation;
@property (nonatomic, strong) NSArray *DNA;

- (id)initWithDNALength:(int)DNALength;

- (NOCBreeder *)crossover:(NOCBreeder *)mate;
- (void)randomizeDNA;
- (void)inheritDNA:(NSArray *)dna1 :(NSArray *)dna2;
- (void)mutate;

+ (double)mutationRate;
+ (void)setMutationRate:(double)newRate;

@end

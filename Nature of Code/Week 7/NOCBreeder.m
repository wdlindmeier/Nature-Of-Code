//
//  NOCBreeder.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCBreeder.h"

@implementation NOCBreeder
{
}

- (id)initWithDNALength:(int)DNALength
{
    self = [self init];
    if(self){
        self.DNALength = DNALength;
        self.fitness = 0;
    }
    return self;
}

- (void)randomizeDNA
{
    NSMutableArray *newDNA = [NSMutableArray arrayWithCapacity:self.DNALength];
    for(int i=0;i<self.DNALength;i++){
        [newDNA addObject:@(RandScalar())];
    }
    self.DNA = [NSArray arrayWithArray:newDNA];
    self.generation = 0;
}

// There are a number of different ways to combine parent's DNA,
// so subclasses can implement their own version of this method.
- (void)inheritDNA:(NSArray *)dna1 :(NSArray *)dna2
{
    NSMutableArray *newDNA = [NSMutableArray arrayWithCapacity:self.DNALength];
    int halfwayPoint = self.DNALength / 2;
    for(int i=0;i<self.DNALength;i++){
        // Populate the DNA
        NSNumber *n = (i < halfwayPoint) ? dna1[i] : dna2[i];
        [newDNA addObject:n];
    }
    self.DNA = [NSArray arrayWithArray:newDNA];
}

- (NOCBreeder *)crossover:(NOCBreeder *)mate
{

    NOCBreeder *baby = nil;
    
    baby = [[[self class] alloc] initWithDNALength:self.DNALength];
    
    [baby inheritDNA:[self DNA] :[mate DNA]];
    
    [baby mutate];
    
    baby.generation = MAX(self.generation, mate.generation) + 1;
    
    return baby;
}

- (void)mutate
{
    NSMutableArray *newDNA = [NSMutableArray arrayWithArray:self.DNA];
    for(int i=0;i<self.DNALength;i++){
        if(RandScalar() < BreederMutationRate){
            newDNA[i] = @(RandScalar());
        }
    }
    self.DNA = [NSArray arrayWithArray:newDNA];
}

static double BreederMutationRate = 0.01;

+ (double)mutationRate
{
    return BreederMutationRate;
}

+ (void)setMutationRate:(double)newRate
{
    BreederMutationRate = newRate;
}

@end

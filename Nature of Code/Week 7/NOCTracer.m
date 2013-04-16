//
//  NOCTracer.m
//  Nature of Code
//
//  Created by William Lindmeier on 4/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCTracer.h"
#import "NOCColorHelpers.h"

@implementation NOCTracer
{
}

- (id)initWithLifeSpan:(int)lifespan
{
    int extraDNAcount = 3; // Starting position
    extraDNAcount += 3; // Color
    extraDNAcount += 1; // Spring constraints (length)
    int myDNALength = (lifespan * 3) + extraDNAcount;
    self = [super initWithDNALength:myDNALength];
    if(self){
        [self initTracerWithLifespan:lifespan];
        [self randomizeDNA];
    }
    return self;
}

- (void)initTracerWithLifespan:(int)lifespan
{
    self.framesAlive = 0;
    self.lifespan = lifespan;
}

#pragma mark - DNA

- (void)inheritDNA:(NSArray *)dna1 :(NSArray *)dna2
{
    // NOTE: Randomizing the mid-point gives us more variation
    // between the 2 parents. We probably don't want to randomize
    // each element, since the /order/ of positions may become a
    // valuable aspect of the genotype.

    NSMutableArray *newDNA = [NSMutableArray arrayWithCapacity:self.DNALength];
    int halfwayPoint = arc4random() % self.DNALength;
    for(int i=0;i<self.DNALength;i++){
        // Populate the DNA
        NSNumber *n = (i < halfwayPoint) ? dna1[i] : dna2[i];
        [newDNA addObject:n];
    }
    self.DNA = [NSArray arrayWithArray:newDNA];
}

- (void)expressDNA
{
}

- (NOCTracer *)crossover:(NOCTracer *)mate
{
    NOCTracer *baby = (NOCTracer *)[super crossover:mate];
    [baby initTracerWithLifespan:self.lifespan];
    [baby expressDNA];
    return baby;
}

#pragma mark - Update

- (void)step
{
    if(_framesAlive < self.lifespan - 1){
        // We'll just stop counting when we're dead
        _framesAlive++;
    }
}

#pragma mark - Draw

- (void)glColor:(GLfloat *)components
{
    NOCColorComponentsForColor(components, self.color);
}

- (void)render:(BOOL)colored
{
    //..
}


@end

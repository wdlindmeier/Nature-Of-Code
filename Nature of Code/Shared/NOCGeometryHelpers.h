//
//  NOCOpenGLHelpers.h
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#ifndef Nature_of_Code_NOCOpenGLHelpers_h
#define Nature_of_Code_NOCOpenGLHelpers_h

#define CONSTRAIN(n,min,max)    MIN(MAX(n,min),max)

static inline double drand()   /* uniform distribution, (0..1] */
{
    return (rand()+1.0)/(RAND_MAX+1.0);
}

static inline double randomNormal()
/* normal distribution, centered on 0, std dev 1 */
{
    return sqrt(-2*log(drand())) * cos(2*M_PI*drand());
}

#endif

//
//  NOCShaderProgram.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/2/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCShaderProgram.h"

@implementation NOCShaderProgram
{
    NSDictionary *_uniformLocations;
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if(self){
        self.name = name;
    }
    return self;
}

- (BOOL)load
{
    GLuint vertShader, fragShader;

    // Create shader program.
    self.glPointer = glCreateProgram();
    
    // Create and compile vertex shader.
    NSString *vertShaderPathname = [[NSBundle mainBundle] pathForResource:self.name
                                                         ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile VERTEX shader: %@", self.name);
        return NO;
    }
    
    // Create and compile fragment shader.
    NSString *fragShaderPathname = [[NSBundle mainBundle] pathForResource:self.name
                                                         ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile FRAGMENT shader: %@", self.name);
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(self.glPointer, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(self.glPointer, fragShader);
    
    for(NSString *attrName in self.attributes){
        NSNumber *attrType = self.attributes[attrName];
        glBindAttribLocation(self.glPointer, [attrType intValue], [attrName UTF8String]);
    }

    // Link program.
    if (![self linkProgram:self.glPointer]) {
        
        NSLog(@"Failed to link program: %@", self.name);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (self.glPointer) {
            glDeleteProgram(self.glPointer);
            self.glPointer = 0;
        }
        
        return NO;
    }
    
    NSMutableDictionary *uniformLocations = [NSMutableDictionary dictionaryWithCapacity:self.uniformNames.count];
    for(NSString *uniName in self.uniformNames){
        int uniLoc = glGetUniformLocation(self.glPointer, [uniName UTF8String]);
        uniformLocations[uniName] = @(uniLoc);
    }
    // Store the locations in an immutable collection
    _uniformLocations = [NSDictionary dictionaryWithDictionary:uniformLocations];

    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(self.glPointer, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(self.glPointer, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;

}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader: %@", self.name);
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (void)unload
{
    if (self.glPointer) {
        glDeleteProgram(self.glPointer);
        self.glPointer = 0;
    }
}

- (void)use
{
    glUseProgram(self.glPointer);
}

#pragma mark - Helpers

- (void)setFloat:(const GLfloat)f forUniform:(NSString *)uniformName
{
    NSNumber *uniLoc = self.uniformLocations[uniformName];
    glUniform1f([uniLoc intValue], f);
}

- (void)setInt:(const GLint)i forUniform:(NSString *)uniformName
{
    NSNumber *uniLoc = self.uniformLocations[uniformName];
    glUniform1i([uniLoc intValue], i);
}

- (void)setMatrix3:(const GLKMatrix3)mat forUniform:(NSString *)uniformName
{
    NSNumber *uniLoc = self.uniformLocations[uniformName];
    // default values for count and transpose
    glUniformMatrix3fv([uniLoc intValue], 1, 0, mat.m);
}

- (void)setMatrix4:(const GLKMatrix4)mat forUniform:(NSString *)uniformName
{
    NSNumber *uniLoc = self.uniformLocations[uniformName];
    // default values for count and transpose
    glUniformMatrix4fv([uniLoc intValue], 1, 0, mat.m);
}

- (void)set1DFloatArray:(const GLfloat[])array withNumElements:(int)num forUniform:(NSString *)uniformName
{
    NSNumber *uniLoc = self.uniformLocations[uniformName];
    glUniform1fv([uniLoc intValue], num, array);
}

- (void)set2DFloatArray:(const GLfloat[])array withNumElements:(int)num forUniform:(NSString *)uniformName
{
    NSNumber *uniLoc = self.uniformLocations[uniformName];
    glUniform2fv([uniLoc intValue], num, array);
}

- (void)set3DFloatArray:(const GLfloat[])array withNumElements:(int)num forUniform:(NSString *)uniformName
{
    NSNumber *uniLoc = self.uniformLocations[uniformName];
    glUniform3fv([uniLoc intValue], num, array);
}

- (void)set4DFloatArray:(const GLfloat[])array withNumElements:(int)num forUniform:(NSString *)uniformName
{
    NSNumber *uniLoc = self.uniformLocations[uniformName];
    glUniform4fv([uniLoc intValue], num, array);
}

@end

attribute vec3 position;
attribute vec2 texCoordA;
attribute vec2 texCoordB;

uniform mat4 modelViewProjectionMatrix;

varying lowp vec2 texCoordVaryingA;
varying lowp vec2 texCoordVaryingB;

void main()
{
    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
    
    texCoordVaryingA = texCoordA; // vec2(texCoordA.x, 1.0-texCoordA.y);
    texCoordVaryingB = texCoordB; // No mapping required
}


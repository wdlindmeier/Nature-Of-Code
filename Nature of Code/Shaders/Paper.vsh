// Also set in the frag shader.
// Is there a way to make this a global variable?
const int NumFlames = 10;

attribute vec3 position;
attribute vec2 texCoord;

uniform mat4 modelViewProjectionMatrix;
uniform vec3 flamePositions[NumFlames];

varying lowp vec3 positionVarying;
varying lowp vec2 textureCoordinate;

void main()
{
    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
    positionVarying = position.xyz;
    // I'm not sure why I have to flip the y here.
    textureCoordinate = vec2(texCoord.x, 1.0-texCoord.y);
}


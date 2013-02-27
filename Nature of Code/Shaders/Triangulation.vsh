attribute vec3 position;
attribute vec2 texCoord;

uniform sampler2D texture;
uniform mat4 modelViewProjectionMatrix;

varying lowp vec2 texCoordVarying;

void main()
{
    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
    texCoordVarying = texCoord;
}


attribute vec4 color;
attribute vec3 position;
attribute vec2 texCoord;

uniform mat4 modelViewProjectionMatrix;
uniform sampler2D texture;

varying vec4 colorVarying;
varying vec2 textureCoordinate;

void main()
{
    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
    colorVarying = color;
    textureCoordinate = texCoord.xy;
}


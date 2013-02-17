attribute vec3 position;
attribute vec2 texCoord;

varying vec2 textureCoordinate;

uniform mat4 modelViewProjectionMatrix;
uniform sampler2D texture;

void main()
{
    textureCoordinate = texCoord.xy;
    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
}


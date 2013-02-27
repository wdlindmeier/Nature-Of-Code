attribute vec3 position;
attribute vec2 texCoord;

uniform mat4 modelViewProjectionMatrix;
uniform sampler2D texture;

varying vec2 textureCoordinate;

void main()
{
    textureCoordinate = texCoord.xy;
    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
}


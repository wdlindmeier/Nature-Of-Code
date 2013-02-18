attribute vec3 position;
attribute vec2 texCoord;

varying vec2 textureCoordinate;
varying highp float depthVarying;

uniform mat4 modelViewProjectionMatrix;
uniform sampler2D texture;

void main()
{
    textureCoordinate = texCoord.xy;
    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
    // We know the depth is from 0 - 3
    depthVarying = (5.5 - gl_Position.z) * 0.3;
}
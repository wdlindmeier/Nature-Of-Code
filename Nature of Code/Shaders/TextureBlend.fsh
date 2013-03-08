uniform lowp float alphaB;

uniform mediump sampler2D textureA;
uniform mediump sampler2D textureB;

varying lowp vec2 texCoordVaryingA;
varying lowp vec2 texCoordVaryingB;

void main()
{
    lowp vec4 colorA = texture2D(textureA, texCoordVaryingA);
    lowp vec4 colorB = texture2D(textureB, texCoordVaryingB);
    lowp float alphaA = 1.0-alphaB;
    gl_FragColor = colorB; //(colorA * alphaA) + (colorB * alphaB);
}
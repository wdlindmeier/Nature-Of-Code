uniform sampler2D texture;

uniform mediump vec2 translation;
uniform mediump float scale;

varying lowp vec2 texCoordVarying;

void main()
{
    gl_FragColor = texture2D(texture, texCoordVarying);
}
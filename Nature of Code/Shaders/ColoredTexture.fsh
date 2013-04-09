varying lowp vec4 colorVarying;
varying highp vec2 textureCoordinate;
uniform sampler2D texture;

void main()
{
    lowp vec4 texColor = texture2D(texture, textureCoordinate);
    gl_FragColor = colorVarying * texColor;
}
varying highp vec2 textureCoordinate;
uniform sampler2D texture;
uniform mediump float scalarAge;

void main()
{
    mediump vec4 color = texture2D(texture, textureCoordinate);
    gl_FragColor = color * (1.0-scalarAge);

}
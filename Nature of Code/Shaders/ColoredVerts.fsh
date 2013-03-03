// uniform lowp vec4 color;
varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
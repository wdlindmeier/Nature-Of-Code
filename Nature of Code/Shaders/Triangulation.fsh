uniform sampler2D texture;

varying lowp vec2 texCoordVarying;

void main()
{
    /*
    highp float stepAmtColor = 10.0;
    highp float cR = round(colorVarying.x * stepAmtColor) / stepAmtColor;
    highp float cG = round(colorVarying.y * stepAmtColor) / stepAmtColor;
    highp float cB = round(colorVarying.z * stepAmtColor) / stepAmtColor;
    highp vec4 colorVer = vec4(cR,cG,cB,1.0);
    
    highp float stepAmtTex = 10.0;
    lowp float texX = round(texCoordVarying.x * stepAmtTex) / stepAmtTex;
    lowp float texY = round(texCoordVarying.y * stepAmtTex) / stepAmtTex;;
    highp vec4 colorTex = texture2D(texture, vec2(texX, texY));
    
    gl_FragColor = (colorTex + colorVer) / 2.0;
    */
    
    gl_FragColor = texture2D(texture, texCoordVarying);
    
}
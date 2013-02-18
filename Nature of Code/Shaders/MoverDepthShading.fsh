varying highp vec2 textureCoordinate;
uniform sampler2D texture;

varying highp float depthVarying;

void main()
{
    highp vec4 texColor = texture2D(texture, textureCoordinate);
    highp vec4 shadedColor = texColor * depthVarying;
    gl_FragColor = vec4(shadedColor.xyz, texColor.w); // Don't multiply the sampler alpha
}
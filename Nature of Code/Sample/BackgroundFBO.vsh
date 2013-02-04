attribute vec3 position;
attribute vec2 texCoord;

varying lowp vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;
uniform sampler2D texture;

void main()
{
    colorVarying = texture2D(texture, texCoord);//texture2D(texture, texCoord);//vec4(1.0,0.0,0.0,1.0);//
    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
}


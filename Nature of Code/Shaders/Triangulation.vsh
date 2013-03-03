attribute vec3 position;
attribute vec2 texCoord;

uniform sampler2D texture;
uniform mat4 modelViewProjectionMatrix;
uniform vec3 translation;
uniform float scale;

varying lowp vec2 texCoordVarying;

void main()
{
    vec3 positionTranslated = (position * scale) + translation;
    gl_Position = modelViewProjectionMatrix * vec4(positionTranslated, 1.0);

    vec2 uvTranslation = vec2(translation.x * 0.5,
                              translation.y * -0.5);
    
    // This allows us to scale using the position scalar
    float tx = ((texCoord.x * 2.0) - 1.0) * scale;
    float ty = ((texCoord.y * 2.0) - 1.0) * scale;
    
    tx = (tx * 0.5) + 0.5;
    ty = (ty * 0.5) + 0.5;
    
    texCoordVarying = vec2(tx, ty) + uvTranslation;

}


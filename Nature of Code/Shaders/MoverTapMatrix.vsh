attribute vec3 position;
attribute vec3 normal;
attribute vec4 color;

varying lowp vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;

void main()
{
    
    vec3 eyeNormal = normalize(normalMatrix * normal);
    vec3 lightPosition = vec3(0.0, 1.0, 3.0);
    float nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
    
    colorVarying = color * nDotVP;
    //colorVarying = vec4(1.0, 0, 0, 1.0) * nDotVP;

    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
    
}


attribute vec3 position;
attribute vec4 color;

uniform mat4 modelViewProjectionMatrix;
uniform vec3 pointPositions[1000]; // Lame. What's the best approach here?
uniform int numPoints;

varying lowp vec3 positionVarying;
varying lowp vec4 colorVarying;

void main()
{
    
    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
    positionVarying = position.xyz;
    colorVarying = color;
    
}


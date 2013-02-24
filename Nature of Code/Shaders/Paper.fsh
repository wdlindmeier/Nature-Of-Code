// Also set in the vert shader.
const int NumFlames = 10;

uniform lowp vec3 flamePositions[NumFlames];
varying lowp vec3 positionVarying;

varying lowp vec2 textureCoordinate;
uniform lowp sampler2D texture;

void main()
{
    lowp float maxDist = 0.1;
    lowp float whiteness = 0.0;
    for(int i=0;i<NumFlames;i++){
        lowp vec3 flameLoc = flamePositions[i];
        lowp float xDelta = positionVarying.x - flameLoc.x;
        lowp float yDelta = positionVarying.y - flameLoc.y;
        lowp float distance = sqrt((xDelta*xDelta)+(yDelta*yDelta));
        whiteness += max(maxDist-distance, 0.0);
    }
    lowp vec4 prevColor = texture2D(texture, textureCoordinate);
    lowp float w = max(prevColor.x, min((whiteness / maxDist), 1.0));
    gl_FragColor = vec4(w,w,w,1.0);
}
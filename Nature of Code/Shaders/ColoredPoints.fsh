uniform int numPoints;
uniform lowp float pointSize;
uniform lowp vec3 pointPositions[1000];

varying lowp vec3 positionVarying;
varying lowp vec4 colorVarying;

void main()
{
    lowp float amt = 0.0;
    // NOTE: This is highly inefficient, but it's good enough for quick-and-dirty points
    for(int i=0;i<numPoints;i++){
        lowp vec3 pointLoc = pointPositions[i];
        lowp float xDelta = positionVarying.x - pointLoc.x;
        lowp float yDelta = positionVarying.y - pointLoc.y;
        lowp float distance = sqrt((xDelta*xDelta)+(yDelta*yDelta));
        amt += floor(pointSize / distance);
    }
    gl_FragColor = colorVarying * amt;
}
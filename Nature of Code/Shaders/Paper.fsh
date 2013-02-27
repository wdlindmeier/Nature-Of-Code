// Also set in the vert shader.
const int NumFlames = 10;

uniform lowp vec3 flamePositions[NumFlames];
varying lowp vec3 positionVarying;

varying lowp vec2 textureCoordinate;
uniform mediump sampler2D texture;

void main()
{
    lowp float maxDist = 0.1;
    lowp float whiteness = 0.0;
    for(int i=0;i<NumFlames;i++){
        lowp vec3 flameLoc = flamePositions[i];
        lowp float xDelta = positionVarying.x - flameLoc.x;
        lowp float yDelta = positionVarying.y - flameLoc.y;
        lowp float distance = sqrt((xDelta*xDelta)+(yDelta*yDelta));

        /*
        // This makes the burn trail all black
        // Is there a way to do this without an if?
        if(distance < maxDist*0.5){
            whiteness += 1.0;
        }
        */
        
        // Gradient
        whiteness += max(maxDist-distance, 0.0) * 1.25;
    }
    lowp vec4 prevColor = texture2D(texture, textureCoordinate);
    lowp float w = min(prevColor.x, max((1.0-(whiteness / maxDist)), 0.0));
    gl_FragColor = vec4(w,w,w,1.0);
}
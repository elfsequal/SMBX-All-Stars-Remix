#version 120
#include "shaders/logic.glsl"
uniform sampler2D iChannel0;
uniform float time;

float dist(float dx, float dy) 
{
	return sqrt(dx*dx + dy*dy);
}

void main()
{
    vec2 pos = gl_TexCoord[0].xy;

	float d = dist(pos.x-0.5, pos.y-0.5);
	gl_FragColor = vec4(1,1,0,1)*le(d, 0.5)*ge(d, time*0.5)*(1-time);
}
#version 120
uniform sampler2D iChannel0;

uniform vec2 screenSize = vec2(800,600);

uniform vec2 position;
uniform float radius;
uniform float ringSize;

uniform vec4 color;

void main()
{
	vec2 xy = gl_TexCoord[0].xy*screenSize;
	vec2 dist = (position-(normalize(position-xy)*radius))-xy;

	vec4 c = color;

	c.a *= (1-(abs(length(dist))/(ringSize/2)));
	c.rgb *= c.a;
	
	gl_FragColor = c*gl_Color;
}
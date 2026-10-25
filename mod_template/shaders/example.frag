#pragma header

uniform float u_time;

void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec4 color = flixel_texture2D(bitmap, uv);
    gl_FragColor = color;
}

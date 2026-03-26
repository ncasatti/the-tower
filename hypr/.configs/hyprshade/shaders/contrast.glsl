#version 330 core
in vec2 fragCoord;
out vec4 fragColor;
uniform sampler2D tex;

#define CONTRAST 1.2

void main() {
    vec4 color = texture(tex, fragCoord);
    color.rgb = (color.rgb - 0.5) * CONTRAST + 0.5;
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    fragColor = color;
}

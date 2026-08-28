shader_type canvas_item;

// Allows you to adjust the thickness of the ring inside the Godot Inspector
uniform float thickness : hint_range(0.01, 0.5) = 0.05;

void fragment() {
    // Calculate the distance of the current pixel from the center (0.5, 0.5)
    float distance_from_center = length(UV - vec2(0.5));
    
    // Outer edge boundary (radius of 0.5)
    float outer_circle = smoothstep(0.5, 0.495, distance_from_center);
    
    // Inner edge boundary (radius of 0.5 minus thickness)
    float inner_circle = smoothstep(0.5 - thickness, (0.5 - thickness) - 0.005, distance_from_center);
    
    // Subtract the inner circle from the outer circle to leave a ring
    float ring = outer_circle - inner_circle;
    
    // Apply the ring transparency mask to the ColorRect's color
    COLOR.a *= ring;
}
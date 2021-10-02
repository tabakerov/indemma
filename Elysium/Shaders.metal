//
//  Shaders.metal
//  streamProjectOne
//
//  Created by Dmitry Tabakerov on 27.01.21.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float2 uv;
};

struct Particle {
    float2 position;
    float2 direction;
    float3 intensity;
};

kernel void compute_function_move(texture2d<half, access::write> texture [[texture(0)]],
                             device Particle *particles [[buffer(0)]],
                             uint index [[thread_position_in_grid]])
{
   
    const float dimensions = 2000;
    
    texture.write(0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    
    particles[index].position += 0.25 * particles[index].direction;
    particles[index].position.x = fmod(particles[index].position.x + dimensions, dimensions);
    particles[index].position.y = fmod(particles[index].position.y + dimensions, dimensions);
    
    texture.write(0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    
    particles[index].position += 0.25 * particles[index].direction;
    particles[index].position.x = fmod(particles[index].position.x + dimensions, dimensions);
    particles[index].position.y = fmod(particles[index].position.y + dimensions, dimensions);
    
    texture.write(0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    
    particles[index].position += 0.25 * particles[index].direction;
    particles[index].position.x = fmod(particles[index].position.x + dimensions, dimensions);
    particles[index].position.y = fmod(particles[index].position.y + dimensions, dimensions);
    
    texture.write(0.25*half4(particles[index].intensity.r, particles[index].intensity.g, particles[index].intensity.b, 1.0), uint2(particles[index].position));
    particles[index].position += 0.25 * particles[index].direction;
    
    particles[index].position.x = fmod(particles[index].position.x + dimensions, dimensions);
    particles[index].position.y = fmod(particles[index].position.y + dimensions, dimensions);
}

kernel void compute_function_rotate(
                             texture2d<half, access::read> textureSamp [[texture(0)]],
                             device Particle *particles [[buffer(0)]],
                             uint index [[thread_position_in_grid]]) {

    
    const float2x2 streight = float2x2(1.0, 0.0, 0.0, 1.0);
    const float angle = 0.15;
    const float2x2 rot_right = float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
    const float2x2 rot_left = float2x2(cos(-angle), -sin(-angle), sin(-angle), cos(-angle));
    const float angle_sample = 0.25;
    const float2x2 sample_rot_right = float2x2(cos(angle_sample), -sin(angle_sample), sin(angle_sample), cos(angle_sample));
    const float2x2 sample_rot_left = float2x2(cos(-angle_sample), -sin(-angle_sample), sin(-angle_sample), cos(-angle_sample));
    
    float2x2 rot = streight;
    
    
    half l_sample = length(textureSamp.read(uint2(particles[index].position + 1.5*(sample_rot_left * particles[index].direction))));
    half r_sample = length(textureSamp.read(uint2(particles[index].position + 1.5*(sample_rot_right * particles[index].direction))));
    half f_sample = length(textureSamp.read(uint2(particles[index].position + 1.5*(particles[index].direction))));
    rot = streight;
                                 if (particles[index].intensity.x + particles[index].intensity.y + particles[index].intensity.z > 0) {
    if (l_sample > r_sample && l_sample > f_sample) {
        rot = rot_left;
    }
    if (r_sample > l_sample && r_sample > f_sample) {
        rot = rot_right;
    }
                                 } else {
                                     if (l_sample > r_sample && l_sample > f_sample) {
                                         rot = rot_right;
                                     }
                                     if (r_sample > l_sample && r_sample > f_sample) {
                                         rot = rot_left;
                                     }
                                 }
   
    particles[index].direction = rot * particles[index].direction;
    
}


kernel void blur_function(texture2d<half, access::read> textureRead [[texture(0)]],
                          texture2d<half, access::write> textureWrite [[texture(1)]],
                          uint2 index [[thread_position_in_grid]])
{
    
    const uint dimensions = 2000;
    uint x0 = (index.x - 1 + dimensions) % dimensions;
    uint x2 = (index.x + 1) % dimensions;
    uint y0 = (index.y - 1 + dimensions) % dimensions;
    uint y2 = (index.y + 1) % dimensions;
    half4 out = 1.0/4.0 * textureRead.read(index)
    + 1.0/8.0 * textureRead.read(uint2(index.x, y0))
    + 1.0/8.0 * textureRead.read(uint2(index.x, y2))
    + 1.0/8.0 * textureRead.read(uint2(x0, index.y))
    + 1.0/8.0 * textureRead.read(uint2(x2, index.y))
    + 1.0/16.0 * textureRead.read(uint2(x0, y0))
    + 1.0/16.0 * textureRead.read(uint2(x2, y0))
    + 1.0/16.0 * textureRead.read(uint2(x0, y2))
    + 1.0/16.0 * textureRead.read(uint2(x2, y2));
    
    textureWrite.write(0.99*half4(out.rgba), index);
    //textureWrite.write(0.9*textureRead.read(index), index);
}

vertex Vertex vertex_function(constant float4 *vertices [[buffer(0)]],
                              uint id [[vertex_id]]) {
    return {
        .position = vertices[id],
        .uv =  (vertices[id].xy + float2(1)) / float2(2)
    };
}

fragment float4 fragment_function(Vertex v [[stage_in]],
                                  texture2d<float> texture [[texture(0)]]) {
    constexpr sampler smplr(coord::normalized,
                            address::clamp_to_zero,
                            filter::nearest);
    //return (float4(v.uv.x, v.uv.y, 0.0, 1.0));
    return texture.sample(smplr, v.uv);
};

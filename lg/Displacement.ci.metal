#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

// 32-bit Wang hash (fast, decent decorrelation)
inline uint wang_hash(uint x) {
    x = (x ^ 61u) ^ (x >> 16);
    x *= 9u;
    x = x ^ (x >> 4);
    x *= 0x27d4eb2d;
    x = x ^ (x >> 15);
    return x;
}

inline float3 rand01(float2 p, uint seed) {
    // Convert float2 to unique 32-bit integers with scaling
    uint2 ip = uint2(floor(p * 43758.5453 + float2(seed, seed * 17)));

    // Mix coordinates and seed to get decorrelated channels
    uint h1 = wang_hash(ip.x + ip.y * 374761393u + seed * 668265263u);
    uint h2 = wang_hash(ip.x * 3266489917u + ip.y + seed * 374761393u);
    uint h3 = wang_hash(ip.x * 668265263u + ip.y * 2246822519u + seed * 3266489917u);

    // Convert to [0,1)
    float invMax = 1.0 / 4294967296.0; // 1 / 2^32
    return float3(float(h1) * invMax,
                  float(h2) * invMax,
                  float(h3) * invMax);
}

inline uint makeSeed(float2 p) {
    return uint(floor(p.x) + floor(p.y));
}

float2 clampMirrorCoords(float2 coord, float2 imageSize) {
    float2 result = coord;
    
    // Mirror on X axis
    if (result.x > imageSize.x) {
        result.x = imageSize.x * 2.0 - result.x;
    } else if (result.x < 0.0) {
        result.x = -result.x;
    }
    
    // Mirror on Y axis
    if (result.y > imageSize.y) {
        result.y = imageSize.y * 2.0 - result.y;
    } else if (result.y < 0.0) {
        result.y = -result.y;
    }
    
    return result;
}

// negative inside, 0 on border, positive outside
float roundedBoxSDF(float2 p, float2 halfSize, float radius) {
    
    float r = clamp(radius, 0.0, min(halfSize.x, halfSize.y));
    // Compute distance
    float2 q = abs(p) - (halfSize - float2(r));
    float2 k = max(q, 0.0);
    float d_out = length(k);
    float d_in  = min(max(q.x, q.y), 0.0);

    return d_out + d_in - r;
}

float2 calculateOutwardDirection(float2 point, float2 halfRectSize) {
    float2 d = point/halfRectSize;
    return normalize(d);
}

extern "C" float4 displacementMapGeneratorKernel(
                                                 float imageWidth,
                                                 float imageHeight,
                                                 float radius,
                                                 float bezel,
                                                 float magic,
                                                 float rim,
                                                 float noise,
                                                 coreimage::destination dest)
{
    float2 coord = dest.coord();
    
    // some handy values
    float2 size = float2(imageWidth, imageHeight);
    float2 center = size * 0.5;
    float shortSide = min(imageWidth, imageHeight);
    float2 coordRel = coord - center;
    
    // Outward direction vector
    float2 outwardVector = calculateOutwardDirection(coordRel, center);

    // calculate distance to edge
    float dte = roundedBoxSDF(coordRel, center, radius);
    // inverted, argumented, clamped, shifted
    float val = clamp(- dte * bezel * 2.0 / shortSide , 0.0, 1.0) - 1;
    // magic formula calculate how much should displace given pixel
    float bend = -((magic+1)*val*val*val+magic*val*val);

    float red = bend*outwardVector.x * 0.5 + 0.5;
    float green = bend*outwardVector.y * 0.5 + 0.5;
    float blue = bend; // will be used for abberation effect
    
    // apply noise if exist
    if (noise > 0) {
        uint seed = makeSeed(coord);
        float3 rand = rand01(coord, seed) - 0.5;
        red = red + noise * rand.y * rand.z;
        green = green + noise * rand.y * rand.z;
    }
    
    // apply rim effect if exist
    if (abs(rim) >= 0.02) { //just to have tolaeance for slider
        if (dte*dte <= 9.0) { //1 points 3 pixel dencity squared
            red = rim*outwardVector.x * 0.5 + 0.5;
            green = rim*outwardVector.y * 0.5 + 0.5;
            blue = 0.0;
        }
    }
    
    float alpha = (dte > 0 ) ? 0.0 : 1.0;
    
    return float4(red, green, blue, alpha);
}

extern "C" float4 displacementMapDistortsionKernel(coreimage::sampler image,
                                           coreimage::sampler displacement,
                                           float scale,
                                           float radius,
                                           float padding,
                                           float abberation,
                                           float imageWidth,
                                           float imageHeight,
                                           coreimage::destination dest) {
    float2 coord = dest.coord();
    
    if (coord.x < padding || coord.x - padding > imageWidth ||
        coord.y < padding || coord.y - padding > imageHeight) {
        return float4(0);
    }

    float2 displacementValue = displacement.sample(displacement.transform(coord-padding)).rg;
    displacementValue = displacementValue -0.5; // offset
    
    // Apply different displacements for each channel
    
    float2 redDisplacement = displacementValue * scale * (-1.0 + 0.2 * abberation);
    float2 greenDisplacement = displacementValue * scale * -1.0;
    float2 blueDisplacement = displacementValue * scale * (-1.0 - 0.3 * abberation);
    
    // Calculate new coordinates for each channel
    float2 imageSize = float2(imageWidth, imageHeight) + 2.0 * float2(padding);
    float2 redCoord = clampMirrorCoords(coord + redDisplacement, imageSize);
    float2 greenCoord = clampMirrorCoords(coord + greenDisplacement, imageSize);
    float2 blueCoord = clampMirrorCoords(coord + blueDisplacement, imageSize);
    float2 alphaCoord = clampMirrorCoords(coord + greenDisplacement, imageSize);
    
    // Sample each channel with corresponding displacement
    float red = image.sample(image.transform(redCoord)).r;
    float green = image.sample(image.transform(greenCoord)).g;
    float blue = image.sample(image.transform(blueCoord)).b;
    float alpha = image.sample(image.transform(alphaCoord)).a;
    
    return float4(red, green, blue, alpha);
}

extern "C" float4 passthrough(coreimage::sampler image, coreimage::destination dest) {
    float2 coord = dest.coord();
    return image.sample(image.transform(coord));
}

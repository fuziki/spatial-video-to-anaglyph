//
//  kernel.metal
//  spatial-video-to-anaglyph
//
//  Created by fuziki on 2024/01/23.
//

#include <metal_stdlib>
using namespace metal;
#include <CoreImage/CoreImage.h>

extern "C" {
    namespace coreimage {
        float4 anaglyph(coreimage::sample_t i, coreimage::sample_t v, coreimage::destination dest) {
            i.gb = v.gb;
            return i;
        }
    }
}

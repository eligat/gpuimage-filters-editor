//
//  IRGPUImageNormalBlendFilter.m
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 8/5/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import "IRGPUImageBlendFilters.h"

#pragma mark HELPER FUNCTIONS
NSString * const hslColorSpaceHelperFunctions = SHADER_STRING
(
 mediump vec3 RGBToHSL(mediump vec3 color) {
   mediump vec3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
   
   mediump float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
   mediump float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
   mediump float delta = fmax - fmin;             //Delta RGB value
   
   hsl.z = (fmax + fmin) / 2.0; // Luminance
   
   if (delta == 0.0)		//This is a gray, no chroma...
       {
     hsl.x = 0.0;	// Hue
     hsl.y = 0.0;	// Saturation
       }
   else                                    //Chromatic data...
       {
     if (hsl.z < 0.5)
       hsl.y = delta / (fmax + fmin); // Saturation
     else
       hsl.y = delta / (2.0 - fmax - fmin); // Saturation
     
     mediump float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
     mediump float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
     mediump float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;
     
     if (color.r == fmax )
       hsl.x = deltaB - deltaG; // Hue
     else if (color.g == fmax)
       hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
     else if (color.b == fmax)
       hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue
     
     if (hsl.x < 0.0)
       hsl.x += 1.0; // Hue
     else if (hsl.x > 1.0)
       hsl.x -= 1.0; // Hue
       }
   
   return hsl;
 }
 
 mediump float HueToRGB(mediump float f1, mediump float f2, mediump float hue) {
   if (hue < 0.0)
     hue += 1.0;
   else if (hue > 1.0)
     hue -= 1.0;
   mediump float res;
   if ((6.0 * hue) < 1.0)
     res = f1 + (f2 - f1) * 6.0 * hue;
   else if ((2.0 * hue) < 1.0)
     res = f2;
   else if ((3.0 * hue) < 2.0)
     res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
   else
     res = f1;
   return res;
 }
 
 mediump vec3 HSLToRGB(mediump vec3 hsl) {
   mediump vec3 rgb;
   
   if (hsl.y == 0.0)
     rgb = vec3(hsl.z); // Luminance
   else
       {
     mediump float f2;
     
     if (hsl.z < 0.5)
       f2 = hsl.z * (1.0 + hsl.y);
     else
       f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
     
     mediump float f1 = 2.0 * hsl.z - f2;
     
     rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
     rgb.g = HueToRGB(f1, f2, hsl.x);
     rgb.b= HueToRGB(f1, f2, hsl.x - (1.0/3.0));
       }
   
   return rgb;
 }
);

NSString * const overlayF = SHADER_STRING
(
 mediump float overlayF(mediump float base, mediump float blend) {
   return (base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)));
 }
);

NSString * const linearBurnF = SHADER_STRING
(
 mediump float linearBurnF(mediump float base, mediump float blend) {
   return max(base + blend - 1.0, 0.0);
 }
 );

NSString * const linearDodgeF = SHADER_STRING
(
 mediump float linearDodgeF(mediump float base, mediump float blend) {
   return min(base + blend, 1.0);
 }
);

NSString * const colorBurnF = SHADER_STRING
(
 mediump float colorBurnF(mediump float base, mediump float blend) {
   return ((blend == 0.0) ? blend : max((1.0 - ((1.0 - base) / blend)), 0.0));
 }
 );

NSString * const colorDodgeF = SHADER_STRING
(
 mediump float colorDodgeF(mediump float base, mediump float blend) {
   return ((blend == 1.0) ? blend : min(base / (1.0 - blend), 1.0));
 }
);

NSString * const darkenF = SHADER_STRING
(
 mediump float darkenF(mediump float base, mediump float blend) {
   return min(base, blend);
 }
);

NSString * const lightenF = SHADER_STRING
(
 mediump float lightenF(mediump float base, mediump float blend) {
   return max(base, blend);
 }
);

NSString * const reflectF = SHADER_STRING
(
 mediump float reflectF(mediump float base, mediump float blend) {
   return ((blend == 1.0) ? blend : min(base * base / (1.0 - blend), 1.0));
 }
);

NSString * const vividLightF = SHADER_STRING
(
 mediump float vividLightF(mediump float base, mediump float blend) {
   return ((blend < 0.5) ?
           colorBurnF(base, (2.0 * blend)) :
           colorDodgeF(base, (2.0 * (blend - 0.5))));
 }
);


#pragma mark Normal
@implementation IRGPUImageNormalBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = blend;
  );
}
@end

#pragma mark Add (Linear Dodge)
@implementation IRGPUImageAddBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = min(base + blend, vec3(1.0));
   );
}
@end

#pragma mark Average
@implementation IRGPUImageAverageBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = ((base + blend) / 2.0);
   );
}
@end

#pragma mark Color
@implementation IRGPUImageColorBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   mediump vec3 blendHSL = RGBToHSL(blend);
   color = HSLToRGB(vec3(blendHSL.r, blendHSL.g, RGBToHSL(base).b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return hslColorSpaceHelperFunctions;
}
@end

#pragma mark ColorBurn
@implementation IRGPUImageColorBurnBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(colorBurnF(base.r, blend.r),
                colorBurnF(base.g, blend.g),
                colorBurnF(base.b, blend.b));
  );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return colorBurnF;
}
@end

#pragma mark Color Dodge
@implementation IRGPUImageColorDodgeBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(colorDodgeF(base.r, blend.r),
                colorDodgeF(base.g, blend.g),
                colorDodgeF(base.b, blend.b));
  );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return colorDodgeF;
}
@end

#pragma mark Darken
@implementation IRGPUImageDarkenBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = min(base,blend);
  );
}
@end

#pragma mark Difference
@implementation IRGPUImageDifferenceBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = abs(base-blend);
  );
}
@end

#pragma mark Divide
@implementation IRGPUImageDivideBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(divideF(base.r, blend.r),
                divideF(base.g, blend.g),
                divideF(base.b, blend.b));
  );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return SHADER_STRING
  (
   mediump float divideF(mediump float base, mediump float blend) {
     return (blend == 0.0) ? 1.0 : base/blend;
   }
  );
}
@end

#pragma mark Exclusion
@implementation IRGPUImageExclusionBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = (base + blend - 2.0 * base * blend);
   );
}
@end

#pragma mark Glow
@implementation IRGPUImageGlowBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(reflectF(blend.r, base.r),
                reflectF(blend.g, base.g),
                reflectF(blend.b, base.b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return reflectF;
}
@end

#pragma mark Hard Light
@implementation IRGPUImageHardLightBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(overlayF(blend.r, base.r),
                overlayF(blend.g, base.g),
                overlayF(blend.b, base.b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return overlayF;
}
@end

#pragma mark Hard Mix
@implementation IRGPUImageHardMixBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(hardMixF(base.r, blend.r),
                hardMixF(base.g, blend.g),
                hardMixF(base.b, blend.b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  NSString *hardMixF = SHADER_STRING
  (
   mediump float hardMixF(mediump float base, mediump float blend) {
     return ((vividLightF(base, blend) < 0.5) ? 0.0 : 1.0);
   }
  );
  
  NSString *str = [NSString stringWithFormat:@"%@\n%@\n%@\n%@",
                   colorBurnF, colorDodgeF, vividLightF, hardMixF];
  
  return str;
}
@end

#pragma mark Hue
@implementation IRGPUImageHueBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   mediump vec3 baseHSL = RGBToHSL(base);
   color = HSLToRGB(vec3(RGBToHSL(blend).r, baseHSL.g, baseHSL.b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return hslColorSpaceHelperFunctions;
}
@end

#pragma mark Lighten
@implementation IRGPUImageLightenBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = max(base,blend);
   );
}
@end

#pragma mark Linear Burn
@implementation IRGPUImageLinearBurnBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = max(base + blend - 1.0, 0.0);
   );
}
@end

#pragma mark Linear Light
@implementation IRGPUImageLinearLightBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(linearLightF(base.r, blend.r),
                linearLightF(base.g, blend.g),
                linearLightF(base.b, blend.b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  NSString *linearLightF = SHADER_STRING
  (
   mediump float linearLightF(mediump float base, mediump float blend) {
     return (blend < 0.5 ?
             linearBurnF(base, (2.0 * blend)) :
             linearDodgeF(base, (2.0 * (blend - 0.5))));
   }
  );
  
  NSString *str = [NSString stringWithFormat:@"%@\n%@\n%@",
   linearBurnF, linearDodgeF, linearLightF];
  
  return str;
}
@end

#pragma mark Luminosity
@implementation IRGPUImageLuminosityBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   mediump vec3 baseHSL = RGBToHSL(base);
   color = HSLToRGB(vec3(baseHSL.r, baseHSL.g, RGBToHSL(blend).b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return hslColorSpaceHelperFunctions;
}
@end

#pragma mark Multiply
@implementation IRGPUImageMultiplyBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = base * blend;
   );
}
@end

#pragma mark Overlay
@implementation IRGPUImageOverlayBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(overlayF(base.r, blend.r),
                overlayF(base.g, blend.g),
                overlayF(base.b, blend.b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return overlayF;
}
@end

#pragma mark Phoenix
@implementation IRGPUImagePhoenixBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = (min(base, blend) - max(base, blend) + vec3(1.0));
  );
}
@end

#pragma mark Pin Light
@implementation IRGPUImagePinLightBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(pinLightF(base.r, blend.r),
                pinLightF(base.g, blend.g),
                pinLightF(base.b, blend.b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  NSString *pinLightF = SHADER_STRING
  (
   mediump float pinLightF(mediump float base, mediump float blend) {
     return ((blend < 0.5) ?
             darkenF(base, (2.0 * blend)) :
             lightenF(base, (2.0 *(blend - 0.5))));
   }
   );
  
  NSString *str = [NSString stringWithFormat:@"%@\n%@\n%@",
                   darkenF, lightenF, pinLightF];
  
  return str;
}
@end

#pragma mark Reflect
@implementation IRGPUImageReflectBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(reflectF(base.r, blend.r),
                reflectF(base.g, blend.g),
                reflectF(base.b, blend.b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return reflectF;
}
@end

#pragma mark Saturation
@implementation IRGPUImageSaturationBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   mediump vec3 baseHSL = RGBToHSL(base);
   color = HSLToRGB(vec3(baseHSL.r, RGBToHSL(blend).g, baseHSL.b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return hslColorSpaceHelperFunctions;
}
@end

#pragma mark Screen
@implementation IRGPUImageScreenBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = (1.0 - ((1.0 - base) * (1.0 - blend)));
   );
}
@end

#pragma mark Soft Light
@implementation IRGPUImageSoftLightBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(softLightF(base.r, blend.r),
                softLightF(base.g, blend.g),
                softLightF(base.b, blend.b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return SHADER_STRING
  (
   mediump float softLightF(mediump float base, mediump float blend) {
     return ((blend < 0.5) ?
             (2.0 * base * blend + base * base * (1.0 - 2.0 * blend)) :
             (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend)));
   }
  );
}
@end

#pragma mark Subtract
@implementation IRGPUImageSubtractBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = max(base - blend, 0.0);
   );
}
@end

#pragma mark Vivid Light
@implementation IRGPUImageVividLightBlendFilter
- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = vec3(vividLightF(base.r, blend.r),
                vividLightF(base.g, blend.g),
                vividLightF(base.b, blend.b));
   );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  NSString *str = [NSString stringWithFormat:@"%@\n%@\n%@",
                   colorBurnF, colorDodgeF, vividLightF];
  
  return str;
}
@end

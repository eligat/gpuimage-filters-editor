//
//  IRGPUImageOpacityFilter.m
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 8/5/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import "IRGPUImageOpacityBlendFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kIRGPUImageOpacityFragmentShaderStringTemplate = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform lowp float opacity;
 
 // Place for additional helper functions
 %@
 
 void main()
 {
    lowp vec4 baseFull = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 blendFull = texture2D(inputImageTexture2, textureCoordinate2);
    lowp vec3 base = baseFull.rgb;
    lowp vec3 blend = blendFull.rgb;
    lowp vec3 color; // pixel color with opacity NOT taken into account

    // Particular blend shader implementation should initialize `color` variable
    %@

    lowp float totalOpacity = opacity * blendFull.a;
    lowp vec3 resultColor = (color * totalOpacity + base * (1.0 - totalOpacity));
    lowp float resultAlpha = baseFull.a + (1.0 - baseFull.a) * blendFull.a;
    gl_FragColor = vec4(resultColor, resultAlpha);
 }
);
#else
NSString *const kIRGPUImageOpacityFragmentShaderStringTemplate = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform float opacity;
 
 // Place for additional helper functions
 %@
 
 void main()
 {
    vec3 base = texture2D(inputImageTexture, textureCoordinate).rgb;
    vec3 blend = texture2D(inputImageTexture2, textureCoordinate2).rgb;
    vec3 color;

    // Particular blend shader implementation should initialize `color` variable
    %@

    vec3 resultColor = color * opacity + base * (1.0 - opacity);
    gl_FragColor = vec4(resultColor, 1.0);
 }
);
#endif

@implementation IRGPUImageOpacityBlendFilter

- (id)init;
{
  NSString *shaderString = [NSString stringWithFormat:
                            kIRGPUImageOpacityFragmentShaderStringTemplate,
                            self.colorBlendShaderHelperFunctionsCode,
                            self.colorBlendShaderCode];
  if (!(self = [super initWithFragmentShaderFromString:shaderString])) {
    return nil;
  }
  
  opacityUniform = [filterProgram uniformIndex:@"opacity"];
  self.opacity = 0.5;
  
  return self;
}


#pragma mark -
#pragma mark Accessors

- (NSString *)colorBlendShaderCode {
  return SHADER_STRING
  (
   color = base;
  );
}

- (NSString *)colorBlendShaderHelperFunctionsCode {
  return @"";
}

- (void)setOpacity:(CGFloat)opacity {
  _opacity = opacity;
  [self setFloat:_opacity forUniform:opacityUniform program:filterProgram];
}

@end

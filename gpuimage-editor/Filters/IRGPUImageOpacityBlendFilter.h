//
//  IRGPUImageOpacityFilter.h
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 8/5/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface IRGPUImageOpacityBlendFilter : GPUImageTwoInputFilter
{
  GLint opacityUniform;
}

/// Opacity of second (overlay) input
@property(readwrite, nonatomic) CGFloat opacity;
@property(readonly, nonatomic) NSString *colorBlendShaderCode;
@property(readonly, nonatomic) NSString *colorBlendShaderHelperFunctionsCode;

@end

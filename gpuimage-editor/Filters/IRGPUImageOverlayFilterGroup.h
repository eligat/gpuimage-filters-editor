//
//  IRGPUImageOverlayFilterGroup.h
//  selfie-battle
//
//  Created by Oleg Sannikov on 9/1/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface IRGPUImageOverlayFilterGroup : GPUImageFilterGroup

@property(nonatomic) GPUImagePicture *overlayPicture;

@end

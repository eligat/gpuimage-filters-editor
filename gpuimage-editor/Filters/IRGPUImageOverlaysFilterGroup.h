//
//  IRGPUImageOverlaysFilterGroup.h
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 10/18/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <GPUImage/GPUImage.h>
/// Class only exists to strongly hold references to overlay pictures
@interface IRGPUImageOverlaysFilterGroup : GPUImageFilterGroup

@property (nonatomic, nonnull) NSArray<GPUImagePicture *> *overlayPictures;

@end

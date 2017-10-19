//
//  IROverlayFilterGroupFactory.h
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 10/18/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IRFilterGroupDescription, IRGPUImageOverlaysFilterGroup;

@protocol IRImageDataSource
- (nullable UIImage *) imageForName:(nonnull NSString *)name;
@end

@interface IROverlayFilterGroupFactory : NSObject

+ (nullable IRGPUImageOverlaysFilterGroup *) overlayFilterGroupWithDescription:(nonnull IRFilterGroupDescription *)description
                                                               imageDataSource:(nonnull id<IRImageDataSource>)imageDataSource;

@end

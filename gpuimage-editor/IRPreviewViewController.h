//
//  IRPreviewViewController.h
//  gpuimage-editor
//
//  Created by Aleksey Mikhailov on 06/02/2017.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GPUImageFilter, IRFilterConfiguration;

@interface IRPreviewViewController : UIViewController

@property(nonatomic, copy, readonly) NSArray<GPUImageFilter *> *filters;
@property(nonatomic, readonly) NSString *filtersCode;
@property(nonatomic, readonly) NSString *overlayFilterCode;

- (void)updatePreviewWithFilterConfigurations:(NSArray<IRFilterConfiguration *> *)configurations;

@end

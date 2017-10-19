//
//  IRFilterGroupDescription.h
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 10/18/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@class IRFilterConfiguration, IRFilterOverlayConfiguration;
@protocol IRFiltersConfiguratorCellData, IRFilterOverlayConfiguration;


@interface IRFilterGroupDescription : JSONModel

@property (nonatomic, nonnull) NSArray<IRFilterConfiguration *> <IRFiltersConfiguratorCellData> *filterConfigurations;
@property (nonatomic, nonnull) NSArray<IRFilterOverlayConfiguration *> <IRFilterOverlayConfiguration> *overlayConfigurations;
@property (nonatomic, readonly) BOOL isEmpty;

@end

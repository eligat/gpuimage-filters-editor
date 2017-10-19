//
//  IRFilterGroupDescription.h
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 10/18/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "IRFilterConfiguration.h"
#import "IRFilterOverlayConfiguration.h"

@protocol IRFilterConfiguration, IRFilterOverlayConfiguration;


@interface IRFilterGroupDescription : JSONModel

@property (nonatomic, nonnull) NSArray<IRFilterConfiguration *> <IRFilterConfiguration> *filterConfigurations;
@property (nonatomic, nonnull) NSArray<IRFilterOverlayConfiguration *> <IRFilterOverlayConfiguration> *overlayConfigurations;
@property (nonatomic, readonly) BOOL isEmpty;

- (nonnull instancetype)initWithFilterConfigurations:(nonnull NSArray<IRFilterConfiguration *> *)filterConfigurations
                               overlayConfigurations:(nonnull NSArray<IRFilterOverlayConfiguration *> *)overlayConfigurations;

@end

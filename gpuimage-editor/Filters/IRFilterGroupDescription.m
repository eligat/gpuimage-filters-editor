//
//  IRFilterGroupDescription.m
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 10/18/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import "IRFilterGroupDescription.h"

@implementation IRFilterGroupDescription 

- (nonnull instancetype)initWithFilterConfigurations:(nonnull NSArray<IRFilterConfiguration *> *)filterConfigurations
                   overlayConfigurations:(nonnull NSArray<IRFilterOverlayConfiguration *> *)overlayConfigurations {
  self = [super init];
  
  if (self) {
    _filterConfigurations = (NSArray<IRFilterConfiguration *><IRFilterConfiguration> *)filterConfigurations;
    _overlayConfigurations = (NSArray<IRFilterOverlayConfiguration *><IRFilterOverlayConfiguration> *)overlayConfigurations;
  }
  
  return self;
}

- (BOOL)isEmpty {
  return self.filterConfigurations.count == 0 && self.overlayConfigurations.count == 0;
}

@end

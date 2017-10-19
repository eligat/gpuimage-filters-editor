//
//  IRFilterOverlayConfiguration.m
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 10/18/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import "IRFilterOverlayConfiguration.h"

@implementation IRFilterOverlayConfiguration

- (nonnull instancetype)initWithName:(nonnull NSString *)name
                           className:(nonnull NSString *)className
                           imageName:(nonnull NSString *)imageName
                             opacity:(float)opacity {
  self = [super init];
  
  if (self) {
    _name = name;
    _className = name;
    _imageName = imageName;
    _opacity = opacity;
  }
  
  return self;
}

@end

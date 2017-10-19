//
//  IRFilterOverlayConfiguration.h
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 10/18/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@interface IRFilterOverlayConfiguration : JSONModel

@property (nonatomic, nonnull) NSString *name;
@property (nonatomic, nonnull) NSString *className;
@property (nonatomic, nonnull) NSString *imageName;
@property float opacity;

- (nonnull instancetype)initWithName:(nonnull NSString *)name
                   className:(nonnull NSString *)className
                   imageName:(nonnull NSString *)imageName
                     opacity:(float)opacity;
@end

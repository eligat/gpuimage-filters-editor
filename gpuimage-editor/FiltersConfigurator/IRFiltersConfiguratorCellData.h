//
//  IRFiltersConfiguratorCellData.h
//  gpuimage-editor
//
//  Created by Aleksey Mikhailov on 06/02/2017.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"
#import "IRFilterDescription.h"

@interface IRFiltersConfiguratorCellData: JSONModel

@property (nonatomic) IRFilterDescription *filterDescription;
@property (nonatomic) NSMutableArray<NSNumber *> *values;
@property bool enabled;

- (instancetype)initWithFilterDescription:(IRFilterDescription *)filterDescription;

@end

//
//  IRFiltersRepository.h
//  gpuimage-editor
//
//  Created by Aleksey Mikhailov on 06/02/2017.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IRFilterDescription;
@class GPUImageTwoInputFilter;

@interface IRFiltersRepository : NSObject

@property (readonly) NSArray<IRFilterDescription*>* filtersDescription;
@property (readonly) NSArray<IRFilterDescription*>* blendModeFilters;

@end

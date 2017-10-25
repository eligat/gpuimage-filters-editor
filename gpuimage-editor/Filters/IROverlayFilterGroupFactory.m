//
//  IROverlayFilterGroupFactory.m
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 10/18/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import "IRGPUImageOverlaysFilterGroup.h"
#import "IROverlayFilterGroupFactory.h"
#import "IRFilterGroupDescription.h"
#import "IRFilterConfiguration.h"
#import "IRFilterOverlayConfiguration.h"
#import "IRGPUImageOpacityBlendFilter.h"
#import <GPUImage/GPUImage.h>

@implementation IROverlayFilterGroupFactory

+ (nullable IRGPUImageOverlaysFilterGroup *) overlayFilterGroupWithDescription:(nonnull IRFilterGroupDescription *)description
                                                               imageDataSource:(nonnull id<IRImageDataSource>)imageDataSource {
    if (description.isEmpty) {
        return nil;
    }
    
    // Create filter group
    IRGPUImageOverlaysFilterGroup *group = [IRGPUImageOverlaysFilterGroup new];
    GPUImageOutput<GPUImageInput> * lastFilter = nil;
    
    for (IRFilterConfiguration *config in description.filterConfigurations) {
        
        // Create filter
        NSString* className = config.filterDescription.className;
        GPUImageOutput<GPUImageInput> * filter = [NSClassFromString(className) new];
        if (!filter) continue;
        
        // Set it's parameters
        for (NSUInteger j = 0; j < config.filterDescription.parametersDescription.count; j++) {
            IRFilterParameterDescription *parameterDescription = config.filterDescription.parametersDescription[j];
            
            NSString* setterName = parameterDescription.setterName;
            CGFloat value = config.values[j].floatValue;
            
            SEL setterSelector = NSSelectorFromString(setterName);
            if (!setterSelector) continue;
            
            NSMethodSignature *setterSignature = [[filter class] instanceMethodSignatureForSelector:setterSelector];
            if (!setterSignature) continue;
            
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:setterSignature];
            [invocation setTarget:filter];
            [invocation setSelector:setterSelector];
            [invocation setArgument:&value atIndex:2];
            [invocation invoke];
        }
        
        [group addFilter:filter];
        if (lastFilter) {
            [lastFilter addTarget:filter];
        } else {
            group.initialFilters = @[filter];
        }
        lastFilter = filter;
    }
    
    // Add overlay
    if (description.overlayConfigurations.count == 0) {
        [group setTerminalFilter:lastFilter];
        return group;
    }
    
    NSMutableArray *overlayPictures = [NSMutableArray new];
    for (IRFilterOverlayConfiguration *config in description.overlayConfigurations) {
        
        UIImage *overlayImage = [imageDataSource imageForName:config.imageName];
        if (!overlayImage) continue;
        
        IRGPUImageOpacityBlendFilter *blendFilter = [NSClassFromString(config.className) new];
        blendFilter.opacity = config.opacity;

        [group addFilter:blendFilter];
        if (lastFilter) {
            [lastFilter addTarget:blendFilter atTextureLocation:0];
        } else {
            group.initialFilters = @[blendFilter];
        }
        lastFilter = blendFilter;
        
        GPUImagePicture *overlayPicture = [[GPUImagePicture alloc] initWithImage:overlayImage];
        [overlayPictures addObject:overlayPicture];
        [overlayPicture addTarget:blendFilter atTextureLocation:1];
        [overlayPicture processImage];
    }
    
    [group setTerminalFilter:lastFilter];
    group.overlayPictures = overlayPictures;
    
    return group;
}

@end

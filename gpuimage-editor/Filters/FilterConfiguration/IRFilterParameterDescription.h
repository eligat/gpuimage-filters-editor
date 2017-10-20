//
//  IRFilterParameterDescription.h
//  gpuimage-editor
//
//  Created by Aleksey Mikhailov on 06/02/2017.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

@interface IRFilterParameterDescription : JSONModel

@property(nonatomic) NSString *name;
@property(nonatomic) NSString *setterName;
@property(nonatomic) NSNumber *minValue;
@property(nonatomic) NSNumber *maxValue;

+ (IRFilterParameterDescription *)descriptionWithName:(NSString *)name
                                           setterName:(NSString *)setterName
                                             minValue:(NSNumber *)minValue
                                             maxValue:(NSNumber *)maxValue;

@end

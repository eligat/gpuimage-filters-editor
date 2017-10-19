//
//  IRFilterDescription.h
//  gpuimage-editor
//
//  Created by Aleksey Mikhailov on 06/02/2017.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"
#import "IRFilterParameterDescription.h"

@protocol IRFilterParameterDescription;

@interface IRFilterDescription : JSONModel

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *className;
@property (nonatomic) NSArray<IRFilterParameterDescription *> <IRFilterParameterDescription> *parametersDescription;

+ (IRFilterDescription *) descriptionWithName:(NSString *)name
                                    className:(NSString *)className
                        parametersDescription:(NSArray<IRFilterParameterDescription*>*)parametersDescription;

@end

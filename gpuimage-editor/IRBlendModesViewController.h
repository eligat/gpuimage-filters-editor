//
//  IRBlendModesViewController.h
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 8/3/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IRFilterDescription, IRBlendModesViewController;

@protocol IRBlendModesViewControllerDelegate <NSObject>

- (void)blendModesViewController:(IRBlendModesViewController *)controller selectedBlendModeFilter:(IRFilterDescription *)filter;

@end

@interface IRBlendModesViewController : UIViewController

@property(nonatomic, weak) id<IRBlendModesViewControllerDelegate> delegate;

@end

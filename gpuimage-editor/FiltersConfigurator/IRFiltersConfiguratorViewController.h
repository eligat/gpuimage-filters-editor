//
//  IRFiltersConfiguratorViewController.h
//  gpuimage-editor
//
//  Created by Aleksey Mikhailov on 06/02/2017.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IRPreviewViewController, IRFilterConfiguration;

@interface IRFiltersConfiguratorViewController : UITableViewController

@property(strong, nonatomic) IRPreviewViewController *previewViewController;

- (void)setFiltersConfiguration:(NSArray<IRFilterConfiguration *> *)configuration;

@end

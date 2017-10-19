//
//  IRFiltersConfiguratorViewController.m
//  gpuimage-editor
//
//  Created by Aleksey Mikhailov on 06/02/2017.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import "IRFiltersConfiguratorViewController.h"
#import "IRFiltersRepository.h"
#import "IRFiltersConfiguratorTableViewCell.h"
#import "IRFilterConfiguration.h"
#import "IRFilterDescription.h"
#import "IRPreviewViewController.h"
#import "IRFilterParameterDescription.h"
#import <GPUImage/GPUImage.h>

@interface IRFiltersConfiguratorViewController () <IRFiltersConfiguratorTableViewCellDelegate>

@property(nonatomic) NSMutableArray<IRFilterConfiguration *> *tableData;

@end

@implementation IRFiltersConfiguratorViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  IRFiltersRepository *filtersRepository = [IRFiltersRepository new];
  self.tableData = [NSMutableArray arrayWithCapacity:filtersRepository.filtersDescription.count];

  for (NSUInteger i = 0; i < filtersRepository.filtersDescription.count; i++) {
    IRFilterDescription *filterDescription = filtersRepository.filtersDescription[i];
    self.tableData[i] = [[IRFilterConfiguration alloc] initWithFilterDescription:filterDescription];
  }

  self.tableView.estimatedRowHeight = 44.0;
  self.tableView.rowHeight = UITableViewAutomaticDimension;
  self.tableView.allowsMultipleSelectionDuringEditing = true;

  [self.tableView setEditing:true];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  IRFiltersConfiguratorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FilterDescriptionCell"
                                                                             forIndexPath:indexPath];

  IRFilterConfiguration *data = self.tableData[indexPath.row];

  [cell fill:data];
  [cell setDelegate:self];

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.tableData[indexPath.row].enabled = true;

  [self updateConfiguration];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.tableData[indexPath.row].enabled = false;

  [self updateConfiguration];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
  IRFilterConfiguration *data = self.tableData[sourceIndexPath.row];
  [self.tableData removeObjectAtIndex:sourceIndexPath.row];
  [self.tableData insertObject:data atIndex:destinationIndexPath.row];

  [self updateConfiguration];
}

#pragma mark - IRFiltersConfiguratorTableViewCellDelegate

- (void)filtersConfiguratorTableViewCell:(IRFiltersConfiguratorTableViewCell *)cell
                          didChangeValue:(float)value
                    atParameterWithIndex:(NSUInteger)index {
  NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

  if (indexPath == nil) {
    return;
  }

  self.tableData[indexPath.row].values[index] = @(value);

  [self updateConfiguration];
}

#pragma mark - Public

- (void)updateConfiguration {
  NSMutableArray<IRFilterConfiguration *> *enabledFilters = [NSMutableArray new];
  for (IRFilterConfiguration *configuration in self.tableData) {
    if (configuration.enabled) {
      [enabledFilters addObject:configuration];
    }
  }
  
  UIViewController *viewController = [(UINavigationController *) [self.splitViewController.viewControllers lastObject] topViewController];
  if ([viewController isKindOfClass:[IRPreviewViewController class]]) {
    IRPreviewViewController *previewViewController = (IRPreviewViewController *) viewController;
    [previewViewController updatePreviewWithFilterConfigurations:enabledFilters];
  }
}

@end

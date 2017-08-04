//
//  IRBlendModesViewController.m
//  gpuimage-editor
//
//  Created by Oleg Sannikov on 8/3/17.
//  Copyright © 2017 IceRock Development. All rights reserved.
//


#import "IRBlendModesViewController.h"
#import "IRFilterDescription.h"
#import "IRFiltersRepository.h"

@interface IRBlendModesViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, weak) IBOutlet UITableView *tableView;
@property(nonatomic) IRFiltersRepository *filtersRepository;

@end

@implementation IRBlendModesViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.filtersRepository = [IRFiltersRepository new];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.filtersRepository.blendModeFilters.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell" forIndexPath:indexPath];
  IRFilterDescription *filter = self.filtersRepository.blendModeFilters[indexPath.row];
  cell.textLabel.text = filter.name;
  return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.delegate &&
      [self.delegate respondsToSelector:@selector(blendModesViewController:selectedBlendModeFilter:)]) {
    
    IRFilterDescription *filter = self.filtersRepository.blendModeFilters[indexPath.row];
    [self.delegate blendModesViewController:self selectedBlendModeFilter:filter];
  }
}


@end

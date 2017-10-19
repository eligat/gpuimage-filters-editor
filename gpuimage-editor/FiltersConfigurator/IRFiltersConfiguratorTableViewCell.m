//
//  IRFiltersConfiguratorTableViewCell.m
//  gpuimage-editor
//
//  Created by Aleksey Mikhailov on 06/02/2017.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import "IRFiltersConfiguratorTableViewCell.h"
#import "IRFilterDescription.h"
#import "IRFilterParameterDescription.h"
#import "IRFilterConfiguration.h"

@interface IRFiltersConfiguratorTableViewCell()

@property (nonatomic, weak) IBOutlet UILabel* nameLabel;
@property (nonatomic, weak) IBOutlet UIStackView* parametersStackView;
@property (nonatomic, weak) UISlider* slider;

@property (nonatomic) NSTimer* timer;

@end

@implementation IRFiltersConfiguratorTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)fill:(IRFilterConfiguration*)cellData {
  self.nameLabel.text = cellData.filterDescription.name;

  for(NSInteger i = self.parametersStackView.subviews.count - 1;i >= 0;i--) {
    [self.parametersStackView.subviews[i] removeFromSuperview];
  }

  for(NSInteger i = 0;i < cellData.filterDescription.parametersDescription.count;i++) {
    IRFilterParameterDescription *parameterDescription = cellData.filterDescription.parametersDescription[i];

    UILabel *label = [UILabel new];
    label.text = parameterDescription.name;
    [self.parametersStackView addArrangedSubview:label];

    UISlider *slider = [UISlider new];
    slider.minimumValue = [parameterDescription.minValue floatValue];
    slider.maximumValue = [parameterDescription.maxValue floatValue];
    slider.value = cellData.values[i].floatValue;
    slider.tag = i;
    [slider addTarget:self
               action:@selector(sliderShouldChange:)
     forControlEvents:UIControlEventValueChanged];
    [self.parametersStackView addArrangedSubview:slider];
    self.slider = slider;
  }

  self.selected = cellData.enabled;
}

- (void)sliderShouldChange:(UISlider*)slider {
  [self.timer invalidate];
  self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                target:self
                                              selector:@selector(sliderValueChanged:)
                                              userInfo:slider
                                               repeats:false];
}

- (void)sliderValueChanged:(NSTimer*)timer {
  if([self.delegate respondsToSelector:@selector(filtersConfiguratorTableViewCell:didChangeValue:atParameterWithIndex:)]) {
    UISlider *slider = timer.userInfo;
    [self.delegate filtersConfiguratorTableViewCell:self
                                     didChangeValue:slider.value
                               atParameterWithIndex:(NSUInteger)slider.tag];
  }
}

@end

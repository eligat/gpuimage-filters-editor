//
//  IRPreviewViewController.m
//  gpuimage-editor
//
//  Created by Aleksey Mikhailov on 06/02/2017.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import "IRPreviewViewController.h"
#import "IRFiltersConfiguratorViewController.h"
#import "IRBlendModesViewController.h"
#import "IRFiltersRepository.h"
#import "IRFilterGroupDescription.h"
#import "IRGPUImageOpacityBlendFilter.h"
#import "IRGPUImageOverlaysFilterGroup.h"
#import "IROverlayFilterGroupFactory.h"
#import <GPUImage/GPUImage.h>
#import <JSONModel/JSONModel.h>

NSString * const toBlendModesSegueID = @"toBlendModesViewControllerSegueID";
NSString * const overlayImageName = @"*overlay*";

@interface IRPreviewViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, IRBlendModesViewControllerDelegate, IRImageDataSource>

@property(nonatomic, weak) IBOutlet UIImageView *sourceImageView;
@property(nonatomic, weak) IBOutlet UIImageView *resultImageView;
@property(nonatomic, weak) IBOutlet UITextView *configurationTextView;
@property(nonatomic, weak) IBOutlet UISlider *overlayOpacitySlider;
@property(nonatomic, weak) IBOutlet UILabel *overlayOpacitySliderValueLabel;
@property(nonatomic, weak) IBOutlet UIButton *blendModeButton;

@property(nonatomic) BOOL selectingOverlay;
@property(nonatomic) UIImage *overlayImage;
@property(nonatomic) NSTimer *overlaySliderTimer;

@property(nonatomic) IRFiltersRepository *filtersRepository;
@property(nonatomic, nonnull) IRFilterDescription *blendModeFilter;

@property(nonatomic) NSArray<IRFilterConfiguration *> *filterConfigurations;
@property(nonatomic) IRFilterGroupDescription *filterGroupDescription;
@property(nonatomic) IRGPUImageOverlaysFilterGroup *filterGroup;

@property(nonatomic) dispatch_queue_t processingQueue;
@property(nonatomic) CFTimeInterval lastProcessingTime;

@end

@implementation IRPreviewViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
  [super viewDidLoad];

  self.filtersRepository = [IRFiltersRepository new];
  self.blendModeFilter = self.filtersRepository.blendModeFilters.firstObject;
  
  [self updatePreview];
  [self updateBlendModeButton];
}

#pragma mark - Actions
- (IBAction)pressedImportButton:(UIBarButtonItem *)sender {
  // The \n is required so that the alertcontroller keeps space for the message. Add as many \n as you like your textview height to be
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Import filter configuration here"
                                                             message:@"\n\n\n\n\n\n\n\n\n\n\n\n"
                                                      preferredStyle:UIAlertControllerStyleAlert];
  
  alertController.view.autoresizesSubviews = YES;
  UITextView *textView = [[UITextView alloc] initWithFrame:CGRectZero];
  textView.translatesAutoresizingMaskIntoConstraints = NO;
  textView.editable = YES;
  textView.dataDetectorTypes = UIDataDetectorTypeAll;
  textView.text = @"";
  textView.userInteractionEnabled = YES;
  textView.backgroundColor = [UIColor whiteColor];
  // This will make the scroll view scrollable if the text is too long
  textView.scrollEnabled = YES;
  [alertController.view addSubview:textView];
  
  NSLayoutConstraint *leadConstraint = [NSLayoutConstraint constraintWithItem:alertController.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:textView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:-8.0];
  NSLayoutConstraint *trailConstraint = [NSLayoutConstraint constraintWithItem:alertController.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:textView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:8.0];
  NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:alertController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:textView attribute:NSLayoutAttributeTop multiplier:1.0 constant:-80.0];
  NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:alertController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:textView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:64.0];
  [NSLayoutConstraint activateConstraints:@[leadConstraint, trailConstraint, topConstraint, bottomConstraint]];
  
  [alertController addAction: [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alertController addAction: [UIAlertAction actionWithTitle:@"Import" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [alertController dismissViewControllerAnimated:YES completion:nil];
    
    NSError *error = nil;
    IRFilterGroupDescription *filter = [[IRFilterGroupDescription alloc] initWithString:textView.text error:&error];
    
    if (error) {
      UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:@"Error occured at import"
                                          message:error.localizedDescription
                                   preferredStyle:UIAlertControllerStyleAlert];
      [alertController addAction: [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
      [self presentViewController:alertController animated:YES completion:nil];
      return;
    }
    
    [self updateWithFilterGroup:filter];
    
  }]];
  
  [self presentViewController:alertController animated:true completion:nil];
}

- (IBAction)pressedShareButton:(UIBarButtonItem *)sender {
  UIActivityViewController *activityViewController =
      [[UIActivityViewController alloc] initWithActivityItems:@[self.configurationTextView.text]
                                        applicationActivities:nil];

  activityViewController.modalPresentationStyle = UIModalPresentationPopover;
  activityViewController.popoverPresentationController.barButtonItem = sender;

  [self presentViewController:activityViewController
                     animated:true
                   completion:nil];
}

- (IBAction)pressedCapturePhotoButton:(UIBarButtonItem *)sender {
  UIImagePickerController *imagePickerController = [self createImagePickerForBarButton: sender];

  self.selectingOverlay = NO;
  [self presentViewController:imagePickerController
                     animated:true
                   completion:nil];
}

- (IBAction)pressedOverlayButton:(UIBarButtonItem *)sender {
  UIImagePickerController *imagePickerController = [self createImagePickerForBarButton: sender];
  
  self.selectingOverlay = YES;
  [self presentViewController:imagePickerController
                     animated:true
                   completion:nil];
}

- (IBAction)overlaySliderShouldChange:(UISlider *)sender {
  self.overlayOpacitySliderValueLabel.text = [NSString stringWithFormat:@"%.2f", sender.value];
  [self.overlaySliderTimer invalidate];
  self.overlaySliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                             target:self
                                                           selector:@selector(overlaySliderValueChanged)
                                                           userInfo:nil
                                                            repeats:false];
}

- (IBAction)overlaySliderValueChanged {
  [self updatePreview];
}

- (IBAction)deleteOverlayButtonPressed:(UIButton *)sender {
  self.overlayImage = nil;
  [self updatePreview];
}

#pragma mark - Public
- (void) updatePreviewWithFilterConfigurations:(NSArray<IRFilterConfiguration *> *)configurations {
  self.filterConfigurations = configurations;
  [self updatePreview];
}

#pragma mark - Private
- (UIImagePickerController *)createImagePickerForBarButton:(UIBarButtonItem *)button {
  UIImagePickerController *controller = [[UIImagePickerController alloc] init];
  
  controller.delegate = self;
  controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  controller.allowsEditing = false;
  controller.modalPresentationStyle = UIModalPresentationPopover;
  controller.popoverPresentationController.barButtonItem = button;
  
  return controller;
}

- (void) updateWithFilterGroup:(IRFilterGroupDescription *)group {
  
  // Import overlay
  IRFilterOverlayConfiguration *overlayConfig = group.overlayConfigurations.firstObject;
  
  if (overlayConfig) {
    NSUInteger index = [self.filtersRepository.blendModeFilters indexOfObjectPassingTest:^BOOL(IRFilterDescription * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      if ([obj.className isEqualToString:overlayConfig.className]) {
        *stop = YES;
        return YES;
      }
      
      return NO;
    }];
    if (index != NSNotFound) {
      IRFilterDescription *blendFilterDescription = self.filtersRepository.blendModeFilters[index];
      self.blendModeFilter = blendFilterDescription;
      self.overlayOpacitySlider.value = overlayConfig.opacity;
      self.overlayOpacitySliderValueLabel.text = [NSString stringWithFormat:@"%.2f", overlayConfig.opacity];
      [self updateBlendModeButton];
    }
  } else {
    self.blendModeFilter = self.filtersRepository.blendModeFilters.firstObject;
    self.overlayImage = nil;
  }
  
  //Import filter config
  self.filterGroupDescription = group;
  self.filterConfigurations = group.filterConfigurations;
  UIViewController *viewController = [(UINavigationController *) [self.splitViewController.viewControllers firstObject] topViewController];
  if ([viewController isKindOfClass:[IRFiltersConfiguratorViewController class]]) {
    IRFiltersConfiguratorViewController *configuratorViewController = (IRFiltersConfiguratorViewController *) viewController;
    [configuratorViewController setFiltersConfiguration:group.filterConfigurations];
  }
  
  [self updatePreview];
}

- (void) updateFilterGroup {
  IRFilterOverlayConfiguration *overlayConfig =
  [[IRFilterOverlayConfiguration alloc] initWithName:self.blendModeFilter.name
                                           className:self.blendModeFilter.className
                                           imageName:overlayImageName
                                             opacity:self.overlayOpacitySlider.value];
  
  IRFilterGroupDescription *description =
  [[IRFilterGroupDescription alloc] initWithFilterConfigurations:self.filterConfigurations
                                           overlayConfigurations:@[overlayConfig]];
  
  self.filterGroupDescription = description;
  self.filterGroup = [IROverlayFilterGroupFactory overlayFilterGroupWithDescription:description imageDataSource:self];
}

- (void)updateTextView {
  NSDictionary *description = self.filterGroupDescription.toDictionary;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:description options:NSJSONWritingPrettyPrinted error:nil];
  NSString *prettyJsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  
  self.configurationTextView.text = prettyJsonString;
}

- (void)updatePreview {
  [self updateFilterGroup];
  [self updateTextView];
  
  UIImage *image = self.sourceImageView.image;
  if (image == nil) {
    self.resultImageView.image = nil;
    return;
  }
  
  if (self.filterGroup.filterCount == 0) {
    self.resultImageView.image = image;
    return;
  }
  
  if (!self.processingQueue) {
    self.processingQueue = dispatch_queue_create("processingQueue", 0);
  }
  
  __weak typeof(self) weakself = self;
  dispatch_async(self.processingQueue, ^{
    if (!weakself) {
      return;
    }

    double t1 = CACurrentMediaTime();
    
    UIImage *currentFilteredFrame = [weakself.filterGroup imageByFilteringImage:image];
    
    double t2 = CACurrentMediaTime();
    weakself.lastProcessingTime = t2 - t1;

    dispatch_async(dispatch_get_main_queue(), ^{
      weakself.resultImageView.image = currentFilteredFrame;
      [weakself updateTextView];
    });
  });
}

- (void)updateBlendModeButton {
  [self.blendModeButton setTitle:self.blendModeFilter.name forState:UIControlStateNormal];
}

#pragma mark - UIViewController
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:toBlendModesSegueID] &&
      [segue.destinationViewController isKindOfClass: [IRBlendModesViewController class]]) {
    
    IRBlendModesViewController *controller = segue.destinationViewController;
    controller.delegate = self;
  }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
  
  UIImage *image = info[UIImagePickerControllerOriginalImage];
  
  if (self.selectingOverlay) {
    self.overlayImage = image;
  } else {
    self.sourceImageView.image = image;
  }
  
  [self dismissViewControllerAnimated:true
                           completion:^{
                             [self updatePreview];
                           }];
}

#pragma mark - IRBlendModesViewControllerDelegate
- (void)blendModesViewController:(IRBlendModesViewController *)controller
         selectedBlendModeFilter:(IRFilterDescription *)filter {
  self.blendModeFilter = filter;
  [controller dismissViewControllerAnimated:true completion:nil];
  [self updateBlendModeButton];
  [self updatePreview];
}

#pragma mark - IRImageDataSource
- (UIImage *)imageForName:(NSString *)name {
  return self.overlayImage;
}

@end

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
#import "IRFilterDescription.h"
#import "IRGPUImageOpacityBlendFilter.h"
#import <GPUImage/GPUImage.h>

NSString * const toBlendModesSegueID = @"toBlendModesViewControllerSegueID";

@interface IRPreviewViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, IRBlendModesViewControllerDelegate>

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

@property(nonatomic) dispatch_queue_t processingQueue;
@property(nonatomic) CFTimeInterval lastProcessingTime;

@end

@implementation IRPreviewViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
  [super viewDidLoad];

  self.filtersRepository = [IRFiltersRepository new];
  self.blendModeFilter = self.filtersRepository.blendModeFilters.firstObject;
  
  [self configureView];
  [self updateBlendModeButton];
}

#pragma mark - Actions
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
  [self updateFilters];
}

- (IBAction)deleteOverlayButtonPressed:(UIButton *)sender {
  self.overlayImage = nil;
  [self updateFilters];
}

- (void)updateFilters {
  // We need to regenerate filters every time we reprocess the output image
  // because of GPUImage bug with multiple input filters: https://github.com/BradLarson/GPUImage/issues/1522
  UIViewController *viewController = [(UINavigationController *) [self.splitViewController.viewControllers firstObject] topViewController];
  if ([viewController isKindOfClass:[IRFiltersConfiguratorViewController class]]) {
    IRFiltersConfiguratorViewController *configuratorViewController = (IRFiltersConfiguratorViewController *) viewController;
    [configuratorViewController updateConfiguration];
  }
}


#pragma mark - Public
- (void)setFilters:(NSArray<GPUImageFilter *> *)filters withCode:(NSString *)code {
  _filters = filters;
  _filtersCode = code;

  [self updateOverlayFilterCode];
  [self configureView];
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

- (void)updateOverlayFilterCode {
  NSMutableString *code = [NSMutableString new];
  if (self.filters.count > 0) {
    unsigned long lastFilterIndex = self.filters.count - 1;
    NSString *lastFilterName = [NSString stringWithFormat:@"filter%lu",(unsigned long)lastFilterIndex];
    
    if (self.overlayImage) {
      [code appendString:[NSString stringWithFormat:@"IRGPUImageOpacityBlendFilter *blendFilter = [%@ new];\n",
                          NSClassFromString(self.blendModeFilter.className)]];
      [code appendString:[NSString stringWithFormat:@"blendFilter.opacity = %f;\n", self.overlayOpacitySlider.value]];
      [code appendString:@"GPUImagePicture *overlayPicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@\"<#(image name)#>\"]];\n"];
      [code appendString:[NSString stringWithFormat:@"[filter%lu addTarget:blendFilter];\n",
                          (unsigned long)lastFilterIndex]];
      [code appendString:@"[overlayPicture addTarget:blendFilter];\n"];
      [code appendString:@"[overlayPicture processImage];\n"];
      [code appendString:@"[group addFilter:blendFilter];\n"];
      [code appendString:@"\n"];
      lastFilterName = @"blendFilter";
    }
    
    [code appendString:@"[group setInitialFilters:@[filter0]];\n"];
    [code appendString:[NSString stringWithFormat:@"[group setTerminalFilter:%@];\n", lastFilterName]];
    [code appendString:@"return group;"];
  }
  _overlayFilterCode = code;
}

- (void)updateTextView {
  self.configurationTextView.text = [NSString stringWithFormat:@"// render time %f\n%@\n%@", self.lastProcessingTime, self.filtersCode, self.overlayFilterCode];
}

- (void)configureView {
  UIImage *image = self.sourceImageView.image;
  if (image == nil) {
    self.resultImageView.image = nil;
    self.configurationTextView.text = nil;
    return;
  }
  UIImage *overlayImage = self.overlayImage;
  
  if (!self.processingQueue) {
    self.processingQueue = dispatch_queue_create("processingQueue", 0);
  }
  
  __weak typeof(self) weakself = self;
  dispatch_async(self.processingQueue, ^{
    if (!weakself) {
      return;
    }
    
    double t1 = CACurrentMediaTime();
    
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageOutput *output = picture;
    
    for (NSUInteger i = 0; i < weakself.filters.count; i++) {
      GPUImageFilter *filter = weakself.filters[i];
      [output addTarget:filter];
      output = filter;
    }
    
    GPUImagePicture *overlayPicture = nil;
    if (overlayImage) {
      IRGPUImageOpacityBlendFilter *blendFilter = [NSClassFromString(weakself.blendModeFilter.className) new];
      blendFilter.opacity = weakself.overlayOpacitySlider.value;
      
      overlayPicture = [[GPUImagePicture alloc] initWithImage:overlayImage];
      
      [output addTarget:blendFilter];
      [overlayPicture addTarget:blendFilter];
      
      output = blendFilter;
      
      [overlayPicture processImage];
    }
    
    [output useNextFrameForImageCapture];
    [picture processImage];
    
    UIImage *currentFilteredFrame = [output imageFromCurrentFramebufferWithOrientation:image.imageOrientation];
    
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
                             [self updateFilters];
                           }];
}

#pragma mark - IRBlendModesViewControllerDelegate
- (void)blendModesViewController:(IRBlendModesViewController *)controller
         selectedBlendModeFilter:(IRFilterDescription *)filter {
  self.blendModeFilter = filter;
  [controller dismissViewControllerAnimated:true completion:nil];
  [self updateBlendModeButton];
  [self updateFilters];
}


@end

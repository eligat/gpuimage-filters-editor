//
//  IRPreviewViewController.m
//  gpuimage-editor
//
//  Created by Aleksey Mikhailov on 06/02/2017.
//  Copyright © 2017 IceRock Development. All rights reserved.
//

#import "IRPreviewViewController.h"
#import <GPUImage/GPUImage.h>

@interface IRPreviewViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(nonatomic, weak) IBOutlet UIImageView *sourceImageView;
@property(nonatomic, weak) IBOutlet UIImageView *resultImageView;
@property(nonatomic, weak) IBOutlet UITextView *configurationTextView;
@property(nonatomic, weak) IBOutlet UISlider *overlayOpacitySlider;
@property(nonatomic, weak) IBOutlet UILabel *overlayOpacitySliderValueLabel;

@property(nonatomic) BOOL selectingOverlay;
@property(nonatomic) UIImage *overlayImage;
@property(nonatomic) NSTimer *overlaySliderTimer;

@property(nonatomic) dispatch_queue_t processingQueue;
@property(nonatomic) CFTimeInterval lastProcessingTime;

@end

@implementation IRPreviewViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
  [super viewDidLoad];

  [self configureView];
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
  [self updateOverlayFilterCode];
  [self configureView];
}

- (IBAction)deleteOverlayButtonPressed:(UIButton *)sender {
  self.overlayImage = nil;
  [self updateOverlayFilterCode];
  [self configureView];
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
      [code appendString:@"GPUImageAlphaBlendFilter *blendFilter = [GPUImageAlphaBlendFilter new];\n"];
      [code appendString:[NSString stringWithFormat:@"[blendFilter setMix:%f];\n", 1 - self.overlayOpacitySlider.value]];
      [code appendString:@"GPUImagePicture *overlayPicture = [[GPUImagePicture alloc] initWithImage:<#(image name)#>];\n"];
      [code appendString:@"[overlayPicture addTarget:blendFilter];\n"];
      [code appendString:[NSString stringWithFormat:@"[filter%lu addTarget:blendFilter];\n",
                          (unsigned long)lastFilterIndex]];
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
  
  if (!self.processingQueue) {
    self.processingQueue = dispatch_queue_create("processingQueue", 0);
  }
  
  __weak typeof(self) weakself = self;
  dispatch_async(self.processingQueue, ^{
    if (!weakself) {
      return;
    }
    
    double t1 = CACurrentMediaTime();
    
    GPUImagePicture *mainPicture = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageOutput *mainOutput = mainPicture;
    
    for (NSUInteger i = 0; i < weakself.filters.count; i++) {
      GPUImageFilter *filter = weakself.filters[i];
      [mainOutput addTarget:filter];
      mainOutput = filter;
    }
    
    GPUImagePicture *overlayPicture = nil;
    if (weakself.overlayImage) {
      GPUImageAlphaBlendFilter *blendFilter = [GPUImageAlphaBlendFilter new];
      [blendFilter setMix:1 - weakself.overlayOpacitySlider.value];
      
      overlayPicture = [[GPUImagePicture alloc] initWithImage:weakself.overlayImage];
      [overlayPicture addTarget:blendFilter];
      
      [mainOutput addTarget:blendFilter];
      mainOutput = blendFilter;
      
      [overlayPicture processImage];
    }
    
    [mainOutput useNextFrameForImageCapture];
    [mainPicture processImage];
    
    UIImage *currentFilteredFrame = [mainOutput imageFromCurrentFramebufferWithOrientation:image.imageOrientation];
    
    double t2 = CACurrentMediaTime();
    weakself.lastProcessingTime = t2 - t1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      weakself.resultImageView.image = currentFilteredFrame;
      [weakself updateTextView];
    });
  });
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
                             [self configureView];
                           }];
}

@end

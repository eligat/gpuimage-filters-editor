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

@property(nonatomic) BOOL selectingOverlay;
@property(nonatomic) UIImage *overlayImage;

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

#pragma mark - Public
- (void)setFilters:(NSArray<GPUImageFilter *> *)filters withCode:(NSString *)code {
  _filters = filters;
  _filtersCode = code;

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

- (void)configureView {
  UIImage *image = self.sourceImageView.image;
  if (image == nil) {
    self.resultImageView.image = nil;
    self.configurationTextView.text = nil;
    return;
  }

  double t1 = CACurrentMediaTime();
  
  GPUImagePicture *mainPicture = [[GPUImagePicture alloc] initWithImage:image];
  GPUImageOutput *mainOutput = mainPicture;
  
  for (NSUInteger i = 0; i < self.filters.count; i++) {
    GPUImageFilter *filter = self.filters[i];
    [mainOutput addTarget:filter];
    mainOutput = filter;
  }
  
  GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
  [blendFilter setMix:0.5];
  
  GPUImagePicture *overlayPicture = nil;
  if (self.overlayImage) {
    overlayPicture = [[GPUImagePicture alloc] initWithImage:self.overlayImage];
    [overlayPicture addTarget:blendFilter];
  }
  
  [mainOutput addTarget:blendFilter];
  
  [blendFilter useNextFrameForImageCapture];
  [mainPicture processImage];
  [overlayPicture processImage];
  
  UIImage *currentFilteredFrame = [blendFilter imageFromCurrentFramebufferWithOrientation:image.imageOrientation];
  
  double t2 = CACurrentMediaTime();
  
  self.resultImageView.image = currentFilteredFrame;
  self.configurationTextView.text = [NSString stringWithFormat:@"// render time %f\n%@", (t2 - t1), self.filtersCode];
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

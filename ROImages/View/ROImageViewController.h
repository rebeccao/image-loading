//
//  ROImageViewController.h
//  ROImages
//
//  Created by Rebecca ODell on 12/16/13.
//  Copyright (c) 2013 Rebecca ODell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ROImageViewController : UIViewController 

@property (nonatomic, strong) NSString *itemNumber;
@property (nonatomic, strong) NSString *itemFilename;
@property (nonatomic, strong) UIImage *itemImage;

@property (nonatomic, weak) IBOutlet UIImageView *detailImage;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressViewLabel;

- (IBAction)uploadButton:(id)sender;

@end

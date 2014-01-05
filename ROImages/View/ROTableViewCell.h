//
//  ROTableViewCell.h
//  ROImages
//
//  Created by Rebecca ODell on 12/16/13.
//  Copyright (c) 2013 Rebecca ODell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ROTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *cellTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *cellURLLabel;
@property (nonatomic, weak) IBOutlet UIImageView *cellImage;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@end

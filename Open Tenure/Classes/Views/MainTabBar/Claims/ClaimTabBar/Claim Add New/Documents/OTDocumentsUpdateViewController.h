//
//  OTDocumentsUpdateViewController.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/9/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTAbstractListViewController.h"

@interface OTDocumentsUpdateViewController : OTAbstractListViewController

@property (strong, nonatomic) Claim *claim;

- (IBAction)takePhotoDoc:(id)sender;
- (IBAction)attachDoc:(id)sender;

@end

//
//  OTAdditionalUpdateViewController.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/9/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTAbstractListViewController.h"

@interface OTAdditionalUpdateViewController : OTAbstractListViewController

@property (strong, nonatomic) Claim *claim;

- (IBAction)addAdditionalInfo:(id)sender;

@end

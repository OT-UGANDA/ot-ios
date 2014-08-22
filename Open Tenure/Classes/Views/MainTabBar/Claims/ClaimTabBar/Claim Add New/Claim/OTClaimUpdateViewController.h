//
//  OTClaimUpdateViewController.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/9/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTFormViewController.h"

@interface OTClaimUpdateViewController : OTFormViewController

@property (strong, nonatomic) Claim *claim;

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end

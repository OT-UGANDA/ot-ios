//
//  OTPersonsViewController.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 7/16/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTAbstractListViewController.h"

@class OTPersonsViewController;

@protocol OTPersonsViewControllerDelegate <NSObject>

@optional

- (void)personSelection:(OTPersonsViewController *)controller didSelectPerson:(Person *)person;

@end

@interface OTPersonsViewController : OTAbstractListViewController

@property (weak, nonatomic) id <OTPersonsViewControllerDelegate> delegate;

- (IBAction)addPerson:(id)sender;
- (IBAction)showMenu:(id)sender;
- (IBAction)cancel:(id)sender;

@end

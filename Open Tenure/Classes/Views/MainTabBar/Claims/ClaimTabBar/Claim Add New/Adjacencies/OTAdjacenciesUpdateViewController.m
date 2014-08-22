//
//  OTAdjacenciesUpdateViewController.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/9/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "OTAdjacenciesUpdateViewController.h"
#import "OTFormInputTextFieldCell.h"
#import "OTFormFloatInputTextFieldCell.h"

@interface OTAdjacenciesUpdateViewController ()

@property (assign) OTViewType viewType;

@end

@implementation OTAdjacenciesUpdateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.viewType = _claim.getViewType;
    
    self.formCells = [self createAdjacencies];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)createAdjacencies {
    
    NSInteger customCellHeight = 40.0f;
    Class inputTextFieldClass = [OTFormFloatInputTextFieldCell class];
    
    [self setHeaderTitle:NSLocalizedString(@"title_claim_adjacencies", nil) forSection:0];
    
    OTFormInputTextFieldCell *northAdjacency =
    [[inputTextFieldClass alloc] initWithText:_claim.northAdjacency
                                  placeholder:NSLocalizedString(@"north_adjacency", nil)
                                     delegate:self
                                    mandatory:NO
                             customCellHeight:customCellHeight
                                 keyboardType:UIKeyboardTypeDefault
                                     viewType:_viewType];
    northAdjacency.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        _claim.northAdjacency = inText;
    };

    OTFormInputTextFieldCell *shouthAdjacency =
    [[inputTextFieldClass alloc] initWithText:_claim.shouthAdjacency
                                  placeholder:NSLocalizedString(@"south_adjacency", nil)
                                     delegate:self
                                    mandatory:NO
                             customCellHeight:customCellHeight
                                 keyboardType:UIKeyboardTypeDefault
                                     viewType:_viewType];
    shouthAdjacency.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        _claim.shouthAdjacency = inText;
    };

    OTFormInputTextFieldCell *eastAdjacency =
    [[inputTextFieldClass alloc] initWithText:_claim.eastAdjacency
                                  placeholder:NSLocalizedString(@"east_adjacency", nil)
                                     delegate:self
                                    mandatory:NO
                             customCellHeight:customCellHeight
                                 keyboardType:UIKeyboardTypeDefault
                                     viewType:_viewType];
    eastAdjacency.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        _claim.eastAdjacency = inText;
    };

    OTFormInputTextFieldCell *westAdjacency =
    [[inputTextFieldClass alloc] initWithText:_claim.westAdjacency
                                  placeholder:NSLocalizedString(@"west_adjacency", nil)
                                     delegate:self
                                    mandatory:NO
                             customCellHeight:customCellHeight
                                 keyboardType:UIKeyboardTypeDefault
                                     viewType:_viewType];
    westAdjacency.didEndEditingBlock = ^void(BPFormInputCell *inCell, NSString *inText) {
        _claim.westAdjacency = inText;
    };
    
    [self setHeaderTitle:NSLocalizedString(@"adjacent_claims", nil) forSection:1];
    return @[@[northAdjacency, shouthAdjacency, eastAdjacency, westAdjacency], @[]];
}

@end

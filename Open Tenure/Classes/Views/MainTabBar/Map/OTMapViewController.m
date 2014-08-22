/**
 * ******************************************************************************************
 * Copyright (C) 2014 - Food and Agriculture Organization of the United Nations (FAO).
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice,this list
 *       of conditions and the following disclaimer.
 *    2. Redistributions in binary form must reproduce the above copyright notice,this list
 *       of conditions and the following disclaimer in the documentation and/or other
 *       materials provided with the distribution.
 *    3. Neither the name of FAO nor the names of its contributors may be used to endorse or
 *       promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,STRICT LIABILITY,OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * *********************************************************************************************
 */

#import "OTMapViewController.h"
#import "ShapeKit.h"
#import "TBCoordinateQuadTree.h"
#import "TBClusterAnnotationView.h"

#import "ParseOperation.h"

@interface OTMapViewController ()

// Quad tree coordinate for handle cluster annotations
@property (strong, nonatomic) TBCoordinateQuadTree *coordinateQuadTree;

// Managing annotations on the mapView
@property (nonatomic) NSMutableArray *annotations;

// Managing claims. TODO: using core data
@property (nonatomic) NSMutableArray *claims;

// Progress handle
@property (nonatomic, assign) NSInteger totalItemsToDownload;
@property (nonatomic, assign) NSInteger totalItemsDownloaded;

@property (assign) OTViewType viewType;

// Dữ liệu tọa độ dùng hiển thị polygon (new & edit)
// Quản lý các annotations tại các đỉnh của polygon, không bị xóa bỏ cũng không tham gia tạo cluster
@property (nonatomic) NSMutableArray *polygonAnnotations;
@property (nonatomic) MKPolygon *polygonOverlay;

@property (nonatomic) NSOperationQueue *parseQueue;

@end

@implementation OTMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
      return nil;
    
}

- (void)viewDidLoad
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureOperation {
    
}

- (void)configureNotifications {
   }

/*!
 Quản lý thao tác nhấn giữ trên map
 */
- (void)configureGestures {
  
}

#pragma handler touch on the map

- (IBAction)handleLongPress:(id)sender {
  }

- (void)updatePolygonAnnotations:(MKPointAnnotation *)pointAnnotation remove:(BOOL)remove {
  
}

- (void)renderAnnotations{
    
   }


#pragma Bar Buttons Action

/*!
 Download all new claims by current map rect.
 @result
 Send broadcasting information
 */
- (IBAction)downloadClaims:(id)sender {
   
}

- (IBAction)mapSnapshot:(id)sender {
    
}

- (IBAction)showMenu:(id)sender {
    
}

// observe the queue's operationCount, stop activity indicator if there is no operatation ongoing.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   
}

#pragma handler download result



@end

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

#import "OTSettingViewController.h"

#define TILESPROVIDER @[NSLocalizedString(@"wtms_url_pref_title", nil), NSLocalizedString(@"tms_url_pref_title", nil), NSLocalizedString(@"map_provider_geoserver", nil)]

@interface OTSettingViewController ()

@end

@implementation OTSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureToolBar];

    if (self.sections == nil)
        self.sections = @[NSLocalizedString(@"general", nil),
                          NSLocalizedString(@"map_sources", nil),
                          NSLocalizedString(@"dynamic_form", nil),
                          NSLocalizedString(@"information", nil)];
    if (self.cells == nil)
        self.cells = @[@[@{@"title" : NSLocalizedString(@"cs_url_pref_title", nil),
                           @"subtitle" : NSLocalizedString(@"cs_url_pref_summary", nil)}],
                       @[@{@"title" : NSLocalizedString(@"tiles_provider", nil),
                           @"subtitle" : TILESPROVIDER[[OTSetting getOMTPType]]},
                         @{@"title" : NSLocalizedString(@"geoserver_url_pref_title", nil),
                           @"subtitle" : NSLocalizedString(@"geoserver_url_pref_summary", nil)},
                         @{@"title" : NSLocalizedString(@"geoserver_layer_pref_title", nil),
                           @"subtitle" : NSLocalizedString(@"geoserver_layer_pref_summary", nil)},
                         @{@"title" : NSLocalizedString(@"tms_url_pref_title", nil),
                           @"subtitle" : NSLocalizedString(@"tms_url_pref_summary", nil)},
                         @{@"title" : NSLocalizedString(@"wtms_url_pref_title", nil),
                           @"subtitle" : NSLocalizedString(@"wtms_url_pref_summary", nil)}],
                       @[@{@"title" : NSLocalizedString(@"form_template_url_pref_title", nil),
                           @"subtitle" : NSLocalizedString(@"form_template_url_pref_summary", nil)}],
                       @[@{@"title" : [OTSetting getAppVersion]}]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureToolBar {
    [self.navigationController.toolbar setTintColor:[UIColor otDarkBlue]];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    UIBarButtonItem *reset = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(reInitialization:)];
    [self setToolbarItems:@[reset, flexibleSpace, done]];
  //  [self setToolbarItems:@[flexibleSpace, done]];
    
    NSString *buttonTitle = NSLocalizedString(@"title_activity_settings", nil);
    UIBarButtonItem *logo = [OT logoButtonWithTitle:buttonTitle];
    self.navigationItem.leftBarButtonItems = @[logo];
}

- (IBAction)done:(id)sender {
    [_delegate settingView:self didFinishWithSettings:nil];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)reInitialization:(id)sender {
    [UIAlertView showWithTitle:@"This action will reset all data.." message:nil cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:@[NSLocalizedString(@"confirm", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [SVProgressHUD showWithStatus:@"Please run OT again to make settings effected... " maskType:SVProgressHUDMaskTypeBlack];
            [OTSetting setReInitialization:YES];
            [self performSelector:@selector(abortApp) withObject:self afterDelay:5.0];
        }
    }];
}

- (void)abortApp {
    abort();
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.cells.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cells[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _sections[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSArray *cells = _cells[indexPath.section];
    cell.textLabel.text = [[cells objectAtIndex:indexPath.row] objectForKey:@"title"];
    cell.detailTextLabel.text = [[cells objectAtIndex:indexPath.row] objectForKey:@"subtitle"];
    
    return cell;
 }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"cs_url_pref_title", nil)]) {
        NSString *title = NSLocalizedString(@"cs_url_pref_dialog_title", nil);
        [UIAlertView showWithTitle:title
                           message:nil
                       placeholder:[OTSetting getCommunityServerURL]
                       defaultText:[OTSetting getCommunityServerURL]
                             style:UIAlertViewStylePlainTextInput
                 cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                 otherButtonTitles:@[NSLocalizedString(@"OK", nil)]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex != alertView.cancelButtonIndex) {
                                  NSString *urlString = [[alertView textFieldAtIndex:0] text];
                                  NSURL *theURL = [NSURL URLWithString:urlString];
                                  if (theURL && theURL.scheme && theURL.host) {
                                      [OTSetting setCommunityServerURL:theURL.absoluteString];
                                  } else {
                                      [OT handleErrorWithMessage:@"This URL which has no scheme or host"];
                                  }
                              }
                          }];
    } else if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"geoserver_url_pref_title", nil)]) {
        NSString *title = NSLocalizedString(@"geoserver_url_pref_dialog_title", nil);
        [UIAlertView showWithTitle:title
                           message:nil
                       placeholder:[OTSetting getGeoServerURL]
                       defaultText:[OTSetting getGeoServerURL]
                             style:UIAlertViewStylePlainTextInput
                 cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                 otherButtonTitles:@[NSLocalizedString(@"OK", nil)]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex != alertView.cancelButtonIndex) {
                                  NSString *urlString = [[alertView textFieldAtIndex:0] text];
                                  NSURL *theURL = [NSURL URLWithString:urlString];
                                  if (theURL && theURL.scheme && theURL.host) {
                                      [OTSetting setGeoServerURL:theURL.absoluteString];
                                  } else {
                                      [OT handleErrorWithMessage:@"This URL which has no scheme or host"];
                                  }
                              }
                          }];
    } else if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"geoserver_layer_pref_title", nil)]) {
        NSString *title = NSLocalizedString(@"geoserver_layer_pref_dialog_title", nil);
        [UIAlertView showWithTitle:title
                           message:nil
                       placeholder:[OTSetting getGeoServerLayers]
                       defaultText:[OTSetting getGeoServerLayers]
                             style:UIAlertViewStylePlainTextInput
                 cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                 otherButtonTitles:@[NSLocalizedString(@"OK", nil)]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex != alertView.cancelButtonIndex) {
                                  NSString *layerString = [[alertView textFieldAtIndex:0] text];
                                  if (layerString != nil && layerString.length > 0) {
                                      [OTSetting setGeoServerLayers:layerString];
                                  } else {
                                      [OT handleErrorWithMessage:@"Error"];
                                  }
                              }
                          }];
    } else if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"form_template_url_pref_title", nil)]) {
        NSString *title = NSLocalizedString(@"form_template_url_pref_dialog_title", nil);
        [UIAlertView showWithTitle:title
                           message:nil
                       placeholder:[OTSetting getFormURL]
                       defaultText:nil
                             style:UIAlertViewStylePlainTextInput
                 cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                 otherButtonTitles:@[NSLocalizedString(@"OK", nil)]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex != alertView.cancelButtonIndex) {
                                  NSString *urlString = [[alertView textFieldAtIndex:0] text];
                                  if (urlString.length == 0) {
                                      [OTSetting setFormURL:nil];
                                  } else {
                                      NSURL *theURL = [NSURL URLWithString:urlString];
                                      if (theURL && theURL.scheme && theURL.host) {
                                          [OTSetting setFormURL:theURL.absoluteString];
                                      } else {
                                          [OT handleErrorWithMessage:@"This URL which has no scheme or host"];
                                      }
                                  }
                              }
                          }];
    } else if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"tiles_provider", nil)]) {
        NSString *title = NSLocalizedString(@"tiles_provider_dialog_title", nil);
        [UIAlertView showWithTitle:title
                           message:nil
                 cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                 otherButtonTitles:@[TILESPROVIDER[0],TILESPROVIDER[1],TILESPROVIDER[2]] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                     if (buttonIndex != alertView.cancelButtonIndex) {
                         [OTSetting setOMTPType:buttonIndex - 1];
                         cell.detailTextLabel.text = TILESPROVIDER[[OTSetting getOMTPType]];
                     }
                 }];
    } else if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"tms_url_pref_title", nil)]) {
        NSString *title = NSLocalizedString(@"tms_url_pref_dialog_title", nil);
        [UIAlertView showWithTitle:title
                           message:nil
                       placeholder:[OTSetting getTMSURL]
                       defaultText:[OTSetting getTMSURL]
                             style:UIAlertViewStylePlainTextInput
                 cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                 otherButtonTitles:@[NSLocalizedString(@"OK", nil)]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex != alertView.cancelButtonIndex) {
                                  NSString *urlString = [[alertView textFieldAtIndex:0] text];
                                  urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                  NSURL *theURL = [NSURL URLWithString:urlString];
                                  if (theURL && theURL.scheme && theURL.host) {
                                      [OTSetting setTMSURL:[theURL.absoluteString stringByRemovingPercentEncoding]];
                                  } else {
                                      [OT handleErrorWithMessage:@"This URL which has no scheme or host"];
                                  }
                              }
                          }];
    } else if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"wtms_url_pref_title", nil)]) {
        NSString *title = NSLocalizedString(@"wtms_url_pref_dialog_title", nil);
        [UIAlertView showWithTitle:title
                           message:nil
                       placeholder:[OTSetting getWTMSURL]
                       defaultText:[OTSetting getWTMSURL]
                             style:UIAlertViewStylePlainTextInput
                 cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                 otherButtonTitles:@[NSLocalizedString(@"OK", nil)]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex != alertView.cancelButtonIndex) {
                                  NSString *urlString = [[alertView textFieldAtIndex:0] text];
                                  urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                  NSURL *theURL = [NSURL URLWithString:urlString];
                                  if (theURL && theURL.scheme && theURL.host) {
                                      [OTSetting setWTMSURL:[theURL.absoluteString stringByRemovingPercentEncoding]];
                                  } else {
                                      [OT handleErrorWithMessage:@"This URL which has no scheme or host"];
                                  }
                              }
                          }];
    }
}

@end

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

#import "MapBookmark.h"

@implementation MapBookmark

// Insert code here to add functionality to your managed object subclass
- (NSString *)toString {
    return self.description;
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.lat doubleValue], [self.lon doubleValue]);
}

- (MKPointAnnotation *)annotation {
    MKPointAnnotation *ann = [[MKPointAnnotation alloc] init];
    ann.coordinate = self.coordinate;
    ann.accessibilityHint = @"MapBookmark";
    ann.title = self.name;
    ann.accessibilityValue = self.mapBookmarkId;
    return ann;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    self.lat = [NSDecimalNumber decimalNumberWithString:[@(coordinate.latitude) stringValue]];
    self.lon = [NSDecimalNumber decimalNumberWithString:[@(coordinate.longitude) stringValue]];
}

@end

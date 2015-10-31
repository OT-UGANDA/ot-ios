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

#import "MapBookmarkAnnotationView.h"

@implementation MapBookmarkAnnotationView

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        [self configureUIForStationary];
        [self setDraggable:YES];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if (!selected) {
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^ {
                [self configureUIForSelecting];
            } completion:^(BOOL finished) {
                [self configureUIForStationary];
            }];
        } else {
            [self configureUIForStationary];
        }
    } else {
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^ {
                [self configureUIForStationary];
            } completion:^(BOOL finished) {
                [self configureUIForSelecting];
            }];
        } else {
            [self configureUIForSelecting];
        }
    }
}

- (void)setDragState:(MKAnnotationViewDragState)newDragState animated:(BOOL)animated {
    self.dragState = newDragState;
    if (newDragState == MKAnnotationViewDragStateStarting) {
        
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                [self configureUIForDragging];
            } completion:^(BOOL finished) {
                self.dragState = MKAnnotationViewDragStateDragging;
            }];
        }else{
            [self configureUIForDragging];
            self.dragState = MKAnnotationViewDragStateDragging;
        }
        
    } else if (newDragState == MKAnnotationViewDragStateEnding || newDragState == MKAnnotationViewDragStateCanceling) {
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^ {
                [self configureUIForDragging];
            } completion:^(BOOL finished) {
                [self configureUIForStationary];
                self.dragState = MKAnnotationViewDragStateNone;
            }];
        } else {
            [self configureUIForStationary];
            self.dragState = MKAnnotationViewDragStateNone;
        }
    }
}

- (void) configureUIForSelecting{
    [self setBounds:CGRectMake(0, 0, 29, 29)];
    self.image = [UIImage imageNamed:@"map_bookmark_red"];
    self.centerOffset = CGPointMake(0, 0);
}

- (void) configureUIForDragging{
    [self setBounds:CGRectMake(0, 0, 29, 29)];
    self.image = [UIImage imageNamed:@"map_bookmark_red"];
    self.centerOffset = CGPointMake(0, 0);
}

- (void) configureUIForStationary{
    if ([self.reuseIdentifier isEqualToString:@"MapBookmark"])
        self.image = [UIImage imageNamed:@"map_bookmark"];
    [self setBounds:CGRectMake(0, 0, 29, 29)];
    self.centerOffset = CGPointMake(0, 0);
}

@end

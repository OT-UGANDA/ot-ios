//
//  AttachmentEntity.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/13/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "AbstractEntity.h"

@class Attachment;

@interface AttachmentEntity : AbstractEntity

+ (Attachment *)create;
- (Attachment *)create;

+ (Attachment *)createFromDictionary:(NSDictionary *)object;

@end

//
//  DocumentTypeEntity.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/6/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "AbstractEntity.h"

@class DocumentType;

@interface DocumentTypeEntity : AbstractEntity

+ (DocumentType *)create;
+ (BOOL)insertFromResponseObject:(ResponseDocumentType *)responseObject;
+ (BOOL)updateFromResponseObject:(ResponseDocumentType *)responseObject;

+ (NSArray *)getCollection;

- (NSArray *)getCollection;

+ (DocumentType *)getDocTypeByCode:(NSString *)code;
+ (DocumentType *)getDocTypeByDisplayValue:(NSString *)displayValue;

@end

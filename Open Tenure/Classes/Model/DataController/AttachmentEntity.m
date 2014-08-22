//
//  AttachmentEntity.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/13/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "AttachmentEntity.h"

@implementation AttachmentEntity

#pragma mark - Data

/*!
 Khởi tạo bảng và nạp dữ liệu vào bộ nhớ
 */
- (id)init {
    if (self = [super init]) {
        [self loadData];
    }
    return self;
}

/*!
 Tạo sharedEntity chia sẻ thông tin trong static class
 */
+ (AttachmentEntity *)sharedEntity {
    static dispatch_once_t once;
    __strong static AttachmentEntity *sharedEntity = nil;
    dispatch_once(&once, ^{
        sharedEntity = [self new];
    });
    return sharedEntity;
}

- (void)loadData {
    __weak typeof(self) weakSelf = self;
    // TODO: Progress start
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [weakSelf displayData];
        // TODO Progress dismiss
    });
}

#pragma mark - Overridden getters

/*!
 Override tên bảng dữ liệu vào abstract class
 */
- (NSString *)entityName {
    return @"Attachment";
}

/*!
 Override trường dữ liệu làm section
 */
- (NSString *)mainTableSectionNameKeyPath {
    return nil;
}

/*!
 Override cache cho table
 */
- (NSString *)mainTableCache {
    return @"AttachmentCache";
}

/*!
 Override tên trường sẽ được sắp xếp
 */
- (NSArray *)sortKeys {
    return @[@"documentDate"];
}

/*!
 Override kích thước khối dữ liệu
 */
- (NSUInteger)fetchBatchSize {
    return 30;
}

/*!
 Override predicate mặc định
 */
- (NSPredicate *)frcPredicate {
    return nil;
}

/*
 Override định nghĩa câu truy vấn
 */
- (NSPredicate *)searchPredicateWithSearchText:(NSString *)searchText scope:(NSInteger)scope {
    return [NSPredicate predicateWithFormat:@"(attachmentId == %@)", searchText];
}

#pragma AttachmentEntity methods

+ (Attachment *)create {
    Attachment *entityObject = [NSEntityDescription insertNewObjectForEntityForName:[[self sharedEntity] entityName] inManagedObjectContext:[[self sharedEntity] managedObjectContext]];
    entityObject.status = kAttachmentStatusCreated;
    return entityObject;
}

- (Attachment *)create {
    id entityObject = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:self.managedObjectContext];
    return entityObject;
}

+ (Attachment *)createFromDictionary:(NSDictionary *)object {
    
    object = object.deserialize;
    
    Attachment *attachment = [self create];

    attachment.attachmentId = [object objectForKey:@"id"];
    attachment.note = [object objectForKey:@"description"];
    attachment.documentDate = [object objectForKey:@"documentDate"];
    attachment.fileExtension = [object objectForKey:@"fileExtension"];
    attachment.fileName = [object objectForKey:@"fileName"];
    attachment.size = [NSString stringWithFormat:@"%@", [object objectForKey:@"size"]];
    attachment.mimeType = [object objectForKey:@"mimeType"];
    attachment.referenceNr = [object objectForKey:@"referenceNr"];
    attachment.md5 = [object objectForKey:@"md5"];
    attachment.status = [object objectForKey:@"status"];
    NSString *claimId = [object objectForKey:@"claimId"];
    if (claimId != nil) {
        Claim *claim = [ClaimEntity getClaimByClaimId:claimId];
        if (claim) {
            attachment.claim = claim;
        }
    }
    NSString *typeCode = [object objectForKey:@"typeCode"];
    DocumentType *docType = [DocumentTypeEntity getDocTypeByDisplayValue:typeCode];
    if (typeCode) {
        attachment.typeCode = docType;
    }

    return attachment;
}

@end

//
//  PersonEntity.m
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/7/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "PersonEntity.h"

@implementation PersonEntity

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
 Tạo sharedPersonEntity chia sẻ thông tin trong static class
 */
+ (PersonEntity *)sharedPersonEntity {
    static dispatch_once_t once;
    __strong static PersonEntity *sharedPersonEntity = nil;
    dispatch_once(&once, ^{
        sharedPersonEntity = [self new];
    });
    return sharedPersonEntity;
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
    return @"Person";
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
    return @"PersonCache";
}

/*!
 Override tên trường sẽ được sắp xếp
 */
- (NSArray *)sortKeys {
    return @[@"firstName"];
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
    return [NSPredicate predicateWithFormat:@"(personId == %@)", searchText];
}

#pragma PersonEntity methods

+ (Person *)create {
    NSManagedObjectContext *context = [[[self sharedPersonEntity] fetchedResultsController] managedObjectContext];
    NSEntityDescription *entity = [[[[self sharedPersonEntity] fetchedResultsController] fetchRequest] entity];
    
    Person *entityObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    return entityObject;
}

- (Person *)create {
    Person *entityObject = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:self.managedObjectContext];
    return entityObject;
}

+ (Person *)createFromDictionary:(NSDictionary *)object {
    
    object = object.deserialize;
    
    Person *person = [self create];
    
    person.personId = [object objectForKey:@"id"];
    person.firstName = [object objectForKey:@"name"];
    person.lastName = [object objectForKey:@"lastName"];
    person.dateOfBirth = [object objectForKey:@"birthDate"];
    person.gender = [object objectForKey:@"genderCode"];
    NSString *idTypeCode = [object objectForKey:@"idTypeCode"];
    if (idTypeCode != nil) {
        IdType *idType = [IdTypeEntity idTypeByCode:idTypeCode];
        if (idType) {
            person.idType = idType;
        }
    }
    person.idNumber = [object objectForKey:@"idNumber"];
    person.postalAddress = [object objectForKey:@"address"];
    person.emailAddress = [object objectForKey:@"email"];
    person.contactPhoneNumber = [object objectForKey:@"phone"];
    person.mobilePhoneNumber = [object objectForKey:@"mobilePhone"];
    person.personType = [[object objectForKey:@"person"] integerValue] == 1 ? kPersonTypePhysical : kPersonTypeGroup;
    return person;
}

+ (Person *)getPersonByPersonId:(NSString *)personId {
    [self sharedPersonEntity]->_filteredResults = nil;
    
    [[self sharedPersonEntity] filterContentForSearchText:personId scope:0];
    if ([self sharedPersonEntity]->_filteredObjects.count > 0) {
        return [[self sharedPersonEntity]->_filteredObjects firstObject];
    }
    return nil;
}

@end

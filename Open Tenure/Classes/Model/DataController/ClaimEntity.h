//
//  ClaimEntity.h
//  Open Tenure
//
//  Created by Chuyen Trung Tran on 8/6/14.
//  Copyright (c) 2014 Food and Agriculture Organization of the United Nations (FAO). All rights reserved.
//

#import "AbstractEntity.h"

@interface ClaimEntity : AbstractEntity

+ (Claim *)create;

- (Claim *)create;

/*!
 Thêm claim vào db, duy nhất claimId và statusCode sau khi getAllClaims.
 Các trường còn lại sẽ được hàm updateDetail đảm nhận
 @result
 YES nếu thêm mới thành công, tiếp tục getClaim để lấy chi tiết của claim theo claimId. Hàm updateDetailFromResponseObject sẽ được gọi khi getClaim thành công, lúc này sẽ cập nhật chi tiết
 @result
 NO nếu thêm mới không thành công.
 */
+ (BOOL)insertFromResponseObject:(ResponseClaim *)responseObject;

/*!
 Kiểm tra sự tồn tại của claim trên local (những claim đã tải về). Cập nhật trạng thái cho các claims đã tải về nếu có sự thay đổi từ phía server.
 @param
 responseObject là claim(claimId, statusCode) được tải về từ server bằng hàm getAllClaims
 @result
 YES nếu claim chưa có trên local thì thêm mới claim bằng hàm insertFromResponseObject
 @result
 NO nếu claim đã tồn tại. Trước đó sẽ phải cập nhật statusCode.
 */
+ (BOOL)updateFromResponseObject:(ResponseClaim *)responseObject;


/*!
 Kiểm tra sự tồn tại của claim trên local (những claim đã tải về). Cập nhật chi tiết cho các claims đã tải về.
 @param
 responseObject là claim(claimId, statusCode, ...) được tải về từ server bằng hàm getClaim
 @result
 YES nếu claim đã tồn tại
 @result
 NO nếu claim không tồn tại. Lưu ý: hàm updateFromResponseObject phải được gọi trước
 */
+ (Claim *)updateDetailFromResponseObject:(ResponseClaim *)responseObject;

/*!
 Lấy tất cả các bản ghi
 @result
 Danh sách các bản ghi
 */
+ (NSArray *)getCollection;

+ (Claim *)getClaimByClaimId:(NSString *)claimId;

@end

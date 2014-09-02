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

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

#import "CommunityServerAPIUtilities.h"

NSString *HTTPS_LOGIN = @"%@/ws/%@/auth/login?username=%@&password=%@";

NSString *HTTPS_LOGOUT = @"%@/ws/%@/auth/logout";

NSString *HTTPS_GETCLAIM = @"%@/ws/%@/claim/getClaim/%@";

NSString *HTTPS_GETATTACHMENT = @"%@/claim/getAttachment?id=%@";

NSString *HTTPS_SAVECLAIM = @"%@/ws/%@/claim/saveClaim";

NSString *HTTPS_SAVEATTACHMENT = @"%@/ws/%@/claim/saveAttachment";

NSString *HTTPS_UPLOADCHUNK = @"%@/ws/%@/claim/uploadChunk";

NSString *HTTPS_GETALLCLAIMS = @"%@/ws/%@/claim/getAllClaims";

NSString *HTTPS_GETALLCLAIMSBYBOX = @"%@/ws/%@/claim/getClaimsByBox?minx=%@&miny=%@&maxx=%@&maxy=%@&limit=%@";

NSString *HTTPS_GETCLAIMTYPES = @"%@/ws/%@/ref/getclaimtypes";

NSString *HTTPS_GETDOCUMENTYPES = @"%@/ws/%@/ref/getdocumenttypes";

NSString *HTTPS_GETIDTYPES = @"%@/ws/%@/ref/getidtypes";

NSString *HTTPS_GETLANDUSE = @"%@/ws/%@/ref/getlanduses";

NSString *HTTPS_GETCOMMUNITYAREA = @"%@/ws/%@/ref/getcommunityarea";

NSString *HTTPS_WITHDRAWCLAIM = @"%@/ws/%@/claim/withdrawclaim/%@";

NSString *HTTPS_GETDEFAULTFORMTEMPLATE = @"%@/ws/%@/claim/getDefaultFormTemplate";

NSString *HTTPS_GETPARACELGEOMREQUIRED = @"%@/ws/%@/claim/getParcelGeomRequired";

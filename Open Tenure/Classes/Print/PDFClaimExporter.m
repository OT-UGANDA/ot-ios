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

#import "PDFClaimExporter.h"
#import "ShapeKit.h"
#import "UIImage+OT.h"

@interface PDFClaimExporter () {
    NSString *filePath;
    CGSize pageSize;
    CGFloat A4_PAGE_WIDTH;
    CGFloat A4_PAGE_HEIGHT;
    CGFloat DEFAULT_FONT_SIZE;
    CGFloat DEFAULT_LEFT_MARGIN;
    CGFloat DEFAULT_RIGHT_MARGIN;
    CGFloat DEFAULT_TOP_MARGIN;
    CGFloat DEFAULT_BOTTOM_MARGIN;
    CGFloat DEFAULT_TEXT_INDENT;
    CGFloat DEFAULT_LINE_SPACING;
    
    CGFloat INNER_WIDTH;
    NSMutableParagraphStyle *paragraphStyle;
}

@end

@implementation PDFClaimExporter

- (id)init {
    if (self = [super init]) {
        A4_PAGE_WIDTH = 595.0;
        A4_PAGE_HEIGHT = 842.0;
        DEFAULT_FONT_SIZE = 12.0;
        DEFAULT_LEFT_MARGIN = 40.0;
        DEFAULT_RIGHT_MARGIN = 40.0;
        DEFAULT_TOP_MARGIN = 40.0;
        DEFAULT_BOTTOM_MARGIN = 40.0;
        DEFAULT_TEXT_INDENT = 4.0;
        DEFAULT_LINE_SPACING = 8.0;

        // Default A4
        pageSize = CGSizeMake(A4_PAGE_WIDTH, A4_PAGE_HEIGHT);
    }
    return self;
}

- (id)initWithClaim:(Claim *)claim {
    if (self = [self init]) {
        if (_claim == nil)
            _claim = claim;
        [self setupPDFWithName:@"print_and_sign_this.pdf" pageSize:pageSize];
        [self export];
        [self finishPDF];
    }
    return self;
}

- (void)setupValues {
    INNER_WIDTH = pageSize.width - DEFAULT_LEFT_MARGIN - DEFAULT_RIGHT_MARGIN;
    paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
}

- (void)export {
    [self setupValues];
    
    [self beginPDFPage];
    
    NSString *title = [NSString stringWithFormat:@"%@ #%@", NSLocalizedString(@"claim", nil), _claim.nr];
    // Logo
    UIImage *logoImage = [UIImage imageNamed:@"OpenTenure"];
    CGRect rect = [self addImage:logoImage atPoint:CGPointMake(DEFAULT_LEFT_MARGIN, DEFAULT_TOP_MARGIN) size:logoImage.size];
    
    // Tiêu đề

    CGRect rect0 = rect;
    rect0.origin.x += rect.size.width + DEFAULT_LEFT_MARGIN;
    rect0.origin.y += rect.size.height / 2.0 - DEFAULT_FONT_SIZE * 2.0;
    rect0.size.width = INNER_WIDTH - rect.size.width;
    rect0 = [self addText:title inRect:rect0
                  withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE * 2.0f], NSForegroundColorAttributeName:[UIColor otDarkBlue], NSParagraphStyleAttributeName:paragraphStyle}];
    
    // Generated on
    NSString *generatedDate = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"generated_on", nil), [[[OT dateFormatter] stringFromDate:[NSDate date]] substringToIndex:10]];
    paragraphStyle.alignment = NSTextAlignmentRight;
    
    rect0.origin.x = INNER_WIDTH - DEFAULT_RIGHT_MARGIN + 2.0 * DEFAULT_TEXT_INDENT;
    rect0.origin.y += rect0.size.height;
    rect0.size.width = DEFAULT_LEFT_MARGIN * 2.0;
    [self addText:generatedDate inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE * 0.9f], NSParagraphStyleAttributeName:paragraphStyle}];
    
    rect.origin.y += DEFAULT_LINE_SPACING;
    rect = [self pdfSubTitle:NSLocalizedString(@"title_claimant", nil) inRect:rect];
    
    rect.size.width = INNER_WIDTH;
    rect = [self pdfPerson:_claim.person inRect:rect];
    
    rect = [self pdfSubTitle:NSLocalizedString(@"owners", nil) inRect:rect];

    // Shares
    for (Share *share in _claim.shares) {
        rect.origin.x = DEFAULT_LEFT_MARGIN + DEFAULT_TEXT_INDENT;
        rect.origin.y += rect.size.height + DEFAULT_LINE_SPACING;
        rect.size.width = INNER_WIDTH;
        NSString *titleShare = [NSString stringWithFormat:@"%@ %tu/%tu", NSLocalizedString(@"title_share", nil), [share.nominator integerValue], [share.denominator integerValue]];
        rect = [self addText:titleShare inRect:rect withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
        rect.origin.x = DEFAULT_LEFT_MARGIN;
        rect.origin.y += rect.size.height;
        rect.size.width = INNER_WIDTH;
        rect.size.height = 0.5;
        rect = [self addLineInRect:rect withColor:[UIColor otGreen]];

        rect.origin.x = DEFAULT_LEFT_MARGIN + DEFAULT_TEXT_INDENT;
        rect.origin.y += rect.size.height;
        rect.size.width = INNER_WIDTH;
        for (Person *person in share.owners) {
            rect = [self pdfPerson:person inRect:rect];
            rect.origin.x = DEFAULT_LEFT_MARGIN;
            rect.origin.y += rect.size.height;
            rect.size.width = INNER_WIDTH;
            rect.size.height = 0.5;
            rect = [self addDashLineInRect:rect withColor:[UIColor otGreen]];
        }
    }
    
    // Documents
    rect = [self pdfSubTitle:NSLocalizedString(@"title_claim_documents", nil) inRect:rect];
    rect.origin.y += rect.size.height + DEFAULT_LINE_SPACING;
    rect = [self pdfClaimDocumentsInRect:rect];

    // Additional information
    rect = [self pdfSubTitle:NSLocalizedString(@"title_claim_additional_info", nil) inRect:rect];
    rect.origin.y += rect.size.height + DEFAULT_LINE_SPACING;
    rect = [self addText:_claim.notes inRect:rect withAttributes:@{NSFontAttributeName:[UIFont italicSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    if (rect.size.height == 0.0) rect.size.height = DEFAULT_LINE_SPACING;
    
    // Parcel
    rect.origin.y += DEFAULT_LINE_SPACING;
    rect = [self pdfSubTitle:NSLocalizedString(@"title_claim_parcel", nil) inRect:rect];
    rect.origin.y += rect.size.height + DEFAULT_LINE_SPACING;
    rect = [self pdfParcelInRect:rect];
    rect.size.height = 0.5;
    rect.size.width = INNER_WIDTH;
    rect.origin.x = DEFAULT_LEFT_MARGIN;
    rect = [self addDashLineInRect:rect withColor:[UIColor otGreen]];
    rect.size.height = 0.5;
    rect.size.width = INNER_WIDTH;
    rect.origin.x = DEFAULT_LEFT_MARGIN + DEFAULT_TEXT_INDENT;
    rect.origin.y += rect.size.height + DEFAULT_LINE_SPACING;
    rect = [self pdfAdjacencyInRect:rect];
    rect.size.height = 0.5;
    rect.size.width = INNER_WIDTH;
    rect.origin.x = DEFAULT_LEFT_MARGIN;
    rect = [self addDashLineInRect:rect withColor:[UIColor otGreen]];
    rect.origin.x = DEFAULT_LEFT_MARGIN + DEFAULT_TEXT_INDENT;
    // Cadastral map
    CGSize imageSize = CGSizeMake(INNER_WIDTH, INNER_WIDTH - DEFAULT_LINE_SPACING * 8.0);
    UIImage *claimImage = [self getCadastralMapWithSize:imageSize];
    if (claimImage != nil)
        rect = [self addImage:claimImage atPoint:CGPointMake(DEFAULT_LEFT_MARGIN, rect.origin.y + rect.size.height + DEFAULT_LINE_SPACING) size:imageSize];
    else {
        CGRect rect00 = CGRectMake(DEFAULT_LEFT_MARGIN, rect.origin.y + DEFAULT_LINE_SPACING, pageSize.width - DEFAULT_LEFT_MARGIN * 2.0, DEFAULT_FONT_SIZE);
        rect = [self addText:@"Please download Cadastral Map!" inRect:rect00 withAttributes:@{NSFontAttributeName:[UIFont italicSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    }
    // Signature & Date
    NSString *dateText = NSLocalizedString(@"date", nil);
    NSString *signatureText = NSLocalizedString(@"signature", nil);
    rect.origin.x = DEFAULT_LEFT_MARGIN + DEFAULT_TEXT_INDENT;
    rect.origin.y += rect.size.height + DEFAULT_LINE_SPACING * 4.0;
    rect.size.width = INNER_WIDTH / 2.0;
    rect = [self addText:signatureText inRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    rect0 = rect;
    rect0.origin.x += rect.size.width;
    rect0.origin.y += rect.size.height;
    rect0.size.width = INNER_WIDTH / 2.0 - rect.size.width - DEFAULT_TEXT_INDENT;
    rect0.size.height = 0.5;
    [self addLineInRect:rect0 withColor:[UIColor otGreen]];
    
    rect.origin.x += INNER_WIDTH / 2.0;
    rect = [self addText:dateText inRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x = rect.origin.x + rect.size.width;
    rect0.size.width = INNER_WIDTH / 2.0 - rect.size.width - DEFAULT_TEXT_INDENT;
    [self addLineInRect:rect0 withColor:[UIColor otGreen]];
}

- (CGRect)pdfSubTitle:(NSString *)subtitle inRect:(CGRect)rect {
    rect.size.width = INNER_WIDTH;
    rect.origin.x = DEFAULT_LEFT_MARGIN;
    rect.origin.y += rect.size.height;
    rect.size.height = 1.0;
    
    rect = [self addLineInRect:rect withColor:[UIColor otGreen]];
    // Fill rect
    rect.size.height = DEFAULT_FONT_SIZE + DEFAULT_LINE_SPACING * 1.2;
    rect = [self addFillRectInRect:rect fillColor:[UIColor otLightGreen]];
    
    rect.origin.y += DEFAULT_LINE_SPACING / 2.0;
    rect.origin.x += DEFAULT_TEXT_INDENT;
    rect.size.width = INNER_WIDTH - 2.0 * DEFAULT_TEXT_INDENT;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    rect = [self addText:subtitle inRect:rect withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    return rect;
}

- (CGRect)pdfClaimDocumentsInRect:(CGRect)rect {
    CGFloat width = (INNER_WIDTH - DEFAULT_TEXT_INDENT * 2.0) / 4.0;
    CGRect rect0 = rect;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"type", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"title_claim_document_reference", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"title_claim_document_date", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"title_claim_document_description", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];

    rect0.origin.x = rect.origin.x;
    rect0.origin.y += rect0.size.height + DEFAULT_LINE_SPACING;
    for (Attachment *att in _claim.attachments) {
        rect0.size.width = width;
        rect0 = [self addText:att.typeCode.displayValue inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
        rect0.origin.x += width;
        rect0.size.width = width;
        rect0 = [self addText:att.referenceNr inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
        rect0.origin.x += width;
        rect0.size.width = width;
        rect0 = [self addText:[att.documentDate substringToIndex:10] inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
        rect0.origin.x += width;
        rect0.size.width = width;
        rect0 = [self addText:att.note inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
        rect0.origin.y += rect0.size.height + DEFAULT_LINE_SPACING;
        rect0.origin.x = rect.origin.x;
    }
    return rect0;
}

- (CGRect)pdfParcelInRect:(CGRect)rect {
    CGFloat width = (INNER_WIDTH - DEFAULT_TEXT_INDENT * 2.0) / 4.0;
    CGRect rect0 = rect;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"claim_area_label", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"title_claim_type_label", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"land_use", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"title_claim_occupied_since", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    rect0.origin.x = rect.origin.x;
    rect0.origin.y += rect0.size.height + DEFAULT_LINE_SPACING;
    rect0.size.width = width;
    // Claim's area
    NSString *claimAreaText = [NSString stringWithFormat:@"%0.0f %@", _claim.area, NSLocalizedString(@"square_meters", nil)];
    
    rect0 = [self addText:claimAreaText inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:_claim.claimType.displayValue inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:_claim.landUse.displayValue inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:[_claim.startDate substringToIndex:10] inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.y += rect0.size.height + DEFAULT_LINE_SPACING;
    rect0.origin.x = rect.origin.x;
    return rect0;
}

- (CGRect)pdfAdjacencyInRect:(CGRect)rect {
    CGFloat width = (INNER_WIDTH - DEFAULT_TEXT_INDENT * 2.0) / 4.0;
    CGRect rect0 = rect;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"title_claim_north_adjacency_label", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"title_claim_south_adjacency_label", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"title_claim_east_label", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:NSLocalizedString(@"title_claim_west_label", nil) inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    rect0.origin.x = rect.origin.x;
    rect0.origin.y += rect0.size.height + DEFAULT_LINE_SPACING;
    rect0.size.width = width;
    
    rect0 = [self addText:_claim.northAdjacency inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:_claim.southAdjacency inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:_claim.eastAdjacency inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.x += width;
    rect0.size.width = width;
    rect0 = [self addText:_claim.westAdjacency inRect:rect0 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect0.origin.y += rect0.size.height + DEFAULT_LINE_SPACING;
    rect0.origin.x = rect.origin.x;
    return rect0;
}

- (CGRect)pdfPerson:(Person *)person inRect:(CGRect)rect {
    // Title Name
    NSString *titleName = NSLocalizedString(@"group_name", nil);
    NSString *titleBirthDate = [person.person boolValue] ? NSLocalizedString(@"date_of_birth", nil) : NSLocalizedString(@"date_of_establishment_label", nil);
    NSString *claimantName = [person.person boolValue] ? [person fullNameType:OTFullNameTypeDefault] : person.name;
    NSString *birthDate = [person.birthDate substringToIndex:10];
    rect.origin.x = DEFAULT_LEFT_MARGIN + DEFAULT_TEXT_INDENT;
    rect.origin.y += rect.size.height + DEFAULT_LINE_SPACING;
    rect.size.width = INNER_WIDTH / 2.0 - 2.0 * DEFAULT_TEXT_INDENT;
    rect = [self addText:titleName inRect:rect withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    // Title Birthdate
    rect.origin.x = DEFAULT_LEFT_MARGIN + INNER_WIDTH / 2.0;
    rect.size.width = INNER_WIDTH / 2.0 - 2.0 * DEFAULT_TEXT_INDENT;
    rect = [self addText:titleBirthDate inRect:rect withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    // Name
    rect.origin.x = DEFAULT_LEFT_MARGIN + DEFAULT_TEXT_INDENT;
    rect.origin.y += rect.size.height;
    rect.size.width = INNER_WIDTH / 2.0 - 2.0 * DEFAULT_TEXT_INDENT;
    rect = [self addText:claimantName inRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    // Birthdate
    rect.origin.x = DEFAULT_LEFT_MARGIN + INNER_WIDTH / 2.0;
    rect.size.width = INNER_WIDTH / 2.0 - 2.0 * DEFAULT_TEXT_INDENT;
    rect = [self addText:birthDate inRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    // Title ID Type
    rect.origin.x = DEFAULT_LEFT_MARGIN + DEFAULT_TEXT_INDENT;
    rect.origin.y += rect.size.height + DEFAULT_LINE_SPACING;
    rect.size.width = INNER_WIDTH / 2.0 - 2.0 * DEFAULT_TEXT_INDENT;
    rect = [self addText:NSLocalizedString(@"id_type", nil) inRect:rect withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    // Title ID Number
    rect.origin.x = DEFAULT_LEFT_MARGIN + INNER_WIDTH / 2.0;
    rect.size.width = INNER_WIDTH / 2.0 - 2.0 * DEFAULT_TEXT_INDENT;
    rect = [self addText:NSLocalizedString(@"id_number", nil) inRect:rect withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    // ID Type
    IdTypeEntity *idTypeEntity = [IdTypeEntity new];
    NSArray *entities= [idTypeEntity getCollectionWithProperties:@[@"code", @"displayValue"]];
    NSArray *codes = [entities valueForKeyPath:@"code"];
    NSArray *displayValues = [entities valueForKeyPath:@"displayValue"];
    NSDictionary *idTypes = [NSDictionary dictionaryWithObjects:displayValues forKeys:codes];
    
    NSString *idTypeText = [person.person boolValue] ? [idTypes objectForKey:person.idTypeCode] : @"-";
    rect.origin.x = DEFAULT_LEFT_MARGIN + DEFAULT_TEXT_INDENT;
    rect.origin.y += rect.size.height;
    rect.size.width = INNER_WIDTH / 2.0 - 2.0 * DEFAULT_TEXT_INDENT;
    rect = [self addText:idTypeText inRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    // Id Number
    NSString *idNumberText = person.idNumber ? person.idNumber : @"-";
    rect.origin.x = DEFAULT_LEFT_MARGIN + INNER_WIDTH / 2.0;
    rect.size.width = INNER_WIDTH / 2.0 - 2.0 * DEFAULT_TEXT_INDENT;
    rect = [self addText:idNumberText inRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    // Address
    rect.origin.x = DEFAULT_LEFT_MARGIN + DEFAULT_TEXT_INDENT;
    rect.origin.y += rect.size.height + DEFAULT_LINE_SPACING;
    rect.size.width = INNER_WIDTH - 2.0 * DEFAULT_TEXT_INDENT;
    rect = [self addText:NSLocalizedString(@"postal_address", nil) inRect:rect withAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    
    NSString *addressText = person.address;
    rect.origin.y += rect.size.height;
    rect.size.width = INNER_WIDTH + DEFAULT_TEXT_INDENT / 2.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    rect = [self addText:addressText inRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:DEFAULT_FONT_SIZE], NSParagraphStyleAttributeName:paragraphStyle}];
    rect.size.height = DEFAULT_FONT_SIZE * 2.5;
    return rect;
}

#pragma mark - PDFCreator

- (NSString *)getFilePath {
    return filePath;
}

- (void)setupPDFWithName:(NSString *)name pageSize:(CGSize)pageSize {
    [FileSystemUtilities createClaimFolder:_claim.claimId];
    [FileSystemUtilities createClaimantFolder:_claim.claimId];
    NSString *claimFolder = [[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:[FileSystemUtilities getClaimFolder:_claim.claimId]];
    filePath = [claimFolder stringByAppendingPathComponent:name];
    UIGraphicsBeginPDFContextToFile(filePath, CGRectZero, nil);
}

- (void)beginPDFPage {
    UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, pageSize.width, pageSize.height), nil);
}

- (CGRect)addText:(NSString*)text inRect:(CGRect)rect withAttributes:(NSDictionary *)attributes {
    if (text == nil) text = @"-";
    CGRect textRect = [text boundingRectWithSize:(CGSize){rect.size.width, CGFLOAT_MAX}
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes
                                         context:nil];
    
    CGSize stringSize = textRect.size;
    float textWidth = rect.size.width;
    
    if (stringSize.width > pageSize.width - rect.origin.x - (rect.size.width - rect.origin.x))
        textWidth = rect.size.width;
    else
        textWidth = stringSize.width;

    // Check for new page
    if (rect.origin.y + stringSize.height > pageSize.height - DEFAULT_BOTTOM_MARGIN) {
        [self beginPDFPage];
        rect.origin.y = DEFAULT_TOP_MARGIN;
    }

    CGRect renderingRect = CGRectMake(rect.origin.x, rect.origin.y, textWidth, stringSize.height);
    
    [text drawInRect:renderingRect withAttributes:attributes];
    
    rect = CGRectMake(rect.origin.x, rect.origin.y, textWidth, stringSize.height);
    return rect;
}

- (CGRect)addLineInRect:(CGRect)rect withColor:(UIColor *)color {
    // Check for new page
    if (rect.origin.y + rect.size.height > pageSize.height - DEFAULT_TOP_MARGIN - DEFAULT_BOTTOM_MARGIN) {
        [self beginPDFPage];
        rect.origin.y = DEFAULT_TOP_MARGIN;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    CGPoint startPoint = rect.origin;
    CGPoint endPoint = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
    
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextSetLineWidth(context, rect.size.height);
    CGContextStrokePath(context);
    return rect;
}

- (CGRect)addDashLineInRect:(CGRect)rect withColor:(UIColor *)color {
    // Check for new page
    if (rect.origin.y + rect.size.height > pageSize.height - DEFAULT_TOP_MARGIN - DEFAULT_BOTTOM_MARGIN) {
        [self beginPDFPage];
        rect.origin.y = DEFAULT_TOP_MARGIN;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat dashPhase = 0.0;
    CGFloat dashPattern[] = {1.0, 1.0};
    CGFloat dashCount = 2;

    CGContextSetLineDash(context, dashPhase, dashPattern, dashCount);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    CGPoint startPoint = rect.origin;
    CGPoint endPoint = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);

    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextSetLineWidth(context, rect.size.height);
    CGContextStrokePath(context);
    // restore
    CGContextSetLineDash(context, 0, NULL, 0);
    return rect;
}

- (CGRect)addFillRectInRect:(CGRect)rect fillColor:(UIColor *)color {
    // Check for new page
    if (rect.origin.y + rect.size.height > pageSize.height - DEFAULT_TOP_MARGIN - DEFAULT_BOTTOM_MARGIN) {
        [self beginPDFPage];
        rect.origin.y = DEFAULT_TOP_MARGIN;
    }

    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(currentContext, [color CGColor]);
    CGContextFillRect(currentContext, rect);
    return rect;
}

- (CGRect)addImage:(UIImage*)image atPoint:(CGPoint)point size:(CGSize)size {
    CGRect rect = CGRectMake(point.x, point.y, size.width, size.height);
    // Check for new page
    if (rect.origin.y + rect.size.height > pageSize.height - DEFAULT_TOP_MARGIN - DEFAULT_BOTTOM_MARGIN) {
        [self beginPDFPage];
        rect.origin.y = DEFAULT_TOP_MARGIN;
    }

    [image drawInRect:rect];
    return rect;
}

- (UIImage *)getCadastralMapWithSize:(CGSize)size {
    NSString *cadastralMap = @"_map_.jpg";
    for (Attachment *attachment in _claim.attachments) {
        if ([attachment.typeCode.code isEqualToString:@"cadastralMap"] &&
            [attachment.note isEqualToString:@"Map"]) {
            cadastralMap = [attachment.fileName lastPathComponent];
        }
    }
    NSString *claimImagePath = [[[FileSystemUtilities applicationDocumentsDirectory] path] stringByAppendingPathComponent:[[FileSystemUtilities getAttachmentFolder:_claim.claimId] stringByAppendingPathComponent:cadastralMap]];
    UIImage *image = [UIImage imageWithContentsOfFile:claimImagePath];
    if (image) {
        CGFloat width = image.size.width < image.size.height ? image.size.width : image.size.height;
        CGFloat scale = size.width > size.height ? width / size.width : width / size.height;
        CGSize newSize = CGSizeMake(scale * size.width, scale * size.height);
        return [image cropToSize:newSize];
    }
    return image;
}

- (void)finishPDF {
    UIGraphicsEndPDFContext();
}

@end

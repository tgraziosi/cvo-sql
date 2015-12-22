SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

CREATE PROCEDURE [dbo].[GetDesktopLayout_sp]  @layoutId uniqueidentifier
AS
select 	LayoutId,
	ParentFolderId,
	FolderId,
	IconId,
	Caption,
	DisplayOrder,
	ClassId,
	HTMLDocument,
	Owner,
	IsNull(CaptionStrings.StringText, '') CaptionString
from Strings CaptionStrings RIGHT OUTER JOIN DesktopLayout ON (CaptionStrings.StringId = DesktopLayout.Caption)
where DesktopLayout.LayoutId = @layoutId
Order By ParentFolderId, DisplayOrder
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[GetDesktopLayout_sp] TO [public]
GO

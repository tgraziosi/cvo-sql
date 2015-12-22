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

CREATE PROCEDURE [dbo].[GetObjectClasses_sp] @classId uniqueidentifier = Null
AS

if @classId IS Null

select ObjectClasses.ClassId,
 Name,
 Application,
 ObjectClasses.Category,
 Description,
 Creator,
 Owner,
 BaseClass,
 IconKey,
 HelpId,
 Title,
 Tooltip,
 SourceFileName,
 VersionCode,
 BuildNumber,
 Form_ID=0,
 VbaProjectName,
 IsNull(DescriptionStrings.StringText, '') DescriptionString, 
 IsNull(TitleStrings.StringText, '') TitleString, 
 IsNull(TooltipStrings.StringText, '') TooltipString,
 IsNull(Applications.ApplicationName, '') ApplicationString,
 IsNull(Category.Category, '') CategoryString
from ObjectClasses
	LEFT OUTER JOIN smcom ON (smcom.ClassID = ObjectClasses.ClassId)
	LEFT OUTER JOIN Strings DescriptionStrings ON (DescriptionStrings.StringId = ObjectClasses.Description)
	LEFT OUTER JOIN Strings TitleStrings ON (TitleStrings.StringId = ObjectClasses.Title)
	LEFT OUTER JOIN Strings TooltipStrings  ON (TooltipStrings.StringId = ObjectClasses.Tooltip)
	LEFT OUTER JOIN ApplicationObjectNames Applications ON (Applications.ApplicationId = ObjectClasses.Application)
	LEFT OUTER JOIN Category ON (Category.CategoryId = ObjectClasses.Category)
else

select ObjectClasses.ClassId,
 Name,
 Application,
 ObjectClasses.Category,
 Description,
 Creator,
 Owner,
 BaseClass,
 IconKey,
 HelpId,
 Title,
 Tooltip,
 SourceFileName,
 VersionCode,
 BuildNumber,
 Form_ID,
 VbaProjectName,
 IsNull(DescriptionStrings.StringText,'') DescriptionString, 
 IsNull(TitleStrings.StringText, '') TitleString, 
 IsNull(TooltipStrings.StringText, '') TooltipString,
 IsNull(Applications.ApplicationName, '') ApplicationString,
 IsNull(Category.Category, '') CategoryString
from smcom, 
     ObjectClasses
	LEFT OUTER JOIN Strings DescriptionStrings ON (DescriptionStrings.StringId = ObjectClasses.Description)
	LEFT OUTER JOIN Strings TitleStrings ON (TitleStrings.StringId = ObjectClasses.Title)
	LEFT OUTER JOIN Strings TooltipStrings  ON (TooltipStrings.StringId = ObjectClasses.Tooltip)
	LEFT OUTER JOIN ApplicationObjectNames Applications ON (Applications.ApplicationId = ObjectClasses.Application)
	LEFT OUTER JOIN Category ON (Category.CategoryId = ObjectClasses.Category)
WHERE smcom.ClassID= @classId
AND ObjectClasses.ClassId = @classId
order by TitleString
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[GetObjectClasses_sp] TO [public]
GO

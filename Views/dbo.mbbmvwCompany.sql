SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE VIEW [dbo].[mbbmvwCompany]
AS
/************************************************************************************
* Copyright 2008 Sage Software, Inc. All rights reserved.                           *
* This procedure, trigger or view is the intellectual property of Sage Software,    *
* Inc.  You may not reverse engineer, alter, or redistribute this code without the  *
* express written permission of Sage Software, Inc.  This code, or any portions of  *
* it, may not be used for any other purpose except for the use of the application   *
* software that it was shipped with.  This code falls under the licensing agreement *
* shipped with the software.  See your license agreement for further information.   *
************************************************************************************/
SELECT  CompanyCode =   company_code,
	Description =   description,
	DB =            db_name,
	AcctFormat =    account_format_mask
FROM glcomp_vw
GO
GRANT REFERENCES ON  [dbo].[mbbmvwCompany] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwCompany] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmvwCompany] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmvwCompany] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmvwCompany] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwCompany] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmvwCompany] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmvwCompany] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmvwCompany] TO [public]
GO

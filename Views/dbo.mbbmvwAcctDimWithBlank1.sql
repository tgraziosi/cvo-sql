SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE VIEW [dbo].[mbbmvwAcctDimWithBlank1]
WITH ENCRYPTION
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
SELECT CompanyCode as HostCompany,
       '' AS Dim_Value,
       '' AS Description
FROM mbbmvwCompany
UNION
SELECT DISTINCT
	CompanyCode as HostCompany,
	reference_code AS Dim_Value, 
	glref.[description] AS Description
FROM glref join mbbmvwCompany on 1=1 
GO
GRANT REFERENCES ON  [dbo].[mbbmvwAcctDimWithBlank1] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwAcctDimWithBlank1] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmvwAcctDimWithBlank1] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmvwAcctDimWithBlank1] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmvwAcctDimWithBlank1] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwAcctDimWithBlank1] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmvwAcctDimWithBlank1] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmvwAcctDimWithBlank1] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmvwAcctDimWithBlank1] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE VIEW [dbo].[mbbmvwAccounts]
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
SELECT DISTINCT
	HostCompany	= o.company_code,
	AcctCode	= c.account_code,
	Description	= c.account_description,
	Actual		= 1,
	Budget		= 1,
	Statistical	= 1,
	Active		= (1 - c.inactive_flag),
	CreditBal		= ISNULL((SELECT 1 WHERE c.account_type >= 200 AND c.account_type <= 449 OR c.account_type = 600),0),
        	ActiveDate	= c.active_date,
        	InactiveDate    	= c.inactive_date,
	Acct_Dim1	= CASE WHEN r.account_mask IS NULL THEN 0 WHEN r2.reference_flag = 1 THEN 0 ELSE 1 END
	
FROM	glco o 
	LEFT JOIN glchart c ON (1=1) 
	LEFT JOIN glrefact r ON (c.account_code LIKE r.account_mask and r.reference_flag > 1)
	LEFT JOIN glrefact r2 ON (c.account_code LIKE r2.account_mask and r2.reference_flag = 1)
GO
GRANT REFERENCES ON  [dbo].[mbbmvwAccounts] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwAccounts] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmvwAccounts] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmvwAccounts] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmvwAccounts] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwAccounts] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmvwAccounts] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmvwAccounts] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmvwAccounts] TO [public]
GO

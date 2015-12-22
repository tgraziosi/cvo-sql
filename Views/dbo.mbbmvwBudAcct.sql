SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE VIEW [dbo].[mbbmvwBudAcct]
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
SELECT  HostCompany	= company_code,
	AcctCode	= account_code,
	Description	= account_description,
	Active		= (1 - inactive_flag),
	CreditBal	= isnull((SELECT 1 WHERE c.account_type >= 200 AND c.account_type <= 449 OR c.account_type = 600),0),
        ActiveDate      = active_date,
        InactiveDate    = inactive_date,
	Acct_Dim1	= 1
FROM    glchart c, glco
GO
GRANT REFERENCES ON  [dbo].[mbbmvwBudAcct] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwBudAcct] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmvwBudAcct] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmvwBudAcct] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmvwBudAcct] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwBudAcct] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmvwBudAcct] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmvwBudAcct] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmvwBudAcct] TO [public]
GO

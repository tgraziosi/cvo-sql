SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE VIEW [dbo].[mbbmvwActAcct]
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
	--This worked fine in Sybase, not efficiently in SQL Server 6.5 sp3
	--Note that this was not used in PSQL since PSQL sp's bypass this view and go direct to glchart
	--It's left here because the USL view includes this column
	CreditBal	= isnull((SELECT 1 WHERE c.account_type >= 200 AND c.account_type <= 449 OR c.account_type = 600),0),
        ActiveDate      = active_date,
        InactiveDate    = inactive_date,
	Acct_Dim1	= 1
FROM    glchart c, glco
GO
GRANT REFERENCES ON  [dbo].[mbbmvwActAcct] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwActAcct] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmvwActAcct] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmvwActAcct] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmvwActAcct] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwActAcct] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmvwActAcct] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmvwActAcct] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmvwActAcct] TO [public]
GO

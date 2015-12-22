SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE VIEW [dbo].[mbbmvwPeriods] 
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
SELECT  HostCompany = c.company_code,

	CONVERT(smallint,
		(SELECT count(DISTINCT b.period_start_date) 
			FROM glprd b
			WHERE b.period_start_date <= a.period_end_date
				AND b.period_type = 1001)-
			(SELECT count(DISTINCT b.period_start_date)
				FROM glprd b, glco c
				WHERE b.period_start_date <= c.period_end_date
					AND b.period_type = 1001)) 'YearNumber',

	(SELECT max(b.period_start_date)
		FROM glprd b
		WHERE b.period_start_date <= a.period_start_date
			AND b.period_type = 1001) 'YearStartDate',
	(SELECT min(b.period_end_date)
		FROM glprd b
		WHERE b.period_end_date >= a.period_end_date
			AND b.period_type = 1003) 'YearEndDate',
	CONVERT(smallint, 
		(SELECT count(*) 
			FROM glprd b
			WHERE b.period_start_date >= 
				(SELECT max(c.period_start_date)
					FROM glprd c
					WHERE c.period_start_date <= a.period_start_date
						AND c.period_type = 1001)
				AND b.period_start_date <= a.period_start_date)) 'PeriodNumber',        
	a.period_start_date 'PeriodStartDate', 
	a.period_end_date 'PeriodEndDate', 
	a.period_description 'PeriodDescription'
	FROM glprd a, glco c
GO
GRANT REFERENCES ON  [dbo].[mbbmvwPeriods] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwPeriods] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmvwPeriods] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmvwPeriods] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmvwPeriods] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwPeriods] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmvwPeriods] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmvwPeriods] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmvwPeriods] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
create procedure [dbo].[mbbmspWebPeriodList] 
   @HostCompany varchar(8)
WITH ENCRYPTION 
AS
BEGIN
/************************************************************************************
* Copyright 2008 Sage Software, Inc. All rights reserved.                           *
* This procedure, trigger or view is the intellectual property of Sage Software,    *
* Inc.  You may not reverse engineer, alter, or redistribute this code without the  *
* express written permission of Sage Software, Inc.  This code, or any portions of  *
* it, may not be used for any other purpose except for the use of the application   *
* software that it was shipped with.  This code falls under the licensing agreement *
* shipped with the software.  See your license agreement for further information.   *
************************************************************************************/
DECLARE @CurrentPeriod int
select @CurrentPeriod = period_end_date from glco where company_code = @HostCompany

SELECT HostCompany, YearNumber, DATEADD(dd,YearStartDate-693596,'1/1/1900') YearStartDate, 
   DATEADD(dd,YearEndDate-693596,'1/1/1900') YearEndDate, PeriodNumber, 
   DATEADD(dd,PeriodStartDate-693596,'1/1/1900') PeriodStartDate, 
   DATEADD(dd,PeriodEndDate-693596,'1/1/1900') PeriodEndDate, PeriodDescription , DATEADD(dd,@CurrentPeriod-693596,'1/1/1900') CurrentFiscalDate
FROM mbbmvwPeriods 
WHERE HostCompany = @HostCompany
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspWebPeriodList] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspWebPeriodList] TO [public]
GO

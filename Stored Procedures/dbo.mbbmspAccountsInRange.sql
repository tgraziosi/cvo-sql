SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspAccountsInRange]
	@HostCompany	mbbmudtCompanyCode,
	@FromAcct       mbbmudtAccountCode,
	@ThruAcct       mbbmudtAccountCode,
	@InclInactive   mbbmudtYesNo,
        @ProcessDate    mbbmudtAppDate 

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
	--Given an account range, return result set of all posting accounts
	--within range.  Optionally exclude inactive accounts
        --if date is zero, ignores dates but pays attention to flag

	DECLARE @Seg1Pos smallint, @Seg1Len smallint
	DECLARE @Seg2Pos smallint, @Seg2Len smallint
	DECLARE @Seg3Pos smallint, @Seg3Len smallint
	DECLARE @Seg4Pos smallint, @Seg4Len smallint

	DECLARE @FromSeg1 mbbmudtAccountCode, @ThruSeg1 mbbmudtAccountCode
	DECLARE @FromSeg2 mbbmudtAccountCode, @ThruSeg2 mbbmudtAccountCode
	DECLARE @FromSeg3 mbbmudtAccountCode, @ThruSeg3 mbbmudtAccountCode
	DECLARE @FromSeg4 mbbmudtAccountCode, @ThruSeg4 mbbmudtAccountCode

	DECLARE @AccountCount int
	
	
	SELECT @Seg1Pos = start_col, @Seg1Len = length FROM glaccdef WHERE      acct_level = 1
	SELECT @Seg2Pos = start_col, @Seg2Len = length - start_col + 1 FROM glaccdef WHERE acct_level = 2
	SELECT @Seg3Pos = start_col, @Seg3Len = length - start_col + 1 FROM glaccdef WHERE acct_level = 3
	SELECT @Seg4Pos = start_col, @Seg4Len = length - start_col + 1 FROM glaccdef WHERE acct_level = 4

	SELECT  @FromSeg1 = SUBSTRING(@FromAcct, @Seg1Pos, @Seg1Len),
		@ThruSeg1 = SUBSTRING(@ThruAcct, @Seg1Pos, @Seg1Len),
		@FromSeg2 = ISNULL(SUBSTRING(@FromAcct, @Seg2Pos, @Seg2Len), ''),
		@ThruSeg2 = ISNULL(SUBSTRING(@ThruAcct, @Seg2Pos, @Seg2Len), ''),
		@FromSeg3 = ISNULL(SUBSTRING(@FromAcct, @Seg3Pos, @Seg3Len), ''),
		@ThruSeg3 = ISNULL(SUBSTRING(@ThruAcct, @Seg3Pos, @Seg3Len), ''),
		@FromSeg4 = ISNULL(SUBSTRING(@FromAcct, @Seg4Pos, @Seg4Len), ''),
		@ThruSeg4 = ISNULL(SUBSTRING(@ThruAcct, @Seg4Pos, @Seg4Len), '')

	SELECT @AccountCount = count(account_code)
		FROM    glchart
		WHERE   seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
			AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
			AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
			AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
			AND ((@InclInactive = 1) or ((glchart.inactive_flag = 0) and ((@ProcessDate = 0) or ((@ProcessDate >= glchart.active_date) and ((@ProcessDate <= glchart.inactive_date) or (glchart.inactive_date = 0))))))	

	SELECT  @AccountCount, 
		account_code, 
		account_description, 
		1 CreditBal 
		FROM    glchart
		WHERE   seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
			AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
			AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
			AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
			AND (account_type BETWEEN 200 AND 450 OR account_type = 600)
			AND ((@InclInactive = 1) or ((glchart.inactive_flag = 0) and ((@ProcessDate = 0) or ((@ProcessDate >= glchart.active_date) and ((@ProcessDate <= glchart.inactive_date) or (glchart.inactive_date = 0))))))	
	UNION
	SELECT  @AccountCount, 
		account_code, 
		account_description, 
		0 CreditBal 
		FROM    glchart
		WHERE   seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
			AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
			AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
			AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
			AND NOT (account_type BETWEEN 200 AND 450 OR account_type = 600)
			AND ((@InclInactive = 1) or ((glchart.inactive_flag = 0) and ((@ProcessDate = 0) or ((@ProcessDate >= glchart.active_date) and ((@ProcessDate <= glchart.inactive_date) or (glchart.inactive_date = 0))))))
	ORDER BY account_code

END
GO
GRANT EXECUTE ON  [dbo].[mbbmspAccountsInRange] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspAccountsInRange] TO [public]
GO

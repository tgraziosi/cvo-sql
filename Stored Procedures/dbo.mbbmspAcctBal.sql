SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspAcctBal]
	@FromAcct	mbbmudtAccountCode,
	@ThruAcct	mbbmudtAccountCode,
	@RefType	varchar(32),
	@BalType	tinyint,
	@BalCode	varchar(16),
	@InclUnposted	tinyint,
	@ValMethod	tinyint,
	@Currency	mbbmudtCurrencyCode,
	@HomeNat	tinyint,
	@FromPerBegDate	int,
	@FromPerEndDate	int,
	@ThruPerEndDate	int,
	@FromRefCode	varchar(32),
	@ThruRefCode	varchar(32),
	@Bal		float                   OUTPUT
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
	DECLARE @FromCurrency   mbbmudtCurrencyCode,
		@ThruCurrency   mbbmudtCurrencyCode,

		@Seg1Pos smallint, @Seg1Len smallint,
		@Seg2Pos smallint, @Seg2Len smallint,
		@Seg3Pos smallint, @Seg3Len smallint,
		@Seg4Pos smallint, @Seg4Len smallint,

		@FromSeg1 mbbmudtAccountCode, @ThruSeg1 mbbmudtAccountCode,
		@FromSeg2 mbbmudtAccountCode, @ThruSeg2 mbbmudtAccountCode,
		@FromSeg3 mbbmudtAccountCode, @ThruSeg3 mbbmudtAccountCode,
		@FromSeg4 mbbmudtAccountCode, @ThruSeg4 mbbmudtAccountCode

	DECLARE @TestCode varchar(32)
	DECLARE @RefCodeCount int
	DECLARE @RefTypeCount int
	DECLARE @UseCodeOrType smallint

	DECLARE @TempBal float
	DECLARE @TestAcct mbbmudtAccountCode
	DECLARE @TestRefCode varchar(32)
	DECLARE @TestDate int 
	DECLARE @TestYearEndDate int 
	DECLARE @TestYearStartDate int 

	IF (LTrim(RTrim(ISNULL(@FromRefCode,''))) <> '') OR 
	   (LTrim(RTrim(ISNULL(@ThruRefCode,''))) <> '') BEGIN
		SELECT @UseCodeOrType = 1
	END
	ELSE BEGIN
		SELECT @TestCode = LTrim(RTrim(ISNULL(@RefType,'')))
		IF @TestCode = '' BEGIN
			SELECT @UseCodeOrType = 0
		END
		ELSE BEGIN
			SELECT @RefTypeCount = (SELECT COUNT(*) FROM glref WHERE reference_type = @TestCode)
			IF @RefTypeCount > 0 BEGIN
				SELECT @UseCodeOrType = 2
			END
		END
	END

	IF @Currency = '*'
		SELECT  @FromCurrency = min(currency_code), @ThruCurrency = max(currency_code) from glbal
	ELSE
		SELECT  @FromCurrency = @Currency, @ThruCurrency = @Currency

	IF @FromAcct = @ThruAcct AND @FromRefCode = @ThruRefCode BEGIN
		IF @BalType = 0 BEGIN -- Actual
			IF @HomeNat = 0 BEGIN --Home
				IF @UseCodeOrType = 0 BEGIN --no ref code
					IF @ValMethod = 1 BEGIN -- Beginning
						SELECT 	@Bal = ISNULL(SUM(home_current_balance), 0)
						FROM   	glbal
						WHERE  balance_type = 1
							AND balance_date <= @FromPerBegDate
							AND balance_until >= @FromPerBegDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND account_code = @FromAcct
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						-- using net change here, faster if no ref code only
						SELECT	@Bal = ISNULL(SUM(home_net_change), 0)
						FROM   	glbal
						WHERE  balance_type = 1
							AND balance_date >= @FromPerEndDate
							AND balance_date <= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND account_code = @FromAcct

						IF @InclUnposted = 1 BEGIN
							SELECT 	@Bal = @Bal + ISNULL(SUM(balance), 0)
							FROM   	gltrxdet a,
								gltrx_all b
							WHERE  a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct						
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						SELECT	@Bal = ISNULL(SUM(home_current_balance), 0)
						FROM   	glbal
						WHERE  balance_type = 1
							AND balance_date <= @ThruPerEndDate
							AND balance_until >= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND account_code = @FromAcct

						IF @InclUnposted = 1BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance), 0)
							FROM  	gltrxdet a,
								gltrx_all b
							WHERE  a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct
						END
					END
				END
				ELSE IF @UseCodeOrType = 1 BEGIN --by ref code
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
						  	SELECT	@Bal = ISNULL(SUM(balance), 0)
							FROM    	gltrxdet a,
								gltrx_all b
							WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied < @FromPerBegDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = @FromRefCode
	
							IF @InclUnposted = 1 BEGIN
								SELECT	@Bal = @Bal + ISNULL(SUM(balance), 0)
								FROM    	gltrxdet a,
									gltrx_all b
								WHERE  a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct						
									AND a.reference_code = @FromRefCode
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
					  	SELECT	@Bal = ISNULL(SUM(balance), 0)
						FROM    	gltrxdet a,
							gltrx_all b
						WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
							AND b.date_applied >= @FromPerBegDate
							AND b.date_applied <= @ThruPerEndDate
							AND a.nat_cur_code >= @FromCurrency
							AND a.nat_cur_code <= @ThruCurrency
							AND a.posted_flag = 1
							AND a.account_code = @FromAcct
							AND a.reference_code = @FromRefCode

						IF @InclUnposted = 1 BEGIN
							SELECT	@Bal = @Bal + ISNULL(SUM(balance), 0)
							FROM    	gltrxdet a,
								gltrx_all b
							WHERE  a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct						
								AND a.reference_code = @FromRefCode
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
						  	SELECT	@Bal = ISNULL(SUM(balance), 0)
							FROM    	gltrxdet a,
								gltrx_all b
							WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = @FromRefCode
	
							IF @InclUnposted = 1 BEGIN
								SELECT	@Bal = @Bal + ISNULL(SUM(balance), 0)
								FROM    	gltrxdet a,
									gltrx_all b
								WHERE  a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct						
									AND a.reference_code = @FromRefCode
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
				END
				ELSE IF @UseCodeOrType = 2 BEGIN --by ref type
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT	@Bal = ISNULL(SUM(balance), 0)
							FROM  	gltrxdet a,
								gltrx_all b,
								glref c
							WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied < @FromPerBegDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = c.reference_code

							IF @InclUnposted = 1 BEGIN
								SELECT	@Bal = @Bal + ISNULL(SUM(balance), 0)
								FROM   	gltrxdet a,
									gltrx_all b,
									glref c
								WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct						
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0	
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						SELECT	@Bal = ISNULL(SUM(balance), 0)
						FROM  	gltrxdet a,
							gltrx_all b,
							glref c
						WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
							AND c.reference_type = @RefType
							AND b.date_applied >= @FromPerBegDate
							AND b.date_applied <= @ThruPerEndDate
							AND a.nat_cur_code >= @FromCurrency
							AND a.nat_cur_code <= @ThruCurrency
							AND a.posted_flag = 1
							AND a.account_code = @FromAcct
							AND a.reference_code = c.reference_code

						IF @InclUnposted = 1 BEGIN
							SELECT	@Bal = @Bal + ISNULL(SUM(balance), 0)
							FROM   	gltrxdet a,
								gltrx_all b,
								glref c
							WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct						
								AND a.reference_code = c.reference_code
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT	@Bal = ISNULL(SUM(balance), 0)
							FROM  	gltrxdet a,
								gltrx_all b,
								glref c
							WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = c.reference_code

							IF @InclUnposted = 1 BEGIN
								SELECT	@Bal = @Bal + ISNULL(SUM(balance), 0)
								FROM   	gltrxdet a,
									gltrx_all b,
									glref c
								WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct						
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0			
						END
					END
				END
			END
			ELSE IF @HomeNat = 1 BEGIN -- Natural
				IF @UseCodeOrType = 0 BEGIN --no ref code
					IF @ValMethod = 1 BEGIN -- Beginning
						SELECT	@Bal = ISNULL(SUM(current_balance), 0)
						FROM    glbal
						WHERE 	balance_type = 1
							AND balance_date <= @FromPerBegDate
							AND balance_until >= @FromPerBegDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND account_code = @FromAcct
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						-- using net change here, faster if no ref code only
						SELECT	@Bal = ISNULL(SUM(net_change), 0)
						FROM    glbal
						WHERE 	balance_type = 1
							AND balance_date >= @FromPerEndDate
							AND balance_date <= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND account_code = @FromAcct

						IF @InclUnposted = 1 BEGIN
							SELECT	@Bal = @Bal + ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE  a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct						
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						SELECT  @Bal = ISNULL(SUM(current_balance), 0)
						FROM    	glbal
						WHERE  balance_type = 1
							AND balance_date <= @ThruPerEndDate
							AND balance_until >= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND account_code = @FromAcct

						IF @InclUnposted = 1 BEGIN
							SELECT	@Bal = @Bal + ISNULL(SUM(nat_balance), 0)
							FROM    	gltrxdet a,
								gltrx_all b
							WHERE  a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct
						END
					END
				END
				ELSE IF @UseCodeOrType = 1 BEGIN --by ref code
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
						  	SELECT 	@Bal = ISNULL(SUM(nat_balance), 0)
							FROM    	gltrxdet a,
								gltrx_all b
							WHERE  a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied < @FromPerBegDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = @FromRefCode
	
							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct						
									AND a.reference_code = @FromRefCode
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
					  	SELECT   @Bal = ISNULL(SUM(nat_balance), 0)
						FROM    gltrxdet a,
							gltrx_all b
						WHERE   a.journal_ctrl_num = b.journal_ctrl_num
							AND b.date_applied >= @FromPerBegDate
							AND b.date_applied <= @ThruPerEndDate
							AND a.nat_cur_code >= @FromCurrency
							AND a.nat_cur_code <= @ThruCurrency
							AND a.posted_flag = 1
							AND a.account_code = @FromAcct
							AND a.reference_code = @FromRefCode

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct						
								AND a.reference_code = @FromRefCode
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
						  	SELECT   @Bal = ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = @FromRefCode
	
							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct						
									AND a.reference_code = @FromRefCode
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0	
						END
					END
				END
				ELSE IF @UseCodeOrType = 2 BEGIN --by ref type
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT   @Bal = ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied < @FromPerBegDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = c.reference_code

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
								FROM    gltrxdet a,
									gltrx_all b,
									glref c
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct						
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						SELECT   @Bal = ISNULL(SUM(nat_balance), 0)
						FROM    gltrxdet a,
							gltrx_all b,
							glref c
						WHERE   a.journal_ctrl_num = b.journal_ctrl_num
							AND c.reference_type = @RefType
							AND b.date_applied >= @FromPerBegDate
							AND b.date_applied <= @ThruPerEndDate
							AND a.nat_cur_code >= @FromCurrency
							AND a.nat_cur_code <= @ThruCurrency
							AND a.posted_flag = 1
							AND a.account_code = @FromAcct
							AND a.reference_code = c.reference_code

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct						
								AND a.reference_code = c.reference_code
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT   @Bal = ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = c.reference_code

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
								FROM    gltrxdet a,
									gltrx_all b,
									glref c
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct						
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END	
				END
			END
			ELSE BEGIN -- Operating
				IF @UseCodeOrType = 0 BEGIN --no ref code
					IF @ValMethod = 1 BEGIN -- Beginning
						SELECT  @Bal = ISNULL(SUM(current_balance_oper), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date <= @FromPerBegDate
							AND balance_until >= @FromPerBegDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND account_code = @FromAcct
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						SELECT  @Bal = ISNULL(SUM(net_change_oper), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date >= @FromPerEndDate
							AND balance_date <= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND account_code = @FromAcct

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						SELECT  @Bal = ISNULL(SUM(current_balance_oper), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date <= @ThruPerEndDate
							AND balance_until >= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND account_code = @FromAcct

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct
						END
					END
				END
				ELSE IF @UseCodeOrType = 1 BEGIN --by ref code
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT  @Bal = ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied < @FromPerBegDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = @FromRefCode
	
							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct
									AND a.reference_code = @FromRefCode
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						SELECT  @Bal = ISNULL(SUM(balance_oper), 0)
						FROM    gltrxdet a,
							gltrx_all b
						WHERE   a.journal_ctrl_num = b.journal_ctrl_num
							AND b.date_applied >= @FromPerBegDate
							AND b.date_applied <= @ThruPerEndDate
							AND a.nat_cur_code >= @FromCurrency
							AND a.nat_cur_code <= @ThruCurrency
							AND a.posted_flag = 1
							AND a.account_code = @FromAcct
							AND a.reference_code = @FromRefCode

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct
								AND a.reference_code = @FromRefCode
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT  @Bal = ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = @FromRefCode
	
							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct
									AND a.reference_code = @FromRefCode
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
				END
				ELSE IF @UseCodeOrType = 2 BEGIN --by ref type
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT   @Bal = ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied < @FromPerBegDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = c.reference_code

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
								FROM    gltrxdet a,
									gltrx_all b,
									glref c
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct						
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						SELECT   @Bal = ISNULL(SUM(balance_oper), 0)
						FROM    gltrxdet a,
							gltrx_all b,
							glref c
						WHERE   a.journal_ctrl_num = b.journal_ctrl_num
							AND c.reference_type = @RefType
							AND b.date_applied >= @FromPerBegDate
							AND b.date_applied <= @ThruPerEndDate
							AND a.nat_cur_code >= @FromCurrency
							AND a.nat_cur_code <= @ThruCurrency
							AND a.posted_flag = 1
							AND a.account_code = @FromAcct
							AND a.reference_code = c.reference_code

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.account_code = @FromAcct						
								AND a.reference_code = c.reference_code
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT   @Bal = ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.account_code = @FromAcct
								AND a.reference_code = c.reference_code

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
								FROM    gltrxdet a,
									gltrx_all b,
									glref c
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.account_code = @FromAcct						
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END	
				END
			END
		END
		ELSE IF @BalType = 1 BEGIN -- Budget
			IF @UseCodeOrType = 0 BEGIN --no ref code
				IF @ValMethod = 1 BEGIN -- Beginning
					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					-- get closest period at or above asking date for fiscal year
					SELECT 	@TestDate = MIN(period_end_date)
					FROM 	glbuddet
					WHERE 	budget_code = @BalCode
						AND period_end_date >= @FromPerEndDate
						AND period_end_date <= @TestYearEndDate
						AND account_code = @FromAcct

					IF @TestDate IS NOT NULL BEGIN
						SELECT	@Bal = ISNULL(SUM(current_balance-net_change), 0)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date = @TestDate
							AND account_code = @FromAcct
					END
					ELSE BEGIN --try other direction
						-- get closest period below asking date for fiscal year
						SELECT	@TestDate = MAX(period_end_date)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date < @FromPerEndDate
							AND period_end_date >= @TestYearStartDate
							AND account_code = @FromAcct
				
						IF @TestDate IS NOT NULL BEGIN
							SELECT	@Bal = ISNULL(SUM(current_balance), 0)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @FromAcct
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END	
					END
				END
				ELSE IF @ValMethod = 2 -- Change
					SELECT  @Bal = ISNULL(SUM(net_change), 0)
					FROM    glbuddet
					WHERE   budget_code = @BalCode
						AND period_end_date >= @FromPerEndDate
						AND period_end_date <= @ThruPerEndDate
						AND account_code = @FromAcct
				ELSE IF @ValMethod = 3 BEGIN -- Ending
					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)
	
					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)
	
					-- get closest period at or below asking date for fiscal year
					SELECT 	@TestDate = MAX(period_end_date)
					FROM 	glbuddet
					WHERE 	budget_code = @BalCode
						AND period_end_date <= @ThruPerEndDate
						AND period_end_date >= @TestYearStartDate
						AND account_code = @FromAcct

					IF @TestDate IS NOT NULL BEGIN
						SELECT	@Bal = ISNULL(SUM(current_balance), 0)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date = @TestDate
							AND account_code = @FromAcct
					END
					ELSE BEGIN --try other direction
						-- get closest period above asking date for fiscal year
						SELECT	@TestDate = MIN(period_end_date)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date > @ThruPerEndDate
							AND period_end_date <= @TestYearEndDate
							AND account_code = @FromAcct
				
						IF @TestDate IS NOT NULL BEGIN
							SELECT	@Bal = ISNULL(SUM(current_balance-net_change), 0)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @FromAcct
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END	
					END
				END
			END
			ELSE IF @UseCodeOrType = 1 BEGIN --by ref code
				IF @ValMethod = 1 BEGIN -- Beginning
					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					-- get closest period at or above asking date for fiscal year
					SELECT 	@TestDate = MIN(period_end_date)
					FROM 	glbuddet
					WHERE 	budget_code = @BalCode
						AND period_end_date >= @FromPerEndDate
						AND period_end_date <= @TestYearEndDate
						AND account_code = @FromAcct
						AND reference_code = @FromRefCode

					IF @TestDate IS NOT NULL BEGIN
						SELECT	@Bal = ISNULL(SUM(current_balance-net_change), 0)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date = @TestDate
							AND account_code = @FromAcct
							AND reference_code = @FromRefCode
					END
					ELSE BEGIN --try other direction
						-- get closest period below asking date for fiscal year
						SELECT	@TestDate = MAX(period_end_date)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date < @FromPerEndDate
							AND period_end_date >= @TestYearStartDate
							AND account_code = @FromAcct
							AND reference_code = @FromRefCode
				
						IF @TestDate IS NOT NULL BEGIN
							SELECT	@Bal = ISNULL(SUM(current_balance), 0)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @FromAcct
								AND reference_code = @FromRefCode
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END	
					END
				END
				ELSE IF @ValMethod = 2 -- Change
					SELECT  @Bal = ISNULL(SUM(net_change), 0)
					FROM    glbuddet
					WHERE   budget_code = @BalCode
						AND period_end_date >= @FromPerEndDate
						AND period_end_date <= @ThruPerEndDate
						AND account_code = @FromAcct
						AND reference_code = @FromRefCode
				ELSE IF @ValMethod = 3 BEGIN -- Ending
					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)
	
					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)
	
					-- get closest period at or below asking date for fiscal year
					SELECT 	@TestDate = MAX(period_end_date)
					FROM 	glbuddet
					WHERE 	budget_code = @BalCode
						AND period_end_date <= @ThruPerEndDate
						AND period_end_date >= @TestYearStartDate
						AND account_code = @FromAcct
						AND reference_code = @FromRefCode

					IF @TestDate IS NOT NULL BEGIN
						SELECT	@Bal = ISNULL(SUM(current_balance), 0)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date = @TestDate
							AND account_code = @FromAcct
							AND reference_code = @FromRefCode
					END
					ELSE BEGIN --try other direction
						-- get closest period above asking date for fiscal year
						SELECT	@TestDate = MIN(period_end_date)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date > @ThruPerEndDate
							AND period_end_date <= @TestYearEndDate
							AND account_code = @FromAcct
							AND reference_code = @FromRefCode
				
						IF @TestDate IS NOT NULL BEGIN
							SELECT	@Bal = ISNULL(SUM(current_balance-net_change), 0)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @FromAcct
								AND reference_code = @FromRefCode
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END	
					END
				END
			END
			IF @UseCodeOrType = 2 BEGIN --by ref type
				IF @ValMethod = 1 BEGIN -- Beginning
					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					-- get closest period at or above asking date for fiscal year
					SELECT 	@TestDate = MIN(b.period_end_date)
					FROM 	glbuddet b, glref c
					WHERE 	b.budget_code = @BalCode
						AND b.period_end_date >= @FromPerEndDate
						AND b.period_end_date <= @TestYearEndDate
						AND b.account_code = @FromAcct
						AND c.reference_type = @RefType
						AND b.reference_code = c.reference_code

					IF @TestDate IS NOT NULL BEGIN
						SELECT	@Bal = ISNULL(SUM(b.current_balance-b.net_change), 0)
						FROM 	glbuddet b, glref c
						WHERE 	b.budget_code = @BalCode
							AND b.period_end_date = @TestDate
							AND b.account_code = @FromAcct
							AND c.reference_type = @RefType
							AND b.reference_code = c.reference_code
					END
					ELSE BEGIN --try other direction
						-- get closest period below asking date for fiscal year
						SELECT	@TestDate = MAX(b.period_end_date)
						FROM 	glbuddet b, glref c
						WHERE 	b.budget_code = @BalCode
							AND b.period_end_date < @FromPerEndDate
							AND b.period_end_date >= @TestYearStartDate
							AND b.account_code = @FromAcct
							AND c.reference_type = @RefType
							AND b.reference_code = c.reference_code
				
						IF @TestDate IS NOT NULL BEGIN
							SELECT	@Bal = ISNULL(SUM(b.current_balance), 0)
							FROM 	glbuddet b, glref c
							WHERE 	b.budget_code = @BalCode
								AND b.period_end_date = @TestDate
								AND b.account_code = @FromAcct
								AND c.reference_type = @RefType
								AND b.reference_code = c.reference_code
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END	
					END
				END
				ELSE IF @ValMethod = 2 -- Change
					SELECT  @Bal = ISNULL(SUM(b.net_change), 0)
					FROM    glbuddet b, glref c
					WHERE  b.budget_code = @BalCode
						AND b.period_end_date >= @FromPerEndDate
						AND b.period_end_date <= @ThruPerEndDate
						AND b.account_code = @FromAcct
						AND c.reference_type = @RefType
						AND b.reference_code = c.reference_code

				ELSE IF @ValMethod = 3 BEGIN -- Ending
					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)
	
					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)
	
					-- get closest period at or below asking date for fiscal year
					SELECT 	@TestDate = MAX(b.period_end_date)
					FROM 	glbuddet b, glref c
					WHERE 	b.budget_code = @BalCode
						AND b.period_end_date <= @ThruPerEndDate
						AND b.period_end_date >= @TestYearStartDate
						AND b.account_code = @FromAcct
						AND c.reference_type = @RefType
						AND b.reference_code = c.reference_code

					IF @TestDate IS NOT NULL BEGIN
						SELECT	@Bal = ISNULL(SUM(b.current_balance), 0)
						FROM 	glbuddet b, glref c
						WHERE 	b.budget_code = @BalCode
							AND b.period_end_date = @TestDate
							AND b.account_code = @FromAcct
							AND c.reference_type = @RefType
							AND b.reference_code = c.reference_code
					END
					ELSE BEGIN --try other direction
						-- get closest period above asking date for fiscal year
						SELECT	@TestDate = MIN(b.period_end_date)
						FROM 	glbuddet b, glref c
						WHERE 	b.budget_code = @BalCode
							AND b.period_end_date > @ThruPerEndDate
							AND b.period_end_date <= @TestYearEndDate
							AND b.account_code = @FromAcct
							AND c.reference_type = @RefType
							AND b.reference_code = c.reference_code
				
						IF @TestDate IS NOT NULL BEGIN
							SELECT	@Bal = ISNULL(SUM(b.current_balance-b.net_change), 0)
							FROM 	glbuddet b, glref c
							WHERE 	b.budget_code = @BalCode
								AND b.period_end_date = @TestDate
								AND b.account_code = @FromAcct
								AND c.reference_type = @RefType
								AND b.reference_code = c.reference_code
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END	
					END
				END
			END
		END
		ELSE IF @BalType = 2 BEGIN -- Statistical
			IF @ValMethod = 1 BEGIN -- Beginning
				--get end of fiscal year	
				SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
					 	     FROM 	mbbmvwPeriods
						     WHERE	YearStartDate <= @FromPerEndDate
								AND YearEndDate >= @FromPerEndDate)

				-- get start of fiscal year
				SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
					 	     FROM 	mbbmvwPeriods
						     WHERE	YearStartDate <= @FromPerEndDate
								AND YearEndDate >= @FromPerEndDate)

				-- get closest period at or above asking date for fiscal year
				SELECT 	@TestDate = MIN(period_end_date)
				FROM 	glnofind
				WHERE 	nonfin_budget_code = @BalCode
					AND period_end_date >= @FromPerEndDate
					AND period_end_date <= @TestYearEndDate
					AND account_code = @FromAcct

				IF @TestDate IS NOT NULL BEGIN
					SELECT	@Bal = ISNULL(SUM(ytd_quantity - quantity), 0)
					FROM 	glnofind
					WHERE 	nonfin_budget_code = @BalCode
						AND period_end_date = @TestDate
						AND account_code = @FromAcct
				END
				ELSE BEGIN --try other direction
					-- get closest period below asking date for fiscal year
					SELECT	@TestDate = MAX(period_end_date)
					FROM 	glnofind
					WHERE 	nonfin_budget_code = @BalCode
						AND period_end_date < @FromPerEndDate
						AND period_end_date >= @TestYearStartDate
						AND account_code = @FromAcct
				
					IF @TestDate IS NOT NULL BEGIN
						SELECT	@Bal = ISNULL(SUM(ytd_quantity), 0)
						FROM 	glnofind
						WHERE 	nonfin_budget_code = @BalCode
							AND period_end_date = @TestDate
							AND account_code = @FromAcct
					END
					ELSE BEGIN
						SELECT @Bal = 0
					END	
				END
			END
			ELSE IF @ValMethod = 2 -- Change
				SELECT  @Bal = ISNULL(SUM(quantity), 0)
				FROM    glnofind
				WHERE   nonfin_budget_code = @BalCode
					AND period_end_date >= @FromPerEndDate
					AND period_end_date <= @ThruPerEndDate
					AND account_code = @FromAcct
			ELSE IF @ValMethod = 3 BEGIN -- Ending
				--get end of fiscal year	
				SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
					 	     FROM 	mbbmvwPeriods
						     WHERE	YearStartDate <= @ThruPerEndDate
								AND YearEndDate >= @ThruPerEndDate)

				-- get start of fiscal year
				SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
					 	     FROM 	mbbmvwPeriods
						     WHERE	YearStartDate <= @ThruPerEndDate
								AND YearEndDate >= @ThruPerEndDate)

				-- get closest period at or below asking date for fiscal year
				SELECT 	@TestDate = MAX(period_end_date)
				FROM 	glnofind
				WHERE 	nonfin_budget_code = @BalCode
					AND period_end_date <= @ThruPerEndDate
					AND period_end_date >= @TestYearStartDate
					AND account_code = @FromAcct

				IF @TestDate IS NOT NULL BEGIN
					SELECT	@Bal = ISNULL(SUM(ytd_quantity), 0)
					FROM 	glnofind
					WHERE 	nonfin_budget_code = @BalCode
						AND period_end_date = @TestDate
						AND account_code = @FromAcct
				END
				ELSE BEGIN --try other direction
					-- get closest period above asking date for fiscal year
					SELECT	@TestDate = MIN(period_end_date)
					FROM 	glnofind
					WHERE 	nonfin_budget_code = @BalCode
						AND period_end_date > @ThruPerEndDate
						AND period_end_date <= @TestYearEndDate
						AND account_code = @FromAcct
				
					IF @TestDate IS NOT NULL BEGIN
						SELECT	@Bal = ISNULL(SUM(ytd_quantity - quantity), 0)
						FROM 	glnofind
						WHERE 	nonfin_budget_code = @BalCode
							AND period_end_date = @TestDate
							AND account_code = @FromAcct
					END
					ELSE BEGIN
						SELECT @Bal = 0
					END	
				END
			END
		END
	END
	ELSE BEGIN -- Range
		SELECT @Seg1Pos = start_col, @Seg1Len = length FROM glaccdef WHERE acct_level = 1
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

		IF @BalType = 0 BEGIN -- Actual
			IF @HomeNat = 0 BEGIN --Home
				IF @UseCodeOrType = 0 BEGIN --no ref code
					IF @ValMethod = 1 BEGIN -- Beginning
						SELECT  @Bal = ISNULL(SUM(home_current_balance), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date <= @FromPerBegDate
							AND balance_until >= @FromPerBegDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						-- using net change here, faster if no ref code only
						SELECT  @Bal = ISNULL(SUM(home_net_change), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date >= @FromPerEndDate
							AND balance_date <= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						SELECT  @Bal = ISNULL(SUM(home_current_balance), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date <= @ThruPerEndDate
							AND balance_until >= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4

						IF @InclUnposted = 1BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						END
					END
				END
				ELSE IF @UseCodeOrType = 1 BEGIN --by ref code
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
						  	SELECT   @Bal = ISNULL(SUM(balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied < @FromPerBegDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(balance), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
					  	SELECT   @Bal = ISNULL(SUM(balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
						  	SELECT   @Bal = ISNULL(SUM(balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(balance), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
				END
				ELSE IF @UseCodeOrType = 2 BEGIN --by ref type
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT   @Bal = ISNULL(SUM(balance), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied < @FromPerBegDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND a.reference_code = c.reference_code

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(balance), 0)
								FROM    gltrxdet a,
									gltrx_all b,
									glref c
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						SELECT   @Bal = ISNULL(SUM(balance), 0)
						FROM    gltrxdet a,
							gltrx_all b,
							glref c
						WHERE   a.journal_ctrl_num = b.journal_ctrl_num
							AND c.reference_type = @RefType
							AND b.date_applied >= @FromPerBegDate
							AND b.date_applied <= @ThruPerEndDate
							AND a.nat_cur_code >= @FromCurrency
							AND a.nat_cur_code <= @ThruCurrency
							AND a.posted_flag = 1
							AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
							AND a.reference_code = c.reference_code

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND a.reference_code = c.reference_code
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT   @Bal = ISNULL(SUM(balance), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND a.reference_code = c.reference_code

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(balance), 0)
								FROM    gltrxdet a,
									gltrx_all b,
									glref c
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
				END
			END
			ELSE IF @HomeNat = 1 BEGIN -- Natural
				IF @UseCodeOrType = 0 BEGIN --no ref code
					IF @ValMethod = 1BEGIN -- Beginning
						SELECT  @Bal = ISNULL(SUM(current_balance), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date <= @FromPerBegDate
							AND balance_until >= @FromPerBegDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						-- using net change here, faster if no ref code only
						SELECT  @Bal = ISNULL(SUM(net_change), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date >= @FromPerEndDate
							AND balance_date <= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						SELECT  @Bal = ISNULL(SUM(current_balance), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date <= @ThruPerEndDate
							AND balance_until >= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						END
					END
				END
				ELSE IF @UseCodeOrType = 1 BEGIN --by ref code
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
						  	SELECT   @Bal = ISNULL(SUM(nat_balance), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 1
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
					  	SELECT   @Bal = ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
						  	SELECT   @Bal = ISNULL(SUM(nat_balance), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 1
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
				END
				ELSE IF @UseCodeOrType = 2 BEGIN --by ref type
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT   @Bal = ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied < @FromPerBegDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND a.reference_code = c.reference_code

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
								FROM    gltrxdet a,
									gltrx_all b,
									glref c
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						SELECT   @Bal = ISNULL(SUM(nat_balance), 0)
						FROM    gltrxdet a,
							gltrx_all b,
							glref c
						WHERE   a.journal_ctrl_num = b.journal_ctrl_num
							AND c.reference_type = @RefType
							AND b.date_applied >= @FromPerBegDate
							AND b.date_applied <= @ThruPerEndDate
							AND a.nat_cur_code >= @FromCurrency
							AND a.nat_cur_code <= @ThruCurrency
							AND a.posted_flag = 1
							AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
							AND a.reference_code = c.reference_code

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND a.reference_code = c.reference_code
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT   @Bal = ISNULL(SUM(nat_balance), 0)
							FROM    gltrxdet a,
								gltrx_all b,
								glref c
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND a.reference_code = c.reference_code
	
							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance), 0)
								FROM    gltrxdet a,
									gltrx_all b,
									glref c
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
				END
			END
			ELSE BEGIN -- Operating
				IF @UseCodeOrType = 0 BEGIN --no ref code
					IF @ValMethod = 1 BEGIN -- Beginning
						SELECT  @Bal = ISNULL(SUM(current_balance_oper), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date <= @FromPerBegDate
							AND balance_until >= @FromPerBegDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						SELECT  @Bal = ISNULL(SUM(net_change_oper), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date >= @FromPerEndDate
							AND balance_date <= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						SELECT  @Bal = ISNULL(SUM(current_balance_oper), 0)
						FROM    glbal
						WHERE   balance_type = 1
							AND balance_date <= @ThruPerEndDate
							AND balance_until >= @ThruPerEndDate
							AND currency_code >= @FromCurrency
							AND currency_code <= @ThruCurrency
							AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						END
					END
				END
				ELSE IF @UseCodeOrType = 1 BEGIN --by ref code
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
						  	SELECT   @Bal = ISNULL(SUM(balance_oper), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 1
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
					  	SELECT   @Bal = ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))

						IF @InclUnposted = 1 BEGIN
							SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
						  	SELECT   @Bal = ISNULL(SUM(balance_oper), 0)
							FROM    gltrxdet a,
								gltrx_all b
							WHERE   a.journal_ctrl_num = b.journal_ctrl_num
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))

							IF @InclUnposted = 1 BEGIN
								SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper), 0)
								FROM    gltrxdet a,
									gltrx_all b
								WHERE   a.journal_ctrl_num = b.journal_ctrl_num
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND ((a.reference_code BETWEEN @FromRefCode AND @ThruRefCode) OR (@FromRefCode IS NULL AND @ThruRefCode IS NULL))
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
				END
				ELSE IF @UseCodeOrType = 2 BEGIN --by ref type
					IF @ValMethod = 1 BEGIN -- Beginning
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @FromPerBegDate
						AND 	YearEndDate >= @FromPerBegDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT	@Bal = ISNULL(SUM(balance_oper), 0)
							FROM  	gltrxdet a,
								gltrx_all b,
								glref c
							WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied < @FromPerBegDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND a.reference_code = c.reference_code

							IF @InclUnposted = 1 BEGIN
								SELECT	@Bal = @Bal + ISNULL(SUM(balance_oper), 0)
								FROM   	gltrxdet a,
									gltrx_all b,
									glref c
								WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied < @FromPerBegDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
					ELSE IF @ValMethod = 2 BEGIN -- Change
						SELECT	@Bal = ISNULL(SUM(balance_oper), 0)
						FROM  	gltrxdet a,
							gltrx_all b,
							glref c
						WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
							AND c.reference_type = @RefType
							AND b.date_applied >= @FromPerBegDate
							AND b.date_applied <= @ThruPerEndDate
							AND a.nat_cur_code >= @FromCurrency
							AND a.nat_cur_code <= @ThruCurrency
							AND a.posted_flag = 1
							AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
							AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
							AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
							AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
							AND a.reference_code = c.reference_code

						IF @InclUnposted = 1 BEGIN
							SELECT	@Bal = @Bal + ISNULL(SUM(balance_oper), 0)
							FROM   	gltrxdet a,
								gltrx_all b,
								glref c
							WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @FromPerBegDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 0
								AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND a.reference_code = c.reference_code
						END
					END
					ELSE IF @ValMethod = 3 BEGIN -- Ending
						-- get start of fiscal year
						SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						FROM 	mbbmvwPeriods
						WHERE	YearStartDate <= @ThruPerEndDate
						AND 	YearEndDate >= @ThruPerEndDate)

						IF @TestYearStartDate IS NOT NULL BEGIN
							SELECT	@Bal = ISNULL(SUM(balance_oper), 0)
							FROM  	gltrxdet a,
								gltrx_all b,
								glref c
							WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
								AND c.reference_type = @RefType
								AND b.date_applied >= @TestYearStartDate
								AND b.date_applied <= @ThruPerEndDate
								AND a.nat_cur_code >= @FromCurrency
								AND a.nat_cur_code <= @ThruCurrency
								AND a.posted_flag = 1
								AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
								AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
								AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
								AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
								AND a.reference_code = c.reference_code

							IF @InclUnposted = 1 BEGIN
								SELECT	@Bal = @Bal + ISNULL(SUM(balance_oper), 0)
								FROM   	gltrxdet a,
									gltrx_all b,
									glref c
								WHERE 	a.journal_ctrl_num = b.journal_ctrl_num
									AND c.reference_type = @RefType
									AND b.date_applied >= @TestYearStartDate
									AND b.date_applied <= @ThruPerEndDate
									AND a.nat_cur_code >= @FromCurrency
									AND a.nat_cur_code <= @ThruCurrency
									AND a.posted_flag = 0
									AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
									AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
									AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
									AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
									AND a.reference_code = c.reference_code
							END
						END
						ELSE BEGIN
							SELECT @Bal = 0
						END
					END
				END
			END
		END
		ELSE IF @BalType = 1 BEGIN -- Budget
			IF @UseCodeOrType = 0 BEGIN --no ref code

				IF @ValMethod = 1 BEGIN -- Beginning

					SELECT @Bal = 0

					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					DECLARE crsAcct CURSOR FOR

					SELECT  DISTINCT account_code
					FROM    glbuddet
					WHERE   budget_code = @BalCode
						AND period_end_date >= @TestYearStartDate 
						AND period_end_date <= @TestYearEndDate
						AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
						AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
						AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
						AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4

					OPEN    crsAcct
					FETCH   crsAcct
					INTO    @TestAcct

					WHILE (@@FETCH_STATUS = 0) BEGIN

						-- get closest period at or above asking date for fiscal year
						SELECT 	@TestDate = MIN(period_end_date)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date >= @FromPerEndDate
							AND period_end_date <= @TestYearEndDate
							AND account_code = @TestAcct

						IF @TestDate IS NOT NULL BEGIN
							SELECT	@TempBal = ISNULL(SUM(current_balance-net_change), 0)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @TestAcct
						END
						ELSE BEGIN --try other direction
							-- get closest period below asking date for fiscal year
							SELECT	@TestDate = MAX(period_end_date)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date < @FromPerEndDate
								AND period_end_date >= @TestYearStartDate
								AND account_code = @TestAcct
				
							IF @TestDate IS NOT NULL BEGIN
								SELECT	@TempBal = ISNULL(SUM(current_balance), 0)
								FROM 	glbuddet
								WHERE 	budget_code = @BalCode
									AND period_end_date = @TestDate
									AND account_code = @TestAcct
							END
							ELSE BEGIN
								SELECT @TempBal = 0
							END	
						END
						SELECT @Bal = @Bal + @TempBal
	
						FETCH   crsAcct
						INTO    @TestAcct
					END

					CLOSE crsAcct
					DEALLOCATE crsAcct
				END
				ELSE IF @ValMethod = 2 -- Change
					SELECT  @Bal = ISNULL(SUM(net_change), 0)
					FROM    glbuddet
					WHERE   budget_code = @BalCode
						AND period_end_date >= @FromPerEndDate
						AND period_end_date <= @ThruPerEndDate
						AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
						AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
						AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
						AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
				ELSE IF @ValMethod = 3 BEGIN -- Ending

					SELECT @Bal = 0

					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)

					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)

					DECLARE crsAcct CURSOR FOR

					SELECT  DISTINCT account_code
					FROM    glbuddet
					WHERE   budget_code = @BalCode
						AND period_end_date >= @TestYearStartDate 
						AND period_end_date <= @TestYearEndDate
						AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
						AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
						AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
						AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4

					OPEN    crsAcct
					FETCH   crsAcct
					INTO    @TestAcct

					WHILE (@@FETCH_STATUS = 0) BEGIN

						-- get closest period at or below asking date for fiscal year
						SELECT 	@TestDate = MAX(period_end_date)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date <= @ThruPerEndDate
							AND period_end_date >= @TestYearStartDate
							AND account_code = @TestAcct

						IF @TestDate IS NOT NULL BEGIN
							SELECT	@TempBal = ISNULL(SUM(current_balance), 0)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @TestAcct
						END
						ELSE BEGIN --try other direction
							-- get closest period above asking date for fiscal year
							SELECT	@TestDate = MIN(period_end_date)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date > @ThruPerEndDate
								AND period_end_date <= @TestYearEndDate
								AND account_code = @TestAcct
				
							IF @TestDate IS NOT NULL BEGIN
								SELECT	@TempBal = ISNULL(SUM(current_balance-net_change), 0)
								FROM 	glbuddet
								WHERE 	budget_code = @BalCode
									AND period_end_date = @TestDate
									AND account_code = @TestAcct
							END
							ELSE BEGIN
								SELECT @TempBal = 0
							END	
						END
						SELECT @Bal = @Bal + @TempBal
	
						FETCH   crsAcct
						INTO    @TestAcct
					END

					CLOSE crsAcct
					DEALLOCATE crsAcct
				END
			END
			ELSE IF @UseCodeOrType = 1 BEGIN --by ref code

				IF @ValMethod = 1 BEGIN -- Beginning

					SELECT @Bal = 0

					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					DECLARE crsAcct CURSOR FOR

					SELECT  DISTINCT account_code, reference_code
					FROM    glbuddet
					WHERE   budget_code = @BalCode
						AND period_end_date >= @TestYearStartDate 
						AND period_end_date <= @TestYearEndDate
						AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
						AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
						AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
						AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						AND reference_code BETWEEN @FromRefCode AND @ThruRefCode

					OPEN    crsAcct
					FETCH   crsAcct
					INTO    @TestAcct, @TestRefCode

					WHILE (@@FETCH_STATUS = 0) BEGIN

						-- get closest period at or above asking date for fiscal year
						SELECT 	@TestDate = MIN(period_end_date)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date >= @FromPerEndDate
							AND period_end_date <= @TestYearEndDate
							AND account_code = @TestAcct
							AND reference_code = @TestRefCode

						IF @TestDate IS NOT NULL BEGIN
							SELECT	@TempBal = ISNULL(SUM(current_balance-net_change), 0)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @TestAcct
								AND reference_code = @TestRefCode
						END
						ELSE BEGIN --try other direction
							-- get closest period below asking date for fiscal year
							SELECT	@TestDate = MAX(period_end_date)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date < @FromPerEndDate
								AND period_end_date >= @TestYearStartDate
								AND account_code = @TestAcct
								AND reference_code = @TestRefCode
				
							IF @TestDate IS NOT NULL BEGIN
								SELECT	@TempBal = ISNULL(SUM(current_balance), 0)
								FROM 	glbuddet
								WHERE 	budget_code = @BalCode
									AND period_end_date = @TestDate
									AND account_code = @TestAcct
									AND reference_code = @TestRefCode
							END
							ELSE BEGIN
								SELECT @TempBal = 0
							END	
						END
						SELECT @Bal = @Bal + @TempBal
	
						FETCH   crsAcct
						INTO    @TestAcct, @TestRefCode
					END

					CLOSE crsAcct
					DEALLOCATE crsAcct
				END
				ELSE IF @ValMethod = 2 -- Change
					SELECT  @Bal = ISNULL(SUM(net_change), 0)
					FROM    glbuddet
					WHERE   budget_code = @BalCode
						AND period_end_date >= @FromPerEndDate
						AND period_end_date <= @ThruPerEndDate
						AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
						AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
						AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
						AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						AND reference_code BETWEEN @FromRefCode AND @ThruRefCode
				ELSE IF @ValMethod = 3 BEGIN -- Ending

					SELECT @Bal = 0

					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)

					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)

					DECLARE crsAcct CURSOR FOR

					SELECT  DISTINCT account_code, reference_code
					FROM    glbuddet
					WHERE   budget_code = @BalCode
						AND period_end_date >= @TestYearStartDate 
						AND period_end_date <= @TestYearEndDate
						AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
						AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
						AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
						AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						AND reference_code BETWEEN @FromRefCode AND @ThruRefCode

					OPEN    crsAcct
					FETCH   crsAcct
					INTO    @TestAcct, @TestRefCode

					WHILE (@@FETCH_STATUS = 0) BEGIN

						-- get closest period at or below asking date for fiscal year
						SELECT 	@TestDate = MAX(period_end_date)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date <= @ThruPerEndDate
							AND period_end_date >= @TestYearStartDate
							AND account_code = @TestAcct
							AND reference_code = @TestRefCode

						IF @TestDate IS NOT NULL BEGIN
							SELECT	@TempBal = ISNULL(SUM(current_balance), 0)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @TestAcct
								AND reference_code = @TestRefCode
						END
						ELSE BEGIN --try other direction
							-- get closest period above asking date for fiscal year
							SELECT	@TestDate = MIN(period_end_date)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date > @ThruPerEndDate
								AND period_end_date <= @TestYearEndDate
								AND account_code = @TestAcct
								AND reference_code = @TestRefCode
				
							IF @TestDate IS NOT NULL BEGIN
								SELECT	@TempBal = ISNULL(SUM(current_balance-net_change), 0)
								FROM 	glbuddet
								WHERE 	budget_code = @BalCode
									AND period_end_date = @TestDate
									AND account_code = @TestAcct
									AND reference_code = @TestRefCode
							END
							ELSE BEGIN
								SELECT @TempBal = 0
							END	
						END
						SELECT @Bal = @Bal + @TempBal
	
						FETCH   crsAcct
						INTO    @TestAcct, @TestRefCode
					END

					CLOSE crsAcct
					DEALLOCATE crsAcct
				END
			END
			ELSE IF @UseCodeOrType = 2 BEGIN --by ref type

				IF @ValMethod = 1 BEGIN -- Beginning

					SELECT @Bal = 0

					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @FromPerEndDate
									AND YearEndDate >= @FromPerEndDate)

					DECLARE crsAcct CURSOR FOR

					SELECT  DISTINCT b.account_code, b.reference_code
					FROM    glbuddet b, glref c
					WHERE  b.budget_code = @BalCode
						AND b.period_end_date >= @TestYearStartDate 
						AND b.period_end_date <= @TestYearEndDate
						AND b.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
						AND b.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
						AND b.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
						AND b.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						AND c.reference_type = @RefType
						AND b.reference_code = c.reference_code

					OPEN    crsAcct
					FETCH   crsAcct
					INTO    @TestAcct, @TestRefCode

					WHILE (@@FETCH_STATUS = 0) BEGIN

						-- get closest period at or above asking date for fiscal year
						SELECT 	@TestDate = MIN(period_end_date)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date >= @FromPerEndDate
							AND period_end_date <= @TestYearEndDate
							AND account_code = @TestAcct
							AND reference_code = @TestRefCode

						IF @TestDate IS NOT NULL BEGIN
							SELECT	@TempBal = ISNULL(SUM(current_balance-net_change), 0)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @TestAcct
								AND reference_code = @TestRefCode
						END
						ELSE BEGIN --try other direction
							-- get closest period below asking date for fiscal year
							SELECT	@TestDate = MAX(period_end_date)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date < @FromPerEndDate
								AND period_end_date >= @TestYearStartDate
								AND account_code = @TestAcct
								AND reference_code = @TestRefCode
				
							IF @TestDate IS NOT NULL BEGIN
								SELECT	@TempBal = ISNULL(SUM(current_balance), 0)
								FROM 	glbuddet
								WHERE 	budget_code = @BalCode
									AND period_end_date = @TestDate
									AND account_code = @TestAcct
									AND reference_code = @TestRefCode
							END
							ELSE BEGIN
								SELECT @TempBal = 0
							END	
						END
						SELECT @Bal = @Bal + @TempBal
	
						FETCH   crsAcct
						INTO    @TestAcct, @TestRefCode
					END

					CLOSE crsAcct
					DEALLOCATE crsAcct
				END
				ELSE IF @ValMethod = 2 -- Change
					SELECT  @Bal = ISNULL(SUM(b.net_change), 0)
					FROM    glbuddet b, glref c
					WHERE  b.budget_code = @BalCode
						AND b.period_end_date >= @FromPerEndDate
						AND b.period_end_date <= @ThruPerEndDate
						AND b.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
						AND b.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
						AND b.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
						AND b.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						AND c.reference_type = @RefType
						AND b.reference_code = c.reference_code

				ELSE IF @ValMethod = 3 BEGIN -- Ending

					SELECT @Bal = 0

					--get end of fiscal year	
					SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)

					-- get start of fiscal year
					SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
						 	     FROM 	mbbmvwPeriods
							     WHERE	YearStartDate <= @ThruPerEndDate
									AND YearEndDate >= @ThruPerEndDate)

					DECLARE crsAcct CURSOR FOR

					SELECT  DISTINCT b.account_code, b.reference_code
					FROM    glbuddet b, glref c
					WHERE  b.budget_code = @BalCode
						AND b.period_end_date >= @TestYearStartDate 
						AND b.period_end_date <= @TestYearEndDate
						AND b.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
						AND b.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
						AND b.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
						AND b.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
						AND c.reference_type = @RefType
						AND b.reference_code = c.reference_code

					OPEN    crsAcct
					FETCH   crsAcct
					INTO    @TestAcct, @TestRefCode

					WHILE (@@FETCH_STATUS = 0) BEGIN

						-- get closest period at or below asking date for fiscal year
						SELECT 	@TestDate = MAX(period_end_date)
						FROM 	glbuddet
						WHERE 	budget_code = @BalCode
							AND period_end_date <= @ThruPerEndDate
							AND period_end_date >= @TestYearStartDate
							AND account_code = @TestAcct
							AND reference_code = @TestRefCode

						IF @TestDate IS NOT NULL BEGIN
							SELECT	@TempBal = ISNULL(SUM(current_balance), 0)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @TestAcct
								AND reference_code = @TestRefCode
						END
						ELSE BEGIN --try other direction
							-- get closest period above asking date for fiscal year
							SELECT	@TestDate = MIN(period_end_date)
							FROM 	glbuddet
							WHERE 	budget_code = @BalCode
								AND period_end_date > @ThruPerEndDate
								AND period_end_date <= @TestYearEndDate
								AND account_code = @TestAcct
								AND reference_code = @TestRefCode
				
							IF @TestDate IS NOT NULL BEGIN
								SELECT	@TempBal = ISNULL(SUM(current_balance-net_change), 0)
								FROM 	glbuddet
								WHERE 	budget_code = @BalCode
									AND period_end_date = @TestDate
									AND account_code = @TestAcct
									AND reference_code = @TestRefCode
							END
							ELSE BEGIN
								SELECT @TempBal = 0
							END	
						END
						SELECT @Bal = @Bal + @TempBal
	
						FETCH   crsAcct
						INTO    @TestAcct, @TestRefCode
					END

					CLOSE crsAcct
					DEALLOCATE crsAcct
				END
			END
		END
		ELSE IF @BalType = 2 BEGIN -- Statistical
			IF @ValMethod = 1 BEGIN -- Beginning

				SELECT @Bal = 0

				--get end of fiscal year	
				SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
					 	     FROM 	mbbmvwPeriods
						     WHERE	YearStartDate <= @FromPerEndDate
								AND YearEndDate >= @FromPerEndDate)

				-- get start of fiscal year
				SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
					 	     FROM 	mbbmvwPeriods
						     WHERE	YearStartDate <= @FromPerEndDate
								AND YearEndDate >= @FromPerEndDate)

				DECLARE crsAcct CURSOR FOR

				SELECT  DISTINCT account_code
				FROM    glnofind
				WHERE   nonfin_budget_code = @BalCode
					AND period_end_date >= @TestYearStartDate 
					AND period_end_date <= @TestYearEndDate
					AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
					AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
					AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
					AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4

				OPEN    crsAcct
				FETCH   crsAcct
				INTO    @TestAcct

				WHILE (@@FETCH_STATUS = 0) BEGIN

					-- get closest period at or above asking date for fiscal year
					SELECT 	@TestDate = MIN(period_end_date)
					FROM 	glnofind
					WHERE 	nonfin_budget_code = @BalCode
						AND period_end_date >= @FromPerEndDate
						AND period_end_date <= @TestYearEndDate
						AND account_code = @TestAcct

					IF @TestDate IS NOT NULL BEGIN
						SELECT	@TempBal = ISNULL(SUM(ytd_quantity - quantity), 0)
						FROM 	glnofind
						WHERE 	nonfin_budget_code = @BalCode
							AND period_end_date = @TestDate
							AND account_code = @TestAcct
					END
					ELSE BEGIN --try other direction
						-- get closest period below asking date for fiscal year
						SELECT	@TestDate = MAX(period_end_date)
						FROM 	glnofind
						WHERE 	nonfin_budget_code = @BalCode
							AND period_end_date < @FromPerEndDate
							AND period_end_date >= @TestYearStartDate
							AND account_code = @TestAcct
				
						IF @TestDate IS NOT NULL BEGIN
							SELECT	@TempBal = ISNULL(SUM(ytd_quantity), 0)
							FROM 	glnofind
							WHERE 	nonfin_budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @TestAcct
						END
						ELSE BEGIN
							SELECT @TempBal = 0
						END	
					END
					SELECT @Bal = @Bal + @TempBal
	
					FETCH   crsAcct
					INTO    @TestAcct
				END

				CLOSE crsAcct
				DEALLOCATE crsAcct
			END
			ELSE IF @ValMethod = 2 -- Change
				SELECT  @Bal = ISNULL(SUM(quantity), 0)
				FROM    glnofind
				WHERE   nonfin_budget_code = @BalCode
					AND period_end_date >= @FromPerEndDate
					AND period_end_date <= @ThruPerEndDate
					AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
					AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
					AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
					AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
			ELSE IF @ValMethod = 3 BEGIN -- Ending

				SELECT @Bal = 0

				--get end of fiscal year	
				SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
					 	     FROM 	mbbmvwPeriods
						     WHERE	YearStartDate <= @ThruPerEndDate
								AND YearEndDate >= @ThruPerEndDate)

				-- get start of fiscal year
				SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
					 	     FROM 	mbbmvwPeriods
						     WHERE	YearStartDate <= @ThruPerEndDate
								AND YearEndDate >= @ThruPerEndDate)

				DECLARE crsAcct CURSOR FOR

				SELECT  DISTINCT account_code
				FROM    glnofind
				WHERE   nonfin_budget_code = @BalCode
					AND period_end_date >= @TestYearStartDate 
					AND period_end_date <= @TestYearEndDate
					AND seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
					AND seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
					AND seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
					AND seg4_code BETWEEN @FromSeg4 AND @ThruSeg4

				OPEN    crsAcct
				FETCH   crsAcct
				INTO    @TestAcct

				WHILE (@@FETCH_STATUS = 0) BEGIN

					-- get closest period at or below asking date for fiscal year
					SELECT 	@TestDate = MAX(period_end_date)
					FROM 	glnofind
					WHERE 	nonfin_budget_code = @BalCode
						AND period_end_date <= @ThruPerEndDate
						AND period_end_date >= @TestYearStartDate
						AND account_code = @TestAcct
	
					IF @TestDate IS NOT NULL BEGIN
						SELECT	@TempBal = ISNULL(SUM(ytd_quantity), 0)
						FROM 	glnofind
						WHERE 	nonfin_budget_code = @BalCode
							AND period_end_date = @TestDate
							AND account_code = @TestAcct
					END
					ELSE BEGIN --try other direction
						-- get closest period above asking date for fiscal year
						SELECT	@TestDate = MIN(period_end_date)
						FROM 	glnofind
						WHERE 	nonfin_budget_code = @BalCode
							AND period_end_date > @ThruPerEndDate
							AND period_end_date <= @TestYearEndDate
							AND account_code = @TestAcct
					
						IF @TestDate IS NOT NULL BEGIN
							SELECT	@TempBal = ISNULL(SUM(ytd_quantity - quantity), 0)
							FROM 	glnofind
							WHERE 	nonfin_budget_code = @BalCode
								AND period_end_date = @TestDate
								AND account_code = @TestAcct
						END
						ELSE BEGIN
							SELECT @TempBal = 0
						END	
					END
					SELECT @Bal = @Bal + @TempBal
	
					FETCH   crsAcct
					INTO    @TestAcct
				END

				CLOSE crsAcct
				DEALLOCATE crsAcct
			END
		END
	END
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspAcctBal] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspAcctBal] TO [public]
GO

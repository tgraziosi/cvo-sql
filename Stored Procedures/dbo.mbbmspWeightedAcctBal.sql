SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspWeightedAcctBal]
	@HostCompany	mbbmudtCompanyCode,
	@FromAcct	mbbmudtAccountCode,
	@ThruAcct	mbbmudtAccountCode,
	@BalType	tinyint,
	@BalCode	varchar(16),
	@InclUnposted	tinyint,
	@Currency	mbbmudtCurrencyCode,
	@HomeNat	tinyint,
	@FromPerBegDate	int,
	@FromPerEndDate	int,
	@ThruPerEndDate	int,
	@NumDays	int			OUTPUT,
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
		@NumPds         int,

		@Seg1Pos smallint, @Seg1Len smallint,
		@Seg2Pos smallint, @Seg2Len smallint,
		@Seg3Pos smallint, @Seg3Len smallint,
		@Seg4Pos smallint, @Seg4Len smallint,

		@FromSeg1 mbbmudtAccountCode, @ThruSeg1 mbbmudtAccountCode,
		@FromSeg2 mbbmudtAccountCode, @ThruSeg2 mbbmudtAccountCode,
		@FromSeg3 mbbmudtAccountCode, @ThruSeg3 mbbmudtAccountCode,
		@FromSeg4 mbbmudtAccountCode, @ThruSeg4 mbbmudtAccountCode

	DECLARE @BegBal float
	DECLARE @EndBal float
	DECLARE @TestAcct mbbmudtAccountCode
	DECLARE @TestDate int 
	DECLARE @TestYearEndDate int 
	DECLARE @TestYearStartDate int 

	IF @Currency = '*'
		SELECT  @FromCurrency = min(currency_code), @ThruCurrency = max(currency_code) from glbal
	ELSE
		SELECT  @FromCurrency = @Currency, @ThruCurrency = @Currency

	SELECT  @NumPds = COUNT(*)
	FROM    mbbmvwPeriods
	WHERE   HostCompany = @HostCompany
		AND PeriodEndDate >= @FromPerEndDate
		AND PeriodEndDate <= @ThruPerEndDate

	SELECT  @NumDays = ((@ThruPerEndDate - @FromPerBegDate + 1)
			- (AvgDailyBalExclSat * ((@ThruPerEndDate - @FromPerBegDate + 1) / 7))
			- (AvgDailyBalExclSun * ((@ThruPerEndDate - @FromPerBegDate + 1) / 7))
			- (AvgDailyBalExclSat * (((@FromPerBegDate) % 7) + ((@ThruPerEndDate - @FromPerBegDate + 1) % 7)) / 7)
			- (AvgDailyBalExclSun * (((@FromPerBegDate - 1) % 7) + ((@ThruPerEndDate - @FromPerBegDate + 1) % 7)) / 7))
	FROM    mbbmOptions75
	WHERE	HostCompany = @HostCompany

	IF @FromAcct = @ThruAcct BEGIN
		IF @BalType = 0 BEGIN -- Actual
			IF @HomeNat = 0 BEGIN --Home
				SELECT  @Bal = ISNULL(SUM(home_current_balance) * @NumDays, 0)
				FROM    glbal
				WHERE   balance_type = 1
					AND balance_date <= @FromPerBegDate
					AND balance_until >= @FromPerBegDate
					AND currency_code >= @FromCurrency
					AND currency_code <= @ThruCurrency
					AND account_code = @FromAcct

				SELECT  @Bal = @Bal + ISNULL(SUM(balance * ((@ThruPerEndDate - b.date_applied + 1)
					- (AvgDailyBalExclSat * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSun * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSat * (((b.date_applied) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)
					- (AvgDailyBalExclSun * (((b.date_applied - 1) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)) ), 0)
				FROM    gltrxdet a,
					gltrx_all b,
					mbbmOptions75 c
				WHERE   a.journal_ctrl_num = b.journal_ctrl_num
					AND b.date_applied >= @FromPerBegDate
					AND b.date_applied <= @ThruPerEndDate
					AND a.nat_cur_code >= @FromCurrency
					AND a.nat_cur_code <= @ThruCurrency
					AND a.posted_flag >= ABS(@InclUnposted - 1)
					AND a.posted_flag <= 1
					AND a.account_code = @FromAcct
					AND c.HostCompany = @HostCompany
			END
			ELSE IF @HomeNat = 1 BEGIN -- Natural
				SELECT  @Bal = ISNULL(SUM(current_balance) * @NumDays, 0)
				FROM    glbal
				WHERE   balance_type = 1
					AND balance_date <= @FromPerBegDate
					AND balance_until >= @FromPerBegDate
					AND currency_code >= @FromCurrency
					AND currency_code <= @ThruCurrency
					AND account_code = @FromAcct

				SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance * ((@ThruPerEndDate - b.date_applied + 1)
					- (AvgDailyBalExclSat * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSun * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSat * (((b.date_applied) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)
					- (AvgDailyBalExclSun * (((b.date_applied - 1) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)) ), 0)
				FROM    gltrxdet a,
					gltrx_all b,
					mbbmOptions75 c
				WHERE   a.journal_ctrl_num = b.journal_ctrl_num
					AND b.date_applied >= @FromPerBegDate
					AND b.date_applied <= @ThruPerEndDate
					AND a.nat_cur_code >= @FromCurrency
					AND a.nat_cur_code <= @ThruCurrency
					AND a.posted_flag >= ABS(@InclUnposted - 1)
					AND a.posted_flag <= 1
					AND a.account_code = @FromAcct
					AND c.HostCompany = @HostCompany
			END
			ELSE BEGIN -- Operating
				SELECT  @Bal = ISNULL(SUM(current_balance_oper) * @NumDays, 0)
				FROM    glbal
				WHERE   balance_type = 1
					AND balance_date <= @FromPerBegDate
					AND balance_until >= @FromPerBegDate
					AND currency_code >= @FromCurrency
					AND currency_code <= @ThruCurrency
					AND account_code = @FromAcct

				SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper * ((@ThruPerEndDate - b.date_applied + 1)
					- (AvgDailyBalExclSat * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSun * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSat * (((b.date_applied) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)
					- (AvgDailyBalExclSun * (((b.date_applied - 1) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)) ), 0)
				FROM    gltrxdet a,
					gltrx_all b,
					mbbmOptions75 c
				WHERE   a.journal_ctrl_num = b.journal_ctrl_num
					AND b.date_applied >= @FromPerBegDate
					AND b.date_applied <= @ThruPerEndDate
					AND a.nat_cur_code >= @FromCurrency
					AND a.nat_cur_code <= @ThruCurrency
					AND a.posted_flag >= ABS(@InclUnposted - 1)
					AND a.posted_flag <= 1
					AND a.account_code = @FromAcct
					AND c.HostCompany = @HostCompany

			END
		END
		ELSE IF @BalType = 1 BEGIN -- Budget

			--get end of fiscal year	
			SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
				 	     FROM 	mbbmvwPeriods
					     WHERE	YearStartDate <= @ThruPerEndDate
							AND YearEndDate >= @ThruPerEndDate)

			-- get start of fiscal year
			SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
				 	     FROM 	mbbmvwPeriods
					     WHERE	YearStartDate <= @FromPerEndDate
							AND YearEndDate >= @FromPerEndDate)

			-- get closest period at or below asking date for fiscal year
			SELECT 	@TestDate = MAX(period_end_date)
			FROM 	glbuddet
			WHERE 	budget_code = @BalCode
				AND period_end_date <= @FromPerEndDate
				AND period_end_date >= @TestYearStartDate
				AND account_code = @FromAcct

			IF @TestDate IS NOT NULL BEGIN
				SELECT	@BegBal = ISNULL(SUM(current_balance), 0)
				FROM 	glbuddet
				WHERE 	budget_code = @BalCode
					AND period_end_date = @TestDate
					AND account_code = @FromAcct
			END
			ELSE BEGIN
				SELECT @BegBal = 0
			END

			-- get closest period at or above asking date for fiscal year
			SELECT	@TestDate = MIN(period_end_date)
			FROM 	glbuddet
			WHERE 	budget_code = @BalCode
				AND period_end_date >= @ThruPerEndDate
				AND period_end_date <= @TestYearEndDate
				AND account_code = @FromAcct
		
			IF @TestDate IS NOT NULL BEGIN
				SELECT	@EndBal = ISNULL(SUM(current_balance-net_change), 0)
				FROM 	glbuddet
				WHERE 	budget_code = @BalCode
					AND period_end_date = @TestDate
					AND account_code = @FromAcct
			END
			ELSE BEGIN
				SELECT @EndBal = @BegBal
			END	

			SELECT  @Bal = ((@EndBal + @BegBal) / 2) / @NumPds
		END
		ELSE IF @BalType = 2 BEGIN -- Statistical

			--get end of fiscal year	
			SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
				 	     FROM 	mbbmvwPeriods
					     WHERE	YearStartDate <= @ThruPerEndDate
							AND YearEndDate >= @ThruPerEndDate)

			-- get start of fiscal year
			SELECT	@TestYearStartDate = (SELECT DISTINCT YearStartDate
				 	     FROM 	mbbmvwPeriods
					     WHERE	YearStartDate <= @FromPerEndDate
							AND YearEndDate >= @FromPerEndDate)

			-- get closest period at or below asking date for fiscal year
			SELECT 	@TestDate = MAX(period_end_date)
			FROM 	glnofind
			WHERE 	nonfin_budget_code = @BalCode
				AND period_end_date <= @FromPerEndDate
				AND period_end_date >= @TestYearStartDate
				AND account_code = @FromAcct

			IF @TestDate IS NOT NULL BEGIN
				SELECT	@BegBal = ISNULL(SUM(ytd_quantity), 0)
				FROM 	glnofind
				WHERE 	nonfin_budget_code = @BalCode
					AND period_end_date = @TestDate
					AND account_code = @FromAcct
			END
			ELSE BEGIN
				SELECT @BegBal = 0
			END

			-- get closest period at or above asking date for fiscal year
			SELECT	@TestDate = MIN(period_end_date)
			FROM 	glnofind
			WHERE 	nonfin_budget_code = @BalCode
				AND period_end_date >= @ThruPerEndDate
				AND period_end_date <= @TestYearEndDate
				AND account_code = @FromAcct
		
			IF @TestDate IS NOT NULL BEGIN
				SELECT	@EndBal = ISNULL(SUM(ytd_quantity-quantity), 0)
				FROM 	glnofind
				WHERE 	nonfin_budget_code = @BalCode
					AND period_end_date = @TestDate
					AND account_code = @FromAcct
			END
			ELSE BEGIN
				SELECT @EndBal = @BegBal
			END	

			SELECT  @Bal = ((@EndBal + @BegBal) / 2) / @NumPds
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
				SELECT  @Bal = ISNULL(SUM(home_current_balance) * @NumDays, 0)
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

				SELECT  @Bal = @Bal + ISNULL(SUM(balance * ((@ThruPerEndDate - b.date_applied + 1)
					- (AvgDailyBalExclSat * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSun * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSat * (((b.date_applied) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)
					- (AvgDailyBalExclSun * (((b.date_applied - 1) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)) ), 0)
				FROM    gltrxdet a,
					gltrx_all b,
					mbbmOptions75 c
				WHERE   a.journal_ctrl_num = b.journal_ctrl_num
					AND b.date_applied >= @FromPerBegDate
					AND b.date_applied <= @ThruPerEndDate
					AND a.nat_cur_code >= @FromCurrency
					AND a.nat_cur_code <= @ThruCurrency
					AND a.posted_flag >= ABS(@InclUnposted - 1)
					AND a.posted_flag <= 1
					AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
					AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
					AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
					AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
					AND c.HostCompany = @HostCompany
			END
			ELSE IF @HomeNat = 1 BEGIN -- Natural
				SELECT  @Bal = ISNULL(SUM(current_balance) * @NumDays, 0)
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

				SELECT  @Bal = @Bal + ISNULL(SUM(nat_balance * ((@ThruPerEndDate - b.date_applied + 1)
					- (AvgDailyBalExclSat * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSun * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSat * (((b.date_applied) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)
					- (AvgDailyBalExclSun * (((b.date_applied - 1) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)) ), 0)
				FROM    gltrxdet a,
					gltrx_all b,
					mbbmOptions75 c
				WHERE   a.journal_ctrl_num = b.journal_ctrl_num
					AND b.date_applied >= @FromPerBegDate
					AND b.date_applied <= @ThruPerEndDate
					AND a.nat_cur_code >= @FromCurrency
					AND a.nat_cur_code <= @ThruCurrency
					AND a.posted_flag >= ABS(@InclUnposted - 1)
					AND a.posted_flag <= 1
					AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
					AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
					AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
					AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
					AND c.HostCompany = @HostCompany
			END
			ELSE BEGIN -- Operating
				SELECT  @Bal = ISNULL(SUM(current_balance_oper) * @NumDays, 0)
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

				SELECT  @Bal = @Bal + ISNULL(SUM(balance_oper * ((@ThruPerEndDate - b.date_applied + 1)
					- (AvgDailyBalExclSat * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSun * ((@ThruPerEndDate - b.date_applied + 1) / 7))
					- (AvgDailyBalExclSat * (((b.date_applied) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)
					- (AvgDailyBalExclSun * (((b.date_applied - 1) % 7) + ((@ThruPerEndDate - b.date_applied + 1) % 7)) / 7)) ), 0)
				FROM    gltrxdet a,
					gltrx_all b,
					mbbmOptions75 c
				WHERE   a.journal_ctrl_num = b.journal_ctrl_num
					AND b.date_applied >= @FromPerBegDate
					AND b.date_applied <= @ThruPerEndDate
					AND a.nat_cur_code >= @FromCurrency
					AND a.nat_cur_code <= @ThruCurrency
					AND a.posted_flag >= ABS(@InclUnposted - 1)
					AND a.posted_flag <= 1
					AND a.seg1_code BETWEEN @FromSeg1 AND @ThruSeg1
					AND a.seg2_code BETWEEN @FromSeg2 AND @ThruSeg2
					AND a.seg3_code BETWEEN @FromSeg3 AND @ThruSeg3
					AND a.seg4_code BETWEEN @FromSeg4 AND @ThruSeg4
					AND c.HostCompany = @HostCompany
			END

		END
		ELSE IF @BalType = 1 BEGIN -- Budget

			SELECT @Bal = 0

			--get end of fiscal year	
			SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
				 	     FROM 	mbbmvwPeriods
					     WHERE	YearStartDate <= @ThruPerEndDate
							AND YearEndDate >= @ThruPerEndDate)

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

				-- get closest period at or below asking date for fiscal year
				SELECT 	@TestDate = MAX(period_end_date)
				FROM 	glbuddet
				WHERE 	budget_code = @BalCode
					AND period_end_date <= @FromPerEndDate
					AND period_end_date >= @TestYearStartDate
					AND account_code = @TestAcct

				IF @TestDate IS NOT NULL BEGIN
					SELECT	@BegBal = ISNULL(SUM(current_balance), 0)
					FROM 	glbuddet
					WHERE 	budget_code = @BalCode
						AND period_end_date = @TestDate
						AND account_code = @TestAcct
				END
				ELSE BEGIN
					SELECT @BegBal = 0
				END

				-- get closest period at or above asking date for fiscal year
				SELECT	@TestDate = MIN(period_end_date)
				FROM 	glbuddet
				WHERE 	budget_code = @BalCode
					AND period_end_date >= @ThruPerEndDate
					AND period_end_date <= @TestYearEndDate
					AND account_code = @TestAcct
		
				IF @TestDate IS NOT NULL BEGIN
					SELECT	@EndBal = ISNULL(SUM(current_balance-net_change), 0)
					FROM 	glbuddet
					WHERE 	budget_code = @BalCode
						AND period_end_date = @TestDate
						AND account_code = @TestAcct
				END
				ELSE BEGIN
					SELECT @EndBal = @BegBal
				END	

				SELECT  @Bal = @Bal + (((@EndBal + @BegBal) / 2) / @NumPds)

				FETCH   crsAcct
				INTO    @TestAcct
			END

			CLOSE crsAcct
			DEALLOCATE crsAcct

		END
		ELSE IF @BalType = 2 BEGIN -- Statistical

			SELECT @Bal = 0

			--get end of fiscal year	
			SELECT	@TestYearEndDate = (SELECT DISTINCT YearEndDate
				 	     FROM 	mbbmvwPeriods
					     WHERE	YearStartDate <= @ThruPerEndDate
							AND YearEndDate >= @ThruPerEndDate)

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

				-- get closest period at or below asking date for fiscal year
				SELECT 	@TestDate = MAX(period_end_date)
				FROM 	glnofind
				WHERE 	nonfin_budget_code = @BalCode
					AND period_end_date <= @FromPerEndDate
					AND period_end_date >= @TestYearStartDate
					AND account_code = @TestAcct

				IF @TestDate IS NOT NULL BEGIN
					SELECT	@BegBal = ISNULL(SUM(ytd_quantity), 0)
					FROM 	glnofind
					WHERE 	nonfin_budget_code = @BalCode
						AND period_end_date = @TestDate
						AND account_code = @TestAcct
				END
				ELSE BEGIN
					SELECT @BegBal = 0
				END

				-- get closest period at or above asking date for fiscal year
				SELECT	@TestDate = MIN(period_end_date)
				FROM 	glnofind
				WHERE 	nonfin_budget_code = @BalCode
					AND period_end_date >= @ThruPerEndDate
					AND period_end_date <= @TestYearEndDate
					AND account_code = @TestAcct
		
				IF @TestDate IS NOT NULL BEGIN
					SELECT	@EndBal = ISNULL(SUM(ytd_quantity-quantity), 0)
					FROM 	glnofind
					WHERE 	nonfin_budget_code = @BalCode
						AND period_end_date = @TestDate
						AND account_code = @TestAcct
				END
				ELSE BEGIN
					SELECT @EndBal = @BegBal
				END	

				SELECT  @Bal = @Bal + (((@EndBal + @BegBal) / 2) / @NumPds)

				FETCH   crsAcct
				INTO    @TestAcct
			END

			CLOSE crsAcct
			DEALLOCATE crsAcct
		END
	END
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspWeightedAcctBal] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspWeightedAcctBal] TO [public]
GO

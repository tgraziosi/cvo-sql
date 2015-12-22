SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspGLUpdate] 
	@PostProc		mbbmudtYesNo,
	@BudgetKey		varchar(16),
	@BudgetDesc		varchar(30),
	@StatKey		varchar(16),
	@StatDesc		varchar(30),
	@CompanyCode	mbbmudtCompanyCode
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
	-- Create Periods Temp Table
	CREATE TABLE #mbPCache (YearNumber INT NOT NULL, YearStartDate INT NOT NULL, YearEndDate INT NOT NULL, PeriodNumber 
	  INT NOT NULL, PeriodStartDate INT NOT NULL, PeriodEndDate INT PRIMARY KEY CLUSTERED NOT NULL, PeriodDescription 
	  VARCHAR(40) NOT NULL)
	CREATE INDEX mbnxPeriodsCache_1 ON #mbPCache(PeriodStartDate, PeriodEndDate)
	CREATE INDEX mbnxPeriodsCache_2 ON #mbPCache(YearNumber, PeriodNumber)

	INSERT #mbPCache SELECT YearNumber, YearStartDate, YearEndDate, PeriodNumber, PeriodStartDate, PeriodEndDate, 
	  PeriodDescription FROM mbbmvwPeriods WHERE HostCompany = @CompanyCode

	-- Update All Ending Balances
	UPDATE mbbmTmpUpdateGLSum74 SET EndBal = (SELECT SUM(b.NetChange) FROM mbbmTmpUpdateGLSum74 b, 
	  #mbPCache p WHERE p.PeriodEndDate = a.PerEnd AND b.Acct = a.Acct AND b.Acct_Dim1 = a.Acct_Dim1 And b.PerEnd 
	  BETWEEN p.YearStartDate AND a.PerEnd) FROM mbbmTmpUpdateGLSum74 a

	-- Update GL
	IF @PostProc = 0 BEGIN
	  IF EXISTS (SELECT * FROM glbud WHERE budget_code = @BudgetKey) BEGIN
	    UPDATE glbud SET budget_description = @BudgetDesc  WHERE budget_code = @BudgetKey
	  END
                
	  ELSE BEGIN
	    INSERT glbud(budget_code, budget_description)
	    VALUES (@BudgetKey, @BudgetDesc)
	  END
                 
	  BEGIN TRANSACTION

	  DELETE glbuddet WHERE budget_code = @BudgetKey           
  
	  INSERT glbuddet(sequence_id, budget_code, account_code, reference_code, net_change, current_balance, period_end_date, seg1_code, seg2_code, seg3_code, seg4_code, changed_flag)
	  SELECT SequenceID, @BudgetKey, Acct, Acct_Dim1, NetChange, EndBal, PerEnd, seg1_code, seg2_code, seg3_code, seg4_code, 0 
	    FROM mbbmTmpUpdateGLSum74, glchart
	    WHERE account_code = Acct
	  COMMIT TRANSACTION

	END

	ELSE BEGIN
	  IF EXISTS (SELECT * FROM glnofin WHERE nonfin_budget_code = @StatKey) BEGIN
	    UPDATE glnofin SET nonfin_budget_desc = @StatDesc WHERE nonfin_budget_code = @StatKey
	  END
  
	  ELSE BEGIN
	    INSERT glnofin(nonfin_budget_code, nonfin_budget_desc) VALUES (@StatKey, @StatDesc)
	  END
                    
	  BEGIN TRANSACTION

	  DELETE glnofind WHERE nonfin_budget_code = @StatKey

	  INSERT glnofind(sequence_id, nonfin_budget_code, account_code, quantity, ytd_quantity, period_end_date, 
	    seg1_code, seg2_code, seg3_code, seg4_code, changed_flag, unit_of_measure)
	  SELECT SequenceID, @StatKey, Acct, NetChange, EndBal, PerEnd, seg1_code, seg2_code, seg3_code, seg4_code, 
	    0, '' FROM mbbmTmpUpdateGLSum74, glchart WHERE account_code = Acct
	  COMMIT TRANSACTION

	END
	DROP TABLE #mbPCache
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspGLUpdate] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspGLUpdate] TO [public]
GO

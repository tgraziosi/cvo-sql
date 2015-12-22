SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROC [dbo].[mbbmspGLUpdatePlat41Slam] 
      @PostProc         mbbmudtYesNo,
      @BudgetKey        varchar(16),
      @BudgetDesc       varchar(30),
      @StatKey          varchar(16),
      @StatDesc         varchar(30),
      @CompanyCode      mbbmudtCompanyCode,
      @HomeCurrency     varchar(30),
      @UserID                 varchar(30)
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
	DECLARE @INSCOUNT int

	-- Create Periods Temp Table
	CREATE TABLE #mbPCache (YearNumber INT NOT NULL, YearStartDate INT NOT NULL, YearEndDate INT NOT NULL, PeriodNumber 
		INT NOT NULL, PeriodStartDate INT NOT NULL, PeriodEndDate INT PRIMARY KEY CLUSTERED NOT NULL, PeriodDescription 
		VARCHAR(40) NOT NULL)
	CREATE INDEX mbnxPeriodsCache_1 ON #mbPCache(PeriodStartDate, PeriodEndDate)
	CREATE INDEX mbnxPeriodsCache_2 ON #mbPCache(YearNumber, PeriodNumber)
 
	INSERT #mbPCache SELECT YearNumber, YearStartDate, YearEndDate, PeriodNumber, PeriodStartDate, PeriodEndDate, 
        	PeriodDescription FROM mbbmvwPeriods WHERE HostCompany = @CompanyCode
 
	--SELECT * INTO #tmpSum FROM mbbmTmpUpdateGLSumSlam750 WHERE UserID = @UserID AND CompanyCode = @CompanyCode AND Status = 'I'

	--DELETE FROM mbbmTmpUpdateGLSumSlam750 WHERE UserID= @UserID AND CompanyCode = @CompanyCode AND Status = 'I'

	-- Update All Ending Balances
	UPDATE mbbmTmpUpdateGLSumSlam750 SET EndBal = (SELECT SUM(b.NetChange) FROM mbbmTmpUpdateGLSumSlam750 b, 
        	#mbPCache p WHERE p.PeriodEndDate = a.PerEnd AND b.Acct = a.Acct AND b.Acct_Dim1 = a.Acct_Dim1 AND b.PerEnd 
	        BETWEEN p.YearStartDate AND a.PerEnd AND a.CompanyCode = b.CompanyCode AND a.UserID = b.UserID AND a.Status = b.Status) 
        	FROM mbbmTmpUpdateGLSumSlam750 a
		WHERE a.CompanyCode = @CompanyCode 
		AND a.UserID = @UserID
		AND a.Status = 'I'
 
	-- Update GL
	IF @PostProc = 0 BEGIN
		IF EXISTS (SELECT * FROM glbud WHERE budget_code = @BudgetKey) BEGIN
			UPDATE glbud SET budget_description = @BudgetDesc WHERE budget_code = @BudgetKey
	        END                      
    
    		ELSE BEGIN
			INSERT glbud(budget_code, budget_description, rate_type)
			SELECT @BudgetKey, @BudgetDesc, rate_type_home FROM glco
	        END
                    

		UPDATE a SET a.net_change = b.NetChange, a.current_balance = b.EndBal
            		FROM glbuddet a JOIN mbbmTmpUpdateGLSumSlam750 b ON 	
		    	a.account_code = b.Acct 
			AND a.budget_code = @BudgetKey
			AND a.period_end_date = b.PerEnd 
			WHERE b.UserID = @UserID
			AND b.CompanyCode = @CompanyCode
			AND b.Status = 'I'
 
		UPDATE b SET b.Status = 'U'
			FROM glbuddet a JOIN mbbmTmpUpdateGLSumSlam750 b ON 
            		a.account_code = b.Acct 
			AND a.budget_code = @BudgetKey
			AND a.period_end_date = b.PerEnd 
			WHERE b.UserID = @UserID
			AND b.CompanyCode = @CompanyCode
			AND b.Status = 'I'
 
		SELECT @INSCOUNT = (SELECT COUNT(*) FROM mbbmTmpUpdateGLSumSlam750 WHERE UserID = @UserID AND CompanyCode = @CompanyCode AND Status = 'I')
		IF @INSCOUNT > 0 BEGIN
           		EXEC mbbmspSequenceAcctsSlam @CompanyCode, @UserID, @BudgetKey
		END

		INSERT glbuddet(sequence_id, budget_code, account_code, reference_code, net_change, current_balance, period_end_date, 
			seg1_code, seg2_code, seg3_code, seg4_code, changed_flag, nat_cur_code, rate, rate_oper, nat_net_change, 
          		nat_current_balance, net_change_oper, current_balance_oper)
		        SELECT a.SequenceID, @BudgetKey, a.Acct, a.Acct_Dim1, a.NetChange, a.EndBal, a.PerEnd, c.seg1_code, c.seg2_code, c.seg3_code, c.seg4_code, 0, 
          		@HomeCurrency, 1, 1, a.NetChange, a.EndBal, a.NetChange, a.EndBal 
        		FROM mbbmTmpUpdateGLSumSlam750 a, glchart c
			WHERE c.account_code = a.Acct
			AND a.CompanyCode = @CompanyCode
			AND a.UserID = @UserID
			AND a.Status = 'I'                  
 
      		DELETE FROM mbbmTmpUpdateGLNewSlam750 WHERE
			UserID = @UserID
			AND CompanyCode = @CompanyCode

	END
 
	ELSE BEGIN
		IF EXISTS (SELECT * FROM glnofin WHERE nonfin_budget_code = @StatKey) BEGIN
			UPDATE glnofin SET nonfin_budget_desc = @StatDesc WHERE nonfin_budget_code = @StatKey
	        END
  
	        ELSE BEGIN
			INSERT glnofin(nonfin_budget_code, nonfin_budget_desc) VALUES (@StatKey, @StatDesc)
	        END
                    
        	BEGIN TRANSACTION
 
--  v  Changed to avoid mass delete and insert processes
		UPDATE a SET a.quantity = b.NetChange, a.ytd_quantity = b.EndBal
        		FROM glnofind a JOIN mbbmTmpUpdateGLSumSlam750 b ON 
			a.account_code = b.Acct 
			AND a.nonfin_budget_code = @StatKey
			AND a.period_end_date = b.PerEnd 
			WHERE b.UserID = @UserID
			AND b.CompanyCode = @CompanyCode
			AND b.Status = 'I'
	 
		UPDATE b SET b.Status = 'U'
			FROM glnofind a JOIN mbbmTmpUpdateGLSumSlam750 b ON 
			a.account_code = b.Acct 
			AND a.nonfin_budget_code = @StatKey
			AND a.period_end_date = b.PerEnd 
			WHERE b.UserID = @UserID
			AND b.CompanyCode = @CompanyCode
			AND b.Status = 'I'

		INSERT glnofind(sequence_id, nonfin_budget_code, account_code, quantity, ytd_quantity, period_end_date, 
			seg1_code, seg2_code, seg3_code, seg4_code, changed_flag, unit_of_measure)
		SELECT SequenceID, @StatKey, Acct, NetChange, EndBal, PerEnd, seg1_code, seg2_code, seg3_code, seg4_code, 0, ''
			FROM mbbmTmpUpdateGLSumSlam750 a, glchart c
			WHERE account_code = Acct
			AND a.CompanyCode = @CompanyCode
			AND a.UserID = @UserID
			AND a.Status = 'I'

-- 		DELETE glnofind WHERE nonfin_budget_code = @StatKey
 
--		INSERT glnofind(sequence_id, nonfin_budget_code, account_code, quantity, ytd_quantity, period_end_date, 
--			seg1_code, seg2_code, seg3_code, seg4_code, changed_flag, unit_of_measure)
--	        SELECT SequenceID, @StatKey, Acct, NetChange, EndBal, PerEnd, seg1_code, seg2_code, seg3_code, seg4_code, 
--			0, '' FROM #tmpSum a, glchart c
--			WHERE account_code = Acct
--			AND a.CompanyCode = @CompanyCode
--			AND a.UserID = @UserID

--  ^  Changed to avoid mass delete and insert processes
              
 
        COMMIT TRANSACTION
 
      END

		-- Clean Up From current Process (was leaving them here which 
		-- caused a problem when doing both stat and budget simultaneously)
		Delete from  mbbmTmpUpdateGLSumSlam750 
			where CompanyCode = @CompanyCode
					AND UserID = @UserID

      DROP TABLE #mbPCache
END
GO
GRANT EXECUTE ON  [dbo].[mbbmspGLUpdatePlat41Slam] TO [Analytics]
GO
GRANT EXECUTE ON  [dbo].[mbbmspGLUpdatePlat41Slam] TO [public]
GO

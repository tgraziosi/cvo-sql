SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[apgpvch_sp]	@all_due_date smallint,								
							@from_due_date int,
							@to_due_date int,
							@force_disc_flag smallint,		
							@current_date int,
							@payment_flag smallint,
							@payment_code varchar(8),
							@currency_code varchar(8),
							@process_group_num varchar(16),	
							@check_curr smallint,
							@debug_level smallint = 0,
							@cash_acct_code varchar(32) = ''
AS

DECLARE @vo_trx_ctrl_num VARCHAR (16), 
	@vo_terms_code VARCHAR (8),
	@prc FLOAT,
	@row_number INT,
	@date_applied INT


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 53, 5 ) + " -- ENTRY: "

CREATE TABLE #vchrs (trx_ctrl_num varchar(16))
IF @@error != 0
   RETURN -1
CREATE CLUSTERED INDEX vchrs_ind_1 ON #vchrs (trx_ctrl_num)
IF @@error != 0
   RETURN -1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 64, 5 ) + " -- MSG: " + "---INSERT vouchers into #vchrs"
INSERT #vchrs (trx_ctrl_num)
SELECT trx_ctrl_num
FROM apvohdr
WHERE process_ctrl_num = @process_group_num
AND ((@payment_flag = 0) OR (payment_code = @payment_code))

IF @@error != 0
   RETURN -1


CREATE TABLE #vchrs2 (trx_ctrl_num varchar(16))
IF @@error != 0
   RETURN -1

CREATE TABLE #vchrs3 (trx_ctrl_num varchar(16),
				      vendor_code varchar(12),
				      pay_to_code varchar(8),
				      terms_code varchar(8),
				      nat_cur_code varchar(8),
					  rate_home float,
					  rate_oper float,
					  rate_type_home varchar(8),
					  rate_type_oper varchar(8),
				      amt_net float,
				      amt_to_pay float,
				      amt_disc_to_take float,		
				      date_aging int,
				      date_discount int,
				      date_applied int,
					  date_due int,
				      ovpc_flag smallint,
				      payment_code varchar(8),
				      org_id varchar(30) NULL)
IF @@error != 0
   RETURN -1

CREATE TABLE #posted (trx_ctrl_num varchar(16),
				      vo_amt_disc_taken float )
IF @@error != 0
   RETURN -1

CREATE TABLE #unposted (trx_ctrl_num varchar(16),
						vo_amt_applied float,
		    		    vo_amt_disc_taken float )
IF @@error != 0
   RETURN -1

CREATE TABLE #aging (trx_ctrl_num varchar(16),
				     date_aging int,
				     date_due int,
				     amount float )
IF @@error != 0
   RETURN -1

		



select @row_number = 1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 125, 5 ) + " -- MSG: " + "---Begin looping"
WHILE (1=1)
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 128, 5 ) + " -- MSG: " + "---Insert #vchrs2"
	SET ROWCOUNT @row_number

	INSERT #vchrs2 (trx_ctrl_num)
	SELECT trx_ctrl_num
	FROM #vchrs
	order by trx_ctrl_num	
	
	IF @@rowcount = 0 BREAK
	SET ROWCOUNT 0

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 140, 5 ) + " -- MSG: " + "---Query aptrx to #vchrs3"
	INSERT #vchrs3 (trx_ctrl_num,
					vendor_code,
					pay_to_code,
					terms_code,
					nat_cur_code,
					rate_home,
					rate_oper,
					rate_type_home,
					rate_type_oper,
					amt_net,
					amt_to_pay,
					amt_disc_to_take,
					date_aging,
					date_discount,
					date_applied,
					date_due,
					ovpc_flag,
					payment_code, 
					org_id )
	SELECT a.trx_ctrl_num,
	       b.vendor_code,
	       b.pay_to_code,
	       b.terms_code,
	       b.currency_code,
		   b.rate_home,
		   b.rate_oper,
		   b.rate_type_home,
		   b.rate_type_oper,
	       b.amt_net,
	       b.amt_net - b.amt_paid_to_date,
	       0.0,
	       b.date_aging,
	       b.date_discount,
		   b.date_applied,
		   b.date_due,
		   b.one_check_flag,
		   b.payment_code,
		   b.org_id
	FROM #vchrs2 a, apvohdr b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num
	
	IF @@error != 0
   		RETURN -1


	


	IF @check_curr = 1
	   BEGIN
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 191, 5 ) + " -- MSG: " + "---Delete single currency vendors"
		IF ((SELECT mc_flag FROM apco) = 1)
		   BEGIN
			DELETE #vchrs3
			FROM #vchrs3 a, apvend b
			WHERE a.vendor_code = b.vendor_code
			AND a.pay_to_code = ""
			AND b.one_cur_vendor = 1
			AND b.nat_cur_code != @currency_code

			IF @@error != 0
   				RETURN -1


			DELETE #vchrs3
			FROM #vchrs3 a, apvnd_vw b
			WHERE a.vendor_code = b.vendor_code
			AND a.pay_to_code = b.pay_to_code
			AND b.one_cur_vendor = 1
			AND b.nat_cur_code != @currency_code

			IF @@error != 0
		   		RETURN -1

		   END
	   END

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 219, 5 ) + " -- MSG: " + " -- MSG: " + "---Delete organizations without relation to account organization"	
	DELETE #vchrs3
	FROM #vchrs3 a, iborgsameandrels_vw r
	WHERE r.controlling_org_id = dbo.IBOrgbyAcct_fn(@cash_acct_code)
	AND a.org_id NOT IN ( SELECT detail_org_id FROM iborgsameandrels_vw WHERE controlling_org_id = dbo.IBOrgbyAcct_fn(@cash_acct_code) )

	IF @@error != 0
   		RETURN -1
	

	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 231, 5 ) + " -- MSG: " + "---Get posted amounts"
	INSERT #posted (trx_ctrl_num, vo_amt_disc_taken)
	SELECT a.trx_ctrl_num, SUM(b.vo_amt_disc_taken)
	FROM #vchrs3 a, appydet b
	WHERE a.trx_ctrl_num = b.apply_to_num
	AND b.void_flag = 0
	GROUP BY a.trx_ctrl_num

	IF @@error != 0
   		RETURN -1


	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 244, 5 ) + " -- MSG: " + "---Get unposted amounts"
	INSERT #unposted (trx_ctrl_num, vo_amt_applied, vo_amt_disc_taken)
	SELECT a.trx_ctrl_num, SUM(b.vo_amt_applied),SUM(b.vo_amt_disc_taken)
	FROM #vchrs3 a, apinppdt b
	WHERE a.trx_ctrl_num = b.apply_to_num
	AND b.trx_type = 4111
	GROUP BY a.trx_ctrl_num

	IF @@error != 0
   		RETURN -1


	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 258, 5 ) + " -- MSG: " + "---Calculate terms discount"
	IF @force_disc_flag = 1  
	BEGIN
		select @prc = 0

		select 	@vo_terms_code = b.terms_code , 
	        	@vo_trx_ctrl_num  = a.trx_ctrl_num
		from #vchrs3 a, apvohdr b
		where a.trx_ctrl_num = b.trx_ctrl_num

		SELECT 	@prc = discount_prc/100
		FROM 	aptermsd
		WHERE 	terms_code = @vo_terms_code 
                AND	sequence_id = 1
		SELECT @prc = ISNULL(@prc,0)

		UPDATE #vchrs3  
		SET amt_disc_to_take = (SIGN(a.amt_net * @prc) * ROUND(ABS(a.amt_net * @prc) + 0.0000001, c.curr_precision))
		FROM #vchrs3 a, glcurr_vw c
		WHERE trx_ctrl_num = @vo_trx_ctrl_num 
		AND a.nat_cur_code = c.currency_code
	END
	ELSE
	BEGIN
		select 	@vo_terms_code = b.terms_code , 
	        	@vo_trx_ctrl_num  = a.trx_ctrl_num
		from #vchrs3 a, apvohdr b
		where a.trx_ctrl_num = b.trx_ctrl_num

		SELECT @date_applied = @current_date

		EXEC calc_discount_sp @date_applied, @vo_trx_ctrl_num, @vo_terms_code, @prc OUTPUT 
		SELECT @prc = ISNULL(@prc,0)

		UPDATE #vchrs3  
		SET amt_disc_to_take = (SIGN(a.amt_net * @prc) * ROUND(ABS(a.amt_net * @prc) + 0.0000001, c.curr_precision))
		FROM #vchrs3 a, glcurr_vw c
		WHERE trx_ctrl_num = @vo_trx_ctrl_num 
		AND a.nat_cur_code = c.currency_code
	END

	


	IF @all_due_date = 0
       BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 304, 5 ) + " -- MSG: " + "---Subtract agings not in due date range"
			INSERT #aging (trx_ctrl_num, date_aging, date_due, amount)
			SELECT a.trx_ctrl_num, b.date_aging, b.date_due, b.amount
			FROM #vchrs3 a, aptrxage b
			WHERE a.trx_ctrl_num = b.trx_ctrl_num
			AND b.trx_type = 4091
			AND a.date_aging = 0
			
			IF @@rowcount > 0
			   BEGIN
				
				IF @@error != 0
					RETURN -1
				
				SELECT trx_ctrl_num, amount = SUM(amount)
				INTO #tempaging
				FROM #aging
				WHERE date_due < @from_due_date
				OR date_due > @to_due_date
				GROUP BY trx_ctrl_num
				
				IF @@error != 0
			   		RETURN -1

				
				UPDATE #vchrs3
				SET amt_to_pay = a.amt_to_pay - b.amount
				FROM #vchrs3 a, #tempaging b
				WHERE a.trx_ctrl_num = b.trx_ctrl_num
	
				IF @@error != 0
   					RETURN -1

					
				DROP TABLE #tempaging

				IF @@error != 0
					RETURN -1

			   END

	   END


	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 349, 5 ) + " -- MSG: " + "---Subtract unposted amounts"
	UPDATE #vchrs3
	SET amt_to_pay = a.amt_to_pay - b.vo_amt_applied - b.vo_amt_disc_taken,
	    amt_disc_to_take = a.amt_disc_to_take - b.vo_amt_disc_taken
	FROM #vchrs3 a, #unposted b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

	IF @@error != 0
   		RETURN -1


	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 361, 5 ) + " -- MSG: " + "---Subtract posted amounts"
	UPDATE #vchrs3
	SET amt_disc_to_take = a.amt_disc_to_take - b.vo_amt_disc_taken
	FROM #vchrs3 a, #posted b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num
	IF @@error != 0
   		RETURN -1


	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 371, 5 ) + " -- MSG: " + "---Delete fully paid vouchers"
	DELETE #vchrs3
	WHERE (((amt_to_pay) <= (0.0) + 0.0000001) AND ((amt_net) >= (0.0) - 0.0000001))
	OR (((amt_to_pay) >= (0.0) - 0.0000001) AND ((amt_net) <= (0.0) + 0.0000001))

	IF @@error != 0
   		RETURN -1


	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 381, 5 ) + " -- MSG: " + "---Update discounts less than 0.0"
	UPDATE #vchrs3
	SET amt_disc_to_take = 0.0
	WHERE ((amt_disc_to_take) < (0.0) - 0.0000001)
	IF @@error != 0
   		RETURN -1


	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 390, 5 ) + " -- MSG: " + "---Delete where discounts greater than or equal to amount to pay"
	DELETE #vchrs3
	WHERE ((amt_disc_to_take) >= (amt_to_pay) - 0.0000001) AND ((amt_net) >= (0.0) - 0.0000001)

	IF @@error != 0
   		RETURN -1


	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 399, 5 ) + " -- MSG: " + "---Subtract discounts from amount to pay"
	UPDATE #vchrs3
	SET amt_to_pay = amt_to_pay - amt_disc_to_take
	WHERE ((amt_disc_to_take) > (0.0) + 0.0000001)
	IF @@error != 0
   		RETURN -1


	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 409, 5 ) + " -- MSG: " + "---insert info into #apgpvch"
	INSERT #apgpvch (trx_ctrl_num,
					 vendor_code,
					 pay_to_code,
					 date_applied,
					 date_due,
					 ovpc_flag,
					 payment_code,
					 nat_cur_code,
					 rate_home,
					 rate_oper,
					 rate_type_home,
					 rate_type_oper,
					 amt_to_pay,
				     amt_disc_to_take,
					org_id )
	SELECT trx_ctrl_num,
		   vendor_code,
		   pay_to_code,
		   date_applied,
		   date_due,
		   ovpc_flag,
		   payment_code,
		   nat_cur_code,
		   rate_home,
		   rate_oper,
		   rate_type_home,
		   rate_type_oper,
	       amt_to_pay,
	       amt_disc_to_take,
		   org_id
	FROM #vchrs3
	IF @@error != 0
   		RETURN -1




   

	DELETE v				
	FROM #vchrs v, #vchrs2 v2
	WHERE v.trx_ctrl_num = v2.trx_ctrl_num

	
	TRUNCATE TABLE #vchrs2
	TRUNCATE TABLE #vchrs3
	TRUNCATE TABLE #posted
	TRUNCATE TABLE #unposted
	TRUNCATE TABLE #aging
END
SET ROWCOUNT 0
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 461, 5 ) + " -- MSG: " + "---End looping"


DROP TABLE #vchrs
DROP TABLE #vchrs2
DROP TABLE #vchrs3
DROP TABLE #posted
DROP TABLE #unposted
DROP TABLE #aging


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpvch.cpp" + ", line " + STR( 472, 5 ) + " -- EXIT: "
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[apgpvch_sp] TO [public]
GO

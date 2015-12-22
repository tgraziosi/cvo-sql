SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[apgppay_sp] @date_applied int,	
							@currency_code varchar(8),
							@rate_type_home varchar(8),
							@rate_type_oper varchar(8),
							@rate_home float,
							@rate_oper float,
							@debug_level smallint = 0
							WITH RECOMPILE
							

AS
DECLARE @mc_flag smallint,
		@company_code varchar(8), 
		@home_cur_code varchar(8),
		@oper_cur_code varchar(8), 
		@home_precision smallint,
		@oper_precision smallint,
		@paycur_precision smallint,
		@result int,
		@id int
	       

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 59, 5 ) + " -- ENTRY: "

SELECT @company_code = a.company_code, 
	   @home_cur_code = a.home_currency,
	   @oper_cur_code = a.oper_currency,
	   @home_precision = b.curr_precision,
	   @oper_precision =  c.curr_precision
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code

SELECT @paycur_precision = curr_precision
FROM glcurr_vw
WHERE currency_code = @currency_code

SELECT @mc_flag = mc_flag FROM apco


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 77, 5 ) + " -- MSG: " + "---Create #vndrs"
CREATE TABLE #vndrs (vendor_code varchar(12),
		     pay_to_code varchar(8))
IF @@error != 0
   RETURN -1

CREATE CLUSTERED INDEX vndrs_ind_1 ON #vndrs (vendor_code, pay_to_code)
IF @@error != 0
   RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 88, 5 ) + " -- MSG: " + "---Insert #vndrs"
INSERT #vndrs
SELECT DISTINCT vendor_code,
		pay_to_code
FROM #apgpvch
IF @@error != 0
   RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 97, 5 ) + " -- MSG: " + "---Create temp tables"

CREATE TABLE #vndrs2 (vendor_code varchar(12), pay_to_code varchar(8))
IF @@error != 0
   RETURN -1

CREATE TABLE #payd (id int,
		    vendor_code varchar(12), 
		    pay_to_code varchar(8),
		    apply_to_num varchar(16),
		    date_applied int,
			date_due int,
		    ovpc_flag smallint,
			payment_code varchar(8),
		    nat_cur_code varchar(8),
		    vo_rate_home float,
		    vo_rate_oper float,	
		    rate_type_home varchar(8),
		    rate_type_oper varchar(8),
		    vo_amt_applied float,
		    vo_amt_disc_taken float,
		    amt_applied float,
		    amt_disc_taken float,
		    gain_home float,
		    gain_oper float,
		    cross_rate float,
		    org_id varchar(30) NULL)
IF @@error != 0
   RETURN -1

CREATE TABLE #payh (id int,
					vendor_code varchar(12), 
					pay_to_code varchar(8),
					payment_code varchar(8),
					amt_payment float,
					amt_disc_taken float,
					printed_flag smallint,
					hold_flag smallint)
IF @@error != 0
   RETURN -1


CREATE TABLE #rates (from_currency varchar(8),
		     to_currency varchar(8),
		     rate_type varchar(8),
		     date_applied int,
		     rate float )
IF @@error != 0
   RETURN -1



CREATE TABLE #temp1
	( apply_to_num varchar(16),
	  num numeric identity,
	  id int )
IF @@error != 0
   RETURN -1

CREATE TABLE #temp2
	( vendor_code varchar(12),
	  pay_to_code varchar(8),
	  payment_code varchar(8),
	  num numeric identity,
	  id int )
IF @@error != 0
   RETURN -1

SELECT @id = 0

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 167, 5 ) + " -- MSG: " + "---Begin vendors loop"

WHILE (1=1)
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 171, 5 ) + " -- MSG: " + "---Insert #vndrs2"
       
	SET ROWCOUNT 250
	INSERT #vndrs2 (vendor_code, pay_to_code)
	SELECT vendor_code, pay_to_code
	FROM #vndrs
        order by vendor_code,pay_to_code                 
	
	IF @@rowcount = 0 BREAK
	SET ROWCOUNT 0

	IF @@error != 0
   		RETURN -1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 185, 5 ) + " -- MSG: " + "---Insert #payd"

	INSERT #payd (id,
		      vendor_code,
		      pay_to_code,
		      apply_to_num,
		      date_applied,
			  date_due,
		      ovpc_flag,
			  payment_code,
		      nat_cur_code,
		      vo_rate_home,
		      vo_rate_oper,
		      rate_type_home,
		      rate_type_oper,
		      vo_amt_applied,
		      vo_amt_disc_taken,
		      amt_applied,
		      amt_disc_taken,
		      gain_home,
		      gain_oper,
		      cross_rate,
		      org_id)
	SELECT 0,
	       b.vendor_code,
	       b.pay_to_code,
	       b.trx_ctrl_num,
		   (sign((sign(b.date_applied - @date_applied + 0.00000001) + 1)) * b.date_applied + sign((sign(@date_applied - b.date_applied - 0.00000001) + 1)) * @date_applied),
		   b.date_due,
	       b.ovpc_flag,
		   b.payment_code,
	       b.nat_cur_code,
	       b.rate_home,
	       b.rate_oper,
	       b.rate_type_home,
	       b.rate_type_oper,
	       b.amt_to_pay,
	       b.amt_disc_to_take,
	       b.amt_to_pay,
	       b.amt_disc_to_take,
	       0.0,
	       0.0,
	       1.0,
	       b.org_id
	FROM #vndrs2 a, #apgpvch b 
	WHERE a.vendor_code = b.vendor_code
	AND a.pay_to_code = b.pay_to_code
	IF @@error != 0
	   RETURN -1



	IF (@mc_flag = 1)
        BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 239, 5 ) + " -- MSG: " + "---Get cross rates"

		INSERT #rates (from_currency,
			       to_currency,
			       rate_type,
			       date_applied,
			       rate )
		SELECT DISTINCT
			       nat_cur_code,
			       @home_cur_code,
			       rate_type_home,
			       date_applied,
			       0.0
		FROM #payd
		WHERE nat_cur_code != @currency_code	

		IF @@rowcount > 0
		    BEGIN

			IF @@error != 0
			   RETURN -1
					
			INSERT #rates (from_currency,
				       to_currency,
				       rate_type,
				       date_applied,
				       rate )
			SELECT DISTINCT
				       @currency_code,
				       @home_cur_code,
				       @rate_type_home,
				       date_applied,
				       0.0
			FROM #payd
			WHERE nat_cur_code != @currency_code	
			IF @@error != 0
			   RETURN -1

			EXEC @result = CVO_Control..mcrates_sp
			IF @result != 0
				RETURN -7

			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 281, 5 ) + " -- MSG: " + "---Update #payd with cross rates"
			UPDATE #payd
			SET cross_rate = ( SIGN(1 + SIGN(c.rate))*(c.rate) + (SIGN(ABS(SIGN(ROUND(c.rate,6))))/(c.rate + SIGN(1 - ABS(SIGN(ROUND(c.rate,6)))))) * SIGN(SIGN(c.rate) - 1) )/( SIGN(1 + SIGN(d.rate))*(d.rate) + (SIGN(ABS(SIGN(ROUND(d.rate,6))))/(d.rate + SIGN(1 - ABS(SIGN(ROUND(d.rate,6)))))) * SIGN(SIGN(d.rate) - 1) )
			FROM #payd a, #rates c, #rates d
			WHERE a.nat_cur_code = c.from_currency
			AND a.rate_type_home = c.rate_type
			AND a.date_applied = c.date_applied
			AND d.from_currency = @currency_code
			AND d.rate_type = @rate_type_home
			AND a.date_applied = d.date_applied
			AND a.nat_cur_code != @currency_code
			AND d.rate != 0.0

			IF @@error != 0
			   RETURN -1


			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 298, 5 ) + " -- MSG: " + "---Update amt_applied and amt_disc_taken in #payd"
			UPDATE #payd
			SET amt_applied = (SIGN(vo_amt_applied * ( SIGN(1 + SIGN(cross_rate))*(cross_rate) + (SIGN(ABS(SIGN(ROUND(cross_rate,6))))/(cross_rate + SIGN(1 - ABS(SIGN(ROUND(cross_rate,6)))))) * SIGN(SIGN(cross_rate) - 1) )) * ROUND(ABS(vo_amt_applied * ( SIGN(1 + SIGN(cross_rate))*(cross_rate) + (SIGN(ABS(SIGN(ROUND(cross_rate,6))))/(cross_rate + SIGN(1 - ABS(SIGN(ROUND(cross_rate,6)))))) * SIGN(SIGN(cross_rate) - 1) )) + 0.0000001, @paycur_precision)),
			    amt_disc_taken = (SIGN(vo_amt_disc_taken * ( SIGN(1 + SIGN(cross_rate))*(cross_rate) + (SIGN(ABS(SIGN(ROUND(cross_rate,6))))/(cross_rate + SIGN(1 - ABS(SIGN(ROUND(cross_rate,6)))))) * SIGN(SIGN(cross_rate) - 1) )) * ROUND(ABS(vo_amt_disc_taken * ( SIGN(1 + SIGN(cross_rate))*(cross_rate) + (SIGN(ABS(SIGN(ROUND(cross_rate,6))))/(cross_rate + SIGN(1 - ABS(SIGN(ROUND(cross_rate,6)))))) * SIGN(SIGN(cross_rate) - 1) )) + 0.0000001, @paycur_precision))
			WHERE cross_rate != 1.0
			IF @@error != 0
			   RETURN -1

		END
	      



		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 311, 5 ) + " -- MSG: " + "---Update gain/loss amounts"
		UPDATE #payd
		SET gain_home = (SIGN(vo_amt_applied * ( SIGN(1 + SIGN(vo_rate_home))*(vo_rate_home) + (SIGN(ABS(SIGN(ROUND(vo_rate_home,6))))/(vo_rate_home + SIGN(1 - ABS(SIGN(ROUND(vo_rate_home,6)))))) * SIGN(SIGN(vo_rate_home) - 1) )) * ROUND(ABS(vo_amt_applied * ( SIGN(1 + SIGN(vo_rate_home))*(vo_rate_home) + (SIGN(ABS(SIGN(ROUND(vo_rate_home,6))))/(vo_rate_home + SIGN(1 - ABS(SIGN(ROUND(vo_rate_home,6)))))) * SIGN(SIGN(vo_rate_home) - 1) )) + 0.0000001, @home_precision))
					  - (SIGN(amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @home_precision)),
		    gain_oper = (SIGN(vo_amt_applied * ( SIGN(1 + SIGN(vo_rate_oper))*(vo_rate_oper) + (SIGN(ABS(SIGN(ROUND(vo_rate_oper,6))))/(vo_rate_oper + SIGN(1 - ABS(SIGN(ROUND(vo_rate_oper,6)))))) * SIGN(SIGN(vo_rate_oper) - 1) )) * ROUND(ABS(vo_amt_applied * ( SIGN(1 + SIGN(vo_rate_oper))*(vo_rate_oper) + (SIGN(ABS(SIGN(ROUND(vo_rate_oper,6))))/(vo_rate_oper + SIGN(1 - ABS(SIGN(ROUND(vo_rate_oper,6)))))) * SIGN(SIGN(vo_rate_oper) - 1) )) + 0.0000001, @oper_precision))
					  - (SIGN(amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) * ROUND(ABS(amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) + 0.0000001, @oper_precision))
		FROM #payd
		IF @@error != 0
		   RETURN -1
			

			
	    END	

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 326, 5 ) + " -- MSG: " + "---Calculate id for ovpc vouchers"
	INSERT #temp1 (apply_to_num,
		       id )
	SELECT apply_to_num,
	       0
	FROM #payd
	WHERE ovpc_flag = 1
	
	IF @@rowcount > 0
             BEGIN
				IF @@error != 0
				   RETURN -1
	
				UPDATE #temp1
				SET id = num + @id		
				
				UPDATE #payd
				SET id = b.id
				FROM #payd a, #temp1 b
				WHERE a.apply_to_num = b.apply_to_num
				AND a.ovpc_flag = 1
			
				IF @@error != 0
				   RETURN -1

				SELECT @id = @id + @@identity
		     END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 354, 5 ) + " -- MSG: " + "---Calculate id for non-ovpc vouchers"
	INSERT #temp2 (vendor_code,
		       pay_to_code,
		       payment_code,	
		       id )
	SELECT DISTINCT vendor_code,
	       		pay_to_code,
				payment_code,
	       		0
	FROM #payd
	WHERE ovpc_flag = 0


	IF @@rowcount > 0
             BEGIN
				IF @@error != 0
				   RETURN -1

				UPDATE #temp2
				SET id = num + @id		
				
				UPDATE #payd
				SET id = b.id
				FROM #payd a, #temp2 b
				WHERE a.vendor_code = b.vendor_code
				AND a.pay_to_code = b.pay_to_code
				AND a.payment_code = b.payment_code
				AND a.ovpc_flag = 0
				
				IF @@error != 0
				   RETURN -1

				SELECT @id = @id + @@identity
		     END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 389, 5 ) + " -- MSG: " + "---Insert #payh"
	INSERT #payh (
			id,
			vendor_code,
			pay_to_code,
			payment_code,
			amt_payment,
			amt_disc_taken,
			printed_flag,
			hold_flag
			)
	SELECT id,
		   vendor_code,
		   pay_to_code,
		   payment_code,
		   SUM(amt_applied),
	       SUM(amt_disc_taken),
		   0,
		   MAX(ABS(SIGN(ABS(cross_rate))-1))
	FROM #payd
	GROUP BY id,vendor_code,pay_to_code,payment_code

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 411, 5 ) + " -- MSG: " + "---Update printed flag"
	UPDATE #payh
	SET printed_flag = case b.payment_type 	
					when 1 then 2			
					when 3 then 4			
	            end							
	FROM #payh a, appymeth b
	WHERE a.payment_code = b.payment_code
	AND b.payment_type != 2

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 421, 5 ) + " -- MSG: " + "---Update hold_flag"
	UPDATE #payh
	SET hold_flag = 1
	FROM #payh a, appymeth b
	WHERE a.payment_code = b.payment_code
	AND b.payment_type = 1


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 429, 5 ) + " -- MSG: " + "---Insert #pay_header"
	INSERT #pay_header (
       id,
	   trx_ctrl_num,
	   vendor_code,
	   pay_to_code,
	   payment_code,
	   amt_payment,
	   amt_disc_taken,
	   printed_flag,
	   hold_flag  )
	SELECT id,
		   "",	
		   vendor_code,
		   pay_to_code,
		   payment_code,
		   amt_payment,
		   amt_disc_taken,
		   printed_flag,
		   hold_flag
	 FROM #payh


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 452, 5 ) + " -- MSG: " + "---Insert #pay_detail"
	INSERT #pay_detail  (
	  id,
	  trx_ctrl_num,
	  sequence_id,
	  apply_to_num,
	  amt_applied,
	  amt_disc_taken,
	  vo_amt_applied,
	  vo_amt_disc_taken,
	  gain_home,
	  gain_oper,
	  nat_cur_code,
	  vendor_code,
	  date_due,
	  cross_rate,
	  org_id
	  )
	SELECT id,
		   "",
		   0,	
	       apply_to_num,
	       amt_applied,
	       amt_disc_taken,
	       vo_amt_applied,
	       vo_amt_disc_taken,
	       gain_home,
	       gain_oper,
	       nat_cur_code,
		   vendor_code,
		   date_due,
		   cross_rate,
		   org_id
	FROM #payd
	IF @@error != 0
		   RETURN -1


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 490, 5 ) + " -- MSG: " + "---Delete #vndrs"
	SET ROWCOUNT 250
	DELETE #vndrs
	FROM	#vndrs a, #vndrs2 b				
        WHERE 	a.vendor_code = b.vendor_code			
	and	a.pay_to_code = b.pay_to_code 			
	SET ROWCOUNT 0

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 499, 5 ) + " -- MSG: " + "---Truncate temp tables"

	TRUNCATE TABLE #vndrs2
	TRUNCATE TABLE #payd
	TRUNCATE TABLE #payh
	TRUNCATE TABLE #rates
	TRUNCATE TABLE #temp1
	TRUNCATE TABLE #temp2
END
SET ROWCOUNT 0
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 509, 5 ) + " -- MSG: " + "---End Looping"

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 511, 5 ) + " -- MSG: " + "---Drop Temp tables"
DROP TABLE #payd
DROP TABLE #payh
DROP TABLE #vndrs2
DROP TABLE #rates
DROP TABLE #temp1
DROP TABLE #temp2
DROP TABLE #vndrs

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgppay.cpp" + ", line " + STR( 520, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apgppay_sp] TO [public]
GO

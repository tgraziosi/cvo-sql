SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apgoaply_sp]   @debug_level smallint = 0
WITH RECOMPILE

AS

   DECLARE			@num_vouch int,
					@num_oa int,
					@vouch_rec int,
					@oa_rec int,
   					@next_vo smallint,
					@next_oa smallint,
				    @vo_vendor_code varchar(12),
					@vo_pay_to_code varchar(8),
					@vo_nat_cur_code varchar(8),
					@vo_date_applied int,
					@vo_rate_type_home varchar(8),
					@vo_amt_to_pay float,
					@vo_amt_disc_to_take float,
					@vo_trx_ctrl_num varchar(16),
					@vo_rate_home float,
					@vo_rate_oper float,
					@oa_vendor_code varchar(12),
					@oa_pay_to_code varchar(8),
					@oa_nat_cur_code varchar(8),
					@oa_date_applied int,
					@oa_rate_type_home varchar(8),
					@oa_amt_on_acct float,
					@oa_cash_acct_code varchar(32),
					@oa_doc_ctrl_num varchar(16),
					@oa_rate_home float,
					@oa_rate_oper float,
					@cross_rate float,
					@vouch_to_home float,
					@pay_to_home float,
					@date_applied int,
					@home_cur_code varchar(8),
					@pay_amt_to_pay float,
					@pay_amt_disc_to_take float,
					@vouch_amt_to_pay float,
					@home_precision smallint,
					@oper_precision smallint,
					@vo_org_id varchar(30)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgoaply.cpp" + ", line " + STR( 82, 5 ) + " -- ENTRY: "

SELECT @home_cur_code = home_currency,
	   @home_precision = b.curr_precision,
	   @oper_precision = c.curr_precision
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code

























































SELECT @num_vouch = COUNT(*) FROM #apgpvch
SELECT @num_oa = COUNT(*) FROM #apgooa
SELECT @vouch_rec = 0,
	   @oa_rec = 0,
	   @next_vo = 1,
	   @next_oa = 1

DECLARE vo_cursor CURSOR
   FOR SELECT  
   		vendor_code,
		pay_to_code,
		nat_cur_code,
		date_applied,
		rate_type_home,
		amt_to_pay,
		amt_disc_to_take,
		trx_ctrl_num,
		rate_home,
		rate_oper,
		org_id
   FROM #apgpvch

DECLARE oa_cursor CURSOR
   FOR SELECT
		vendor_code,
		pay_to_code,
		nat_cur_code,
		date_applied,
		rate_type_home,
		amt_on_acct,
		cash_acct_code,
		doc_ctrl_num,
		rate_home,
		rate_oper
   FROM #apgooa

OPEN vo_cursor
OPEN oa_cursor

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgoaply.cpp" + ", line " + STR( 186, 5 ) + " -- MSG: " + "---Begin match oas to vouchers"
WHILE (1=1)
BEGIN
   IF (@next_vo = 1)
      BEGIN
		 SELECT @vouch_rec = @vouch_rec + 1
		 IF (@vouch_rec > @num_vouch) BREAK
		 FETCH vo_cursor
		 INTO   @vo_vendor_code,
				@vo_pay_to_code,
				@vo_nat_cur_code,
				@vo_date_applied,
				@vo_rate_type_home,
				@vo_amt_to_pay,
				@vo_amt_disc_to_take,
				@vo_trx_ctrl_num,
				@vo_rate_home,
				@vo_rate_oper,
				@vo_org_id

		 SELECT @next_vo = 0
	  END
   IF (@next_oa = 1)
      BEGIN
		 SELECT @oa_rec = @oa_rec + 1
		 IF (@oa_rec > @num_oa) BREAK
		 FETCH oa_cursor
		 INTO	@oa_vendor_code,
				@oa_pay_to_code,
				@oa_nat_cur_code,
				@oa_date_applied,
				@oa_rate_type_home,
				@oa_amt_on_acct,
				@oa_cash_acct_code,
				@oa_doc_ctrl_num,
				@oa_rate_home,
				@oa_rate_oper

		 SELECT @next_oa = 0
	  END
   

   IF ((@vo_vendor_code < @oa_vendor_code) OR
       (@vo_vendor_code = @oa_vendor_code AND @vo_pay_to_code < @oa_pay_to_code))
	  BEGIN
		 SELECT @next_vo = 1
		 CONTINUE
	  END
   IF ((@oa_vendor_code < @vo_vendor_code) OR
       (@oa_vendor_code = @vo_vendor_code AND @oa_pay_to_code < @vo_pay_to_code))
	  BEGIN
		 SELECT @next_oa = 1
		 CONTINUE
	  END
   

   IF (@vo_nat_cur_code = @oa_nat_cur_code)
      SELECT @cross_rate = 1
   ELSE
	  BEGIN
		  IF @oa_date_applied > @vo_date_applied
		     SELECT @date_applied = @oa_date_applied
		  ELSE 
		     SELECT @date_applied = @vo_date_applied

	      
	      SELECT @vouch_to_home = 0.0,
				 @pay_to_home = 0.0
	      EXEC CVO_Control..mccurate_sp @date_applied,
									 @vo_nat_cur_code,
									 @home_cur_code,
									 @vo_rate_type_home,
									 @vouch_to_home OUTPUT,
									 0

		  IF (ABS((@vouch_to_home)-(0.0)) < 0.0000001)
		     BEGIN
			     SELECT @next_vo = 1
				 CONTINUE
			 END
	
	      EXEC CVO_Control..mccurate_sp @date_applied,
									 @oa_nat_cur_code,
									 @home_cur_code,
									 @oa_rate_type_home,
									 @pay_to_home OUTPUT,
									 0

		  IF (ABS((@pay_to_home)-(0.0)) < 0.0000001)
		     BEGIN
			     SELECT @next_oa = 1
				 CONTINUE
			 END


		  IF (ABS((@pay_to_home)-(0.0)) > 0.0000001)
	          SELECT @cross_rate = ( SIGN(1 + SIGN(@vouch_to_home))*(@vouch_to_home) + (SIGN(ABS(SIGN(ROUND(@vouch_to_home,6))))/(@vouch_to_home + SIGN(1 - ABS(SIGN(ROUND(@vouch_to_home,6)))))) * SIGN(SIGN(@vouch_to_home) - 1) )/( SIGN(1 + SIGN(@pay_to_home))*(@pay_to_home) + (SIGN(ABS(SIGN(ROUND(@pay_to_home,6))))/(@pay_to_home + SIGN(1 - ABS(SIGN(ROUND(@pay_to_home,6)))))) * SIGN(SIGN(@pay_to_home) - 1) )
	  END


   SELECT @pay_amt_to_pay = (SIGN(@vo_amt_to_pay * @cross_rate) * ROUND(ABS(@vo_amt_to_pay * @cross_rate) + 0.0000001, curr_precision)),
          @pay_amt_disc_to_take = (SIGN(@vo_amt_disc_to_take * @cross_rate) * ROUND(ABS(@vo_amt_disc_to_take * @cross_rate) + 0.0000001, curr_precision))
   FROM glcurr_vw
   WHERE currency_code = @oa_nat_cur_code



   IF ( (ABS((@oa_amt_on_acct)-(@pay_amt_to_pay)) < 0.0000001) )
      BEGIN
		 INSERT #pay_detail  (
			 vendor_code,
			 pay_to_code,
			 apply_to_num,
			 amt_applied,		
			 amt_disc_taken,
			 cash_acct_code,
			 doc_ctrl_num,
			 vo_amt_applied,
			 vo_amt_disc_taken,
			 gain_home,
			 gain_oper,
			 nat_cur_code,
			 inserted,
			 org_id	
			 )	 
		  VALUES  (
		     @vo_vendor_code,
			 @vo_pay_to_code,
			 @vo_trx_ctrl_num,
			 @pay_amt_to_pay,
			 @pay_amt_disc_to_take,
			 @oa_cash_acct_code,
			 @oa_doc_ctrl_num,
			 @vo_amt_to_pay,
			 @vo_amt_disc_to_take,
			 (SIGN(@vo_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_home))*(@vo_rate_home) + (SIGN(ABS(SIGN(ROUND(@vo_rate_home,6))))/(@vo_rate_home + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_home,6)))))) * SIGN(SIGN(@vo_rate_home) - 1) )) * ROUND(ABS(@vo_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_home))*(@vo_rate_home) + (SIGN(ABS(SIGN(ROUND(@vo_rate_home,6))))/(@vo_rate_home + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_home,6)))))) * SIGN(SIGN(@vo_rate_home) - 1) )) + 0.0000001, @home_precision))
			 - (SIGN(@pay_amt_to_pay * ( SIGN(1 + SIGN(@oa_rate_home))*(@oa_rate_home) + (SIGN(ABS(SIGN(ROUND(@oa_rate_home,6))))/(@oa_rate_home + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_home,6)))))) * SIGN(SIGN(@oa_rate_home) - 1) )) * ROUND(ABS(@pay_amt_to_pay * ( SIGN(1 + SIGN(@oa_rate_home))*(@oa_rate_home) + (SIGN(ABS(SIGN(ROUND(@oa_rate_home,6))))/(@oa_rate_home + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_home,6)))))) * SIGN(SIGN(@oa_rate_home) - 1) )) + 0.0000001, @home_precision)),
			 (SIGN(@vo_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_oper))*(@vo_rate_oper) + (SIGN(ABS(SIGN(ROUND(@vo_rate_oper,6))))/(@vo_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_oper,6)))))) * SIGN(SIGN(@vo_rate_oper) - 1) )) * ROUND(ABS(@vo_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_oper))*(@vo_rate_oper) + (SIGN(ABS(SIGN(ROUND(@vo_rate_oper,6))))/(@vo_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_oper,6)))))) * SIGN(SIGN(@vo_rate_oper) - 1) )) + 0.0000001, @oper_precision))
				- (SIGN(@pay_amt_to_pay * ( SIGN(1 + SIGN(@oa_rate_oper))*(@oa_rate_oper) + (SIGN(ABS(SIGN(ROUND(@oa_rate_oper,6))))/(@oa_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_oper,6)))))) * SIGN(SIGN(@oa_rate_oper) - 1) )) * ROUND(ABS(@pay_amt_to_pay * ( SIGN(1 + SIGN(@oa_rate_oper))*(@oa_rate_oper) + (SIGN(ABS(SIGN(ROUND(@oa_rate_oper,6))))/(@oa_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_oper,6)))))) * SIGN(SIGN(@oa_rate_oper) - 1) )) + 0.0000001, @oper_precision)),
			 @vo_nat_cur_code,
			 0,
			 @vo_org_id
			 )
		  
		  IF @@error <> 0
   				RETURN -1

		  SELECT @next_oa = 1
		  SELECT @next_vo = 1

          CONTINUE
      END

   IF ( ((@oa_amt_on_acct) < (@pay_amt_to_pay) - 0.0000001) )
      BEGIN

		 SELECT @vouch_amt_to_pay = (SIGN(@oa_amt_on_acct/@cross_rate) * ROUND(ABS(@oa_amt_on_acct/@cross_rate) + 0.0000001, curr_precision))
		 FROM glcurr_vw
		 WHERE currency_code = @vo_nat_cur_code

		 INSERT #pay_detail  (
			 vendor_code,
			 pay_to_code,
			 apply_to_num,
			 amt_applied,		
			 amt_disc_taken,
			 cash_acct_code,
			 doc_ctrl_num,
			 vo_amt_applied,
			 vo_amt_disc_taken,
			 gain_home,
			 gain_oper,
			 nat_cur_code,
			 inserted,
   			 org_id	
			 )	 
		  VALUES  (
		     @vo_vendor_code,
			 @vo_pay_to_code,
			 @vo_trx_ctrl_num,
			 @oa_amt_on_acct,
			 @pay_amt_disc_to_take,
			 @oa_cash_acct_code,
			 @oa_doc_ctrl_num,
			 @vouch_amt_to_pay,
			 @vo_amt_disc_to_take,
			 (SIGN(@vouch_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_home))*(@vo_rate_home) + (SIGN(ABS(SIGN(ROUND(@vo_rate_home,6))))/(@vo_rate_home + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_home,6)))))) * SIGN(SIGN(@vo_rate_home) - 1) )) * ROUND(ABS(@vouch_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_home))*(@vo_rate_home) + (SIGN(ABS(SIGN(ROUND(@vo_rate_home,6))))/(@vo_rate_home + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_home,6)))))) * SIGN(SIGN(@vo_rate_home) - 1) )) + 0.0000001, @home_precision))
			 - (SIGN(@oa_amt_on_acct * ( SIGN(1 + SIGN(@oa_rate_home))*(@oa_rate_home) + (SIGN(ABS(SIGN(ROUND(@oa_rate_home,6))))/(@oa_rate_home + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_home,6)))))) * SIGN(SIGN(@oa_rate_home) - 1) )) * ROUND(ABS(@oa_amt_on_acct * ( SIGN(1 + SIGN(@oa_rate_home))*(@oa_rate_home) + (SIGN(ABS(SIGN(ROUND(@oa_rate_home,6))))/(@oa_rate_home + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_home,6)))))) * SIGN(SIGN(@oa_rate_home) - 1) )) + 0.0000001, @home_precision)),
			 (SIGN(@vouch_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_oper))*(@vo_rate_oper) + (SIGN(ABS(SIGN(ROUND(@vo_rate_oper,6))))/(@vo_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_oper,6)))))) * SIGN(SIGN(@vo_rate_oper) - 1) )) * ROUND(ABS(@vouch_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_oper))*(@vo_rate_oper) + (SIGN(ABS(SIGN(ROUND(@vo_rate_oper,6))))/(@vo_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_oper,6)))))) * SIGN(SIGN(@vo_rate_oper) - 1) )) + 0.0000001, @oper_precision))
				- (SIGN(@oa_amt_on_acct * ( SIGN(1 + SIGN(@oa_rate_oper))*(@oa_rate_oper) + (SIGN(ABS(SIGN(ROUND(@oa_rate_oper,6))))/(@oa_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_oper,6)))))) * SIGN(SIGN(@oa_rate_oper) - 1) )) * ROUND(ABS(@oa_amt_on_acct * ( SIGN(1 + SIGN(@oa_rate_oper))*(@oa_rate_oper) + (SIGN(ABS(SIGN(ROUND(@oa_rate_oper,6))))/(@oa_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_oper,6)))))) * SIGN(SIGN(@oa_rate_oper) - 1) )) + 0.0000001, @oper_precision)),
			 @vo_nat_cur_code,
			 0,
			 @vo_org_id
			 )
		  IF @@error <> 0
			   RETURN -1

		 SELECT @pay_amt_to_pay = @pay_amt_to_pay - @oa_amt_on_acct
		 SELECT @vo_amt_to_pay = @vo_amt_to_pay - @vouch_amt_to_pay
		 SELECT @vo_amt_disc_to_take = 0.0
		 SELECT @pay_amt_disc_to_take = 0.0
	     
		 SELECT @next_oa = 1

		  CONTINUE
	  END
      
   IF ( ((@oa_amt_on_acct) > (@pay_amt_to_pay) + 0.0000001) )
      BEGIN

		 INSERT #pay_detail  (
			 vendor_code,
			 pay_to_code,
			 apply_to_num,
			 amt_applied,		
			 amt_disc_taken,
			 cash_acct_code,
			 doc_ctrl_num,
			 vo_amt_applied,
			 vo_amt_disc_taken,
			 gain_home,
			 gain_oper,
			 nat_cur_code,
			 inserted,
			 org_id	
			 )	 
		  VALUES  (
		     @vo_vendor_code,
			 @vo_pay_to_code,
			 @vo_trx_ctrl_num,
			 @pay_amt_to_pay,
			 @pay_amt_disc_to_take,
			 @oa_cash_acct_code,
			 @oa_doc_ctrl_num,
			 @vo_amt_to_pay,
			 @vo_amt_disc_to_take,
			 (SIGN(@vo_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_home))*(@vo_rate_home) + (SIGN(ABS(SIGN(ROUND(@vo_rate_home,6))))/(@vo_rate_home + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_home,6)))))) * SIGN(SIGN(@vo_rate_home) - 1) )) * ROUND(ABS(@vo_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_home))*(@vo_rate_home) + (SIGN(ABS(SIGN(ROUND(@vo_rate_home,6))))/(@vo_rate_home + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_home,6)))))) * SIGN(SIGN(@vo_rate_home) - 1) )) + 0.0000001, @home_precision))
			 - (SIGN(@pay_amt_to_pay * ( SIGN(1 + SIGN(@oa_rate_home))*(@oa_rate_home) + (SIGN(ABS(SIGN(ROUND(@oa_rate_home,6))))/(@oa_rate_home + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_home,6)))))) * SIGN(SIGN(@oa_rate_home) - 1) )) * ROUND(ABS(@pay_amt_to_pay * ( SIGN(1 + SIGN(@oa_rate_home))*(@oa_rate_home) + (SIGN(ABS(SIGN(ROUND(@oa_rate_home,6))))/(@oa_rate_home + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_home,6)))))) * SIGN(SIGN(@oa_rate_home) - 1) )) + 0.0000001, @home_precision)),
			 (SIGN(@vo_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_oper))*(@vo_rate_oper) + (SIGN(ABS(SIGN(ROUND(@vo_rate_oper,6))))/(@vo_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_oper,6)))))) * SIGN(SIGN(@vo_rate_oper) - 1) )) * ROUND(ABS(@vo_amt_to_pay * ( SIGN(1 + SIGN(@vo_rate_oper))*(@vo_rate_oper) + (SIGN(ABS(SIGN(ROUND(@vo_rate_oper,6))))/(@vo_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@vo_rate_oper,6)))))) * SIGN(SIGN(@vo_rate_oper) - 1) )) + 0.0000001, @oper_precision))
				- (SIGN(@pay_amt_to_pay * ( SIGN(1 + SIGN(@oa_rate_oper))*(@oa_rate_oper) + (SIGN(ABS(SIGN(ROUND(@oa_rate_oper,6))))/(@oa_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_oper,6)))))) * SIGN(SIGN(@oa_rate_oper) - 1) )) * ROUND(ABS(@pay_amt_to_pay * ( SIGN(1 + SIGN(@oa_rate_oper))*(@oa_rate_oper) + (SIGN(ABS(SIGN(ROUND(@oa_rate_oper,6))))/(@oa_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@oa_rate_oper,6)))))) * SIGN(SIGN(@oa_rate_oper) - 1) )) + 0.0000001, @oper_precision)),
			 @vo_nat_cur_code,
			 0,
			 @vo_org_id
			 )

		 IF @@error <> 0
			   RETURN -1

		 SELECT @oa_amt_on_acct = @oa_amt_on_acct - @pay_amt_to_pay
	     
		  SELECT @next_vo = 1

		  CONTINUE
	  END


END
SET ROWCOUNT 0


CLOSE vo_cursor
CLOSE oa_cursor



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgoaply.cpp" + ", line " + STR( 451, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apgoaply_sp] TO [public]
GO

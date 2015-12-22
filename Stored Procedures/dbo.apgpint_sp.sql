SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[apgpint_sp] @cash_acct_code varchar(32), 
							@date_applied int,
							@user_id smallint,
							@currency_code varchar(8),
							@rate_type_home varchar(8),
							@rate_type_oper varchar(8),
							@rate_home float,
							@rate_oper float,
							@debug_level smallint = 0
							WITH RECOMPILE 	
AS
	DECLARE @num_payments int,
			@next_num int,
			@x int,
			@trx_ctrl_num varchar(16),
			@mask varchar(16),
			@err smallint,
			@pounds_exist smallint,
			@mask_prefix varchar(16),
			@num_length smallint,
			@current_date int,
			@approval_code varchar(8),
			@aprv_check_flag smallint,
			@gen_id int,
			@company_code varchar(8),
			@home_cur_code varchar(8),
			@oper_cur_code varchar(8),
			@num_exist smallint,
			@first_num varchar(16),
			@last_num varchar(16),
			@last_num_int int,
			@result int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpint.cpp" + ", line " + STR( 70, 5 ) + " -- ENTRY: "


EXEC appdate_sp @current_date OUTPUT



SELECT  @aprv_check_flag = aprv_check_flag,
		@approval_code = default_aprv_code
FROM    apco

SELECT @company_code = company_code,
	   @home_cur_code = home_currency,
	   @oper_cur_code = oper_currency
FROM glco



IF @aprv_check_flag = 0
	SELECT @approval_code = " "


SELECT @num_payments = COUNT(*)
FROM #pay_header

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpint.cpp" + ", line " + STR( 95, 5 ) + " -- MSG: " + "---Get control nums"
BEGIN TRAN
UPDATE apnumber
SET next_cash_disb_num = next_cash_disb_num + @num_payments,
	next_gen_id = next_gen_id + 1


SELECT @next_num = next_cash_disb_num - @num_payments,
	   @mask = cash_disb_num_mask,
	   @gen_id = next_gen_id
FROM apnumber
COMMIT TRAN

CREATE TABLE #numbers
( 
  sequence int identity,
  id int,
  trx_ctrl_num varchar(16)
)


INSERT #numbers (
					id,
					trx_ctrl_num
				)
SELECT  id,
		""
FROM #pay_header

CREATE UNIQUE CLUSTERED INDEX numb ON #numbers (sequence)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpint.cpp" + ", line " + STR( 127, 5 ) + " -- MSG: " + "---Format control nums"

SELECT @pounds_exist = SIGN(PATINDEX("%[#]%",@mask))

IF @pounds_exist != 1
   BEGIN
		EXEC fmtctlnm_sp @next_num, @mask, @first_num OUTPUT, @err OUTPUT
		SELECT @last_num_int = @next_num + @num_payments
		EXEC fmtctlnm_sp @last_num_int, @mask, @last_num OUTPUT, @err OUTPUT


		IF EXISTS (SELECT * FROM appyhdr WHERE trx_ctrl_num BETWEEN @first_num AND @last_num)
			    SELECT @num_exist = 1

		IF EXISTS (SELECT * FROM apinppyt WHERE trx_ctrl_num BETWEEN @first_num AND @last_num)
			    SELECT @num_exist = 1
	END

IF (@pounds_exist = 1) OR (@num_exist = 1)
BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpint.cpp" + ", line " + STR( 147, 5 ) + " -- MSG: " + "---Calling apnewnum_sp"

	UPDATE apnumber
	SET next_cash_disb_num = @next_num

	SELECT @x = 0
	WHILE (@x <= @num_payments)
	BEGIN
	   
	   EXEC apnewnum_sp 4111, @company_code, @trx_ctrl_num OUTPUT
	   
	   UPDATE #numbers 
	   SET trx_ctrl_num = @trx_ctrl_num
	   WHERE sequence = @x



	   SELECT @next_num = @next_num + 1
	   SELECT @x = @x + 1
	END
END
 ELSE
   BEGIN
	  SELECT @mask_prefix = SUBSTRING(@mask,1,PATINDEX("%0%",@mask)-1)
	  SELECT @num_length = DATALENGTH(@mask) - DATALENGTH(@mask_prefix)
	  UPDATE #numbers
	  SET trx_ctrl_num = @mask_prefix + RIGHT("0000000000000000" + CONVERT(varchar(16),sequence+@next_num - 1),@num_length)

   END
					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpint.cpp" + ", line " + STR( 178, 5 ) + " -- MSG: " + "---Update control nums in #pay_header"
UPDATE #pay_header
SET trx_ctrl_num = b.trx_ctrl_num
FROM #pay_header a, #numbers b
WHERE a.id = b.id

IF @@error != 0
   RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpint.cpp" + ", line " + STR( 188, 5 ) + " -- MSG: " + "---Update control nums in #pay_detail"
UPDATE #pay_detail
SET trx_ctrl_num = b.trx_ctrl_num
FROM #pay_detail a, #numbers b
WHERE a.id = b.id

IF @@error != 0
   RETURN -1


DROP TABLE #numbers


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpint.cpp" + ", line " + STR( 201, 5 ) + " -- MSG: " + "---Calculate Sequence ids"
CREATE TABLE #seq ( 
				   sequence int identity,
				   id int,
			  	   apply_to_num varchar(16),
				   sequence_id int
				 )

INSERT #seq (id,
			apply_to_num,
			sequence_id )
SELECT id,
	   apply_to_num,
	   0
FROM #pay_detail
ORDER BY id

CREATE UNIQUE CLUSTERED INDEX seq_ind_1 ON #seq (sequence)



CREATE TABLE #temp (id int, min_sequence int)
CREATE UNIQUE CLUSTERED INDEX temp_ind_1 ON #temp (id)

INSERT #temp
(
 id,
 min_sequence )
SELECT id,
	   MIN(sequence)-1
FROM #seq
GROUP BY id

EXEC apgpseq_sp @debug_level

UPDATE #pay_detail
SET sequence_id = b.sequence_id
FROM #pay_detail a, #seq b
WHERE a.id = b.id
AND a.apply_to_num = b.apply_to_num

IF @@error != 0
   RETURN -1


DROP TABLE #seq
DROP TABLE #temp





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpint.cpp" + ", line " + STR( 253, 5 ) + " -- MSG: " + "---Insert #apinppyt"
INSERT  #apinppyt  (
	trx_ctrl_num,
    trx_type,
	doc_ctrl_num,
	trx_desc,
	batch_code,
	cash_acct_code,
	date_entered,
	date_applied,
	date_doc,
    vendor_code,
	pay_to_code,
	approval_code,
	payment_code,
	payment_type,
    amt_payment,
	amt_on_acct,
	posted_flag,
	printed_flag,
	hold_flag,
	approval_flag,
	gen_id,
	user_id,
   	void_type,
	amt_disc_taken,
	print_batch_num,
 	company_code,
	process_group_num,
	nat_cur_code,
	rate_type_home,
	rate_type_oper,
	rate_home,
	rate_oper,
	trx_state,
	org_id,
	mark_flag 
	)
SELECT  
	trx_ctrl_num,		
    4111,		
	"",		    		
	"",		    		
	"",		    		
	@cash_acct_code,	
	@current_date, 		
	@date_applied, 		
	@current_date, 		
	vendor_code,   		
	pay_to_code,   		
	@approval_code,		
	payment_code,  		
	1,		    		
	amt_payment,   		
	0.0,	    		
	0,		    		
	printed_flag,  		
	hold_flag,    		
	@aprv_check_flag,	
	@gen_id,    		
	@user_id,    		
	0,		    		
	amt_disc_taken,		
	0,		    		
	@company_code, 		
	"",		    		
	@currency_code, 	
	@rate_type_home,	
	@rate_type_oper,	
	@rate_home,   		
	@rate_oper,   		
	0,		    		
	dbo.IBOrgbyAcct_fn(@cash_acct_code),   	 
	0		    		
FROM #pay_header
WHERE amt_payment >= 0

IF @@error != 0
   RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpint.cpp" + ", line " + STR( 334, 5 ) + " -- MSG: " + "---Insert #apinppdt"
INSERT #apinppdt   (
	trx_ctrl_num,
	trx_type,
	sequence_id,
	apply_to_num,
	apply_trx_type,
	amt_applied,
	amt_disc_taken,
	line_desc,
	void_flag,
	payment_hold_flag,
	vendor_code,
	vo_amt_applied,
	vo_amt_disc_taken,
	gain_home,
	gain_oper,
	nat_cur_code,
	trx_state,
	org_id,
	mark_flag	)
SELECT 
	trx_ctrl_num,		
	4111,		
	sequence_id,		
	apply_to_num,		
	4091,		
	amt_applied,		
	amt_disc_taken,		
	"",					
	0,					
	0,					
	vendor_code,		
	vo_amt_applied,		
	vo_amt_disc_taken,	
	gain_home,			
	gain_oper,			
	nat_cur_code,		
	0,					
	org_id,					
	0					
FROM #pay_detail
WHERE trx_ctrl_num in (select trx_ctrl_num from #apinppyt )


IF @@error != 0
   RETURN -1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgpint.cpp" + ", line " + STR( 384, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apgpint_sp] TO [public]
GO

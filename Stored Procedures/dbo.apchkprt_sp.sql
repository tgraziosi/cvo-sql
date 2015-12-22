SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE  [dbo].[apchkprt_sp]  
				@print_acct_num         smallint,
				@payment_memo           smallint,
				@voucher_classification smallint,
				@voucher_comment        smallint,
				@voucher_memo           smallint,
				@expense_dist           smallint,
				@to_white_paper         smallint,
				@history_flag			smallint,
				@start_check            int,
				@cash_acct_code			varchar(32),
				@process_group_num      varchar(16),
				@lines_per_check		smallint,
				@debug_level			smallint = 0


AS
	DECLARE   
	            @print_batch_num		int,
				@result         		int,
				@check_num_mask 		varchar(16),
				@check_start_col		smallint, 
				@check_length	 		smallint,
				@trx_ctrl_num   		varchar(16),
				@last_check				int,
				@start_check_masked	 	varchar(16),
				@last_check_masked   	varchar(16),
				@voids_exist   			smallint,
				@sys_date 				int



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkprt.cpp" + ", line " + STR( 63, 5 ) + " -- ENTRY: "

IF NOT EXISTS (SELECT * FROM #check_header)
    BEGIN
	   DROP TABLE #check_header
	   RETURN -4
	END







CREATE TABLE #apchkstb
(
	vendor_code             varchar(12),
	check_num               varchar(16),
	cash_acct_code          varchar(32),            
	print_batch_num         int,
	payment_num             varchar(16),
	payment_type            smallint, 
	print_acct_num          smallint,
	payment_memo            smallint,
	voucher_classification  smallint,
	voucher_comment         smallint,
	voucher_memo            smallint,
	voucher_num             varchar(16),
	amt_paid                float,      
	amt_disc_taken          float,      
	amt_net                 float,      
	invoice_num             varchar(16),
	invoice_date            int,     
	voucher_date_due        int,     
	description             varchar(60),
	voucher_classify        varchar(8) ,
	voucher_internal_memo   varchar(40),
	comment_line            varchar(40),
	posted_flag             smallint,       
	printed_flag            smallint,
	overflow_flag           smallint,
	nat_cur_code			varchar(8),
	lines					smallint,
	history_flag			smallint
)





IF (@@error != 0)
   RETURN -1







CREATE TABLE #apexpdst
(
	vendor_code		varchar(12),
	check_num		varchar(16),
	cash_acct_code		varchar(32),		
	print_batch_num		int,
	payment_num		varchar(16),
	payment_type		smallint, 
	voucher_num		varchar(16),
	sequence_id 		int,
	amt_dist		float,		
	gl_exp_acct		varchar(32),   	
	posted_flag		smallint,	
	printed_flag		smallint, 	
	overflow_flag		smallint)





IF (@@error != 0)
   RETURN -1






CREATE TABLE #apvohist
(
	trx_ctrl_num 		varchar(16),  
	invoice_num 		varchar(16),  
	invoice_date 		datetime NULL,  
	voucher_num 		varchar(16),  
	voucher_date_due 	datetime NULL,  
	amt_paid 		float,  
	amt_disc_taken 		float,  
	amt_net 		float,  
	doc_ctrl_num 		varchar(16),  
	description 		varchar(60),  
	payment_type 		smallint,  
	symbol 			varchar(8),  
	curr_precision 		smallint,  
	voucher_internal_memo 	varchar(40),  
	comment_line 		varchar(40),  
	voucher_classify 	varchar(8),  
	trx_link 		varchar(16) 
)





IF (@@error != 0)
   RETURN -1








CREATE TABLE #aptrx_work
		(
		trx_ctrl_num		varchar(16),
		doc_ctrl_num		varchar(16),
		batch_code			varchar(16),
		date_applied		int,
		date_doc			int,		
	    vendor_code			varchar(12),
	    pay_to_code			varchar(8),	
		cash_acct_code		varchar(32),
		payment_code		varchar(8),
   		void_flag 			smallint,
		user_id				smallint,
		doc_desc			varchar(40),  
		company_code		varchar(8),
		nat_cur_code		varchar(8)
		)



	
	IF (@@error != 0)
			   RETURN -1







BEGIN TRAN PRINTBATCHNUM
		
		UPDATE	apnumber 
		SET	next_print_batch_num = next_print_batch_num + 1

		IF (@@error != 0)
		    BEGIN
				ROLLBACK TRAN PRINTBATCHNUM
	   			RETURN -1
			END

		SELECT  @print_batch_num = (next_print_batch_num - 1)
		FROM    apnumber 

		IF (@@error != 0)
		    BEGIN
				ROLLBACK TRAN PRINTBATCHNUM
	   			RETURN -1
			END

COMMIT  TRAN PRINTBATCHNUM


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkprt.cpp" + ", line " + STR( 141, 5 ) + " -- MSG: " + "Print batch num is " + str(@print_batch_num)




EXEC @result = appdate_sp @sys_date OUTPUT

UPDATE #check_header
SET print_batch_num = @print_batch_num


EXEC @result = apchkstb_sp @print_batch_num, 
						   @print_acct_num,
						   @payment_memo,
						   @voucher_classification,
						   @voucher_comment,
						   @voucher_memo,
						   @history_flag,
						   @cash_acct_code,
						   @process_group_num,
						   @debug_level

IF (@result != 0)
   RETURN @result

	
 





IF (@expense_dist = 1)
   BEGIN
	   EXEC @result = apexpdst_sp @print_batch_num, @cash_acct_code, @debug_level
	   IF (@result != 0)
	      RETURN @result
   END







IF (@history_flag = 1)
   BEGIN
	   EXEC @result = apvohist_sp  @debug_level
	   IF (@result != 0)
	      RETURN @result
   END






SELECT  @check_num_mask = check_num_mask,
		@check_start_col = check_start_col, 
		@check_length = check_length
FROM    apcash
WHERE   cash_acct_code = @cash_acct_code


IF (@@error != 0)
   RETURN -1



IF (@@error != 0)
   RETURN -1

EXEC @result = apchklns_sp		@voucher_classification,
							  	@voucher_comment,
							  	@voucher_memo,
							  	@expense_dist,	 
								@history_flag,
								@debug_level
IF (@result != 0)
   return @result

SELECT @voids_exist = 0

EXEC @result = apchknmb_sp		@expense_dist,
								@cash_acct_code,
								@to_white_paper,
							  	@start_check,
								@last_check OUTPUT,
								@check_num_mask,
								@check_start_col, 
								@check_length,
								@voids_exist OUTPUT,
								@lines_per_check,
								@debug_level

IF (@result != 0)
   return @result








EXEC @result = apchkovf_sp 	@to_white_paper, 
							@lines_per_check,
							@debug_level

IF (@result != 0)
	    RETURN @result



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkprt.cpp" + ", line " + STR( 255, 5 ) + " -- MSG: " + "Update pay-to-code addresses"




UPDATE #check_header
SET #check_header.pay_to_name = apmaster.address_name,
	#check_header.addr1 = apmaster.addr1,
	#check_header.addr2 = apmaster.addr2,
	#check_header.addr3 = apmaster.addr3,
	#check_header.addr4 = apmaster.addr4,
	#check_header.addr5 = apmaster.addr5,
	#check_header.addr6 = apmaster.addr6,
	#check_header.addr_sort1 = apmaster.addr_sort1,
	#check_header.addr_sort2 = apmaster.addr_sort2,
	#check_header.addr_sort3 = apmaster.addr_sort3
FROM #check_header, apmaster
WHERE #check_header.vendor_code = apmaster.vendor_code
AND   #check_header.pay_to_code = apmaster.pay_to_code
AND   apmaster.address_type IN (1,2)

IF (@@error != 0)
	   RETURN -1





   SELECT  @start_check_masked = SUBSTRING(@check_num_mask, 1,
    		@check_start_col -1) + RIGHT("0000000000000000" +
			RTRIM(LTRIM(STR(@start_check, 16, 0))),
			@check_length)


   SELECT  @last_check_masked = SUBSTRING(@check_num_mask, 1,
    		@check_start_col -1) + RIGHT("0000000000000000" +
			RTRIM(LTRIM(STR(@last_check, 16, 0))),
			@check_length)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkprt.cpp" + ", line " + STR( 304, 5 ) + " -- MSG: " + "Begin transaction"
BEGIN TRAN UPDPERM






IF EXISTS(SELECT * FROM apchecks_vw
          WHERE cash_acct_code = @cash_acct_code
		  AND   doc_ctrl_num BETWEEN @start_check_masked AND @last_check_masked)
	BEGIN
	  ROLLBACK TRAN UPDPERM
	  DROP TABLE #apchkstb
      DROP TABLE #apexpdst
	  RETURN -5	   
	END

IF EXISTS(SELECT * FROM apinppyt
          WHERE trx_type IN (4111,4011)
          AND   cash_acct_code = @cash_acct_code
		  AND   doc_ctrl_num BETWEEN @start_check_masked AND @last_check_masked)
	BEGIN
	  ROLLBACK TRAN UPDPERM
	  DROP TABLE #apchkstb
      DROP TABLE #apexpdst
	  RETURN -6	   
	END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkprt.cpp" + ", line " + STR( 333, 5 ) + " -- MSG: " + "Update apcash"

	 UPDATE apcash
	 SET next_check_num = @last_check + 1 
	 WHERE cash_acct_code = @cash_acct_code
	 AND next_check_num BETWEEN @start_check AND @last_check

	IF (@@error != 0)
		BEGIN
			ROLLBACK TRAN UPDPERM
		    RETURN -1
		END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkprt.cpp" + ", line " + STR( 346, 5 ) + " -- MSG: " + "Update apinppyt"
	UPDATE apinppyt
	SET printed_flag = 1,
	    apinppyt.doc_ctrl_num = #check_header.doc_ctrl_num,
		apinppyt.date_doc = #check_header.date_doc,
		apinppyt.print_batch_num = @print_batch_num,
		apinppyt.payee_name = #check_header.addr1
	FROM apinppyt, #check_header
	WHERE apinppyt.trx_ctrl_num = #check_header.trx_ctrl_num
	AND apinppyt.posted_flag = -1
	AND apinppyt.process_group_num = @process_group_num

	IF (@@error != 0)
		BEGIN
			ROLLBACK TRAN UPDPERM
		    RETURN -1
		END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkprt.cpp" + ", line " + STR( 364, 5 ) + " -- MSG: " + "Insert apchkstb"
	INSERT apchkstb	 (
					vendor_code,
					check_num,
					cash_acct_code,
					print_batch_num,
					payment_num,
					payment_type,
					print_acct_num,
					payment_memo,
					voucher_classification,
					voucher_comment,
					voucher_memo,
					voucher_num,
					amt_paid,
					amt_disc_taken,
					amt_net,
					invoice_num,
					invoice_date,
					voucher_date_due,
					description,
					voucher_classify,
					voucher_internal_memo,
					comment_line,
					posted_flag,
					printed_flag,
					overflow_flag,
					nat_cur_code,
					history_flag
					)
	SELECT 
					vendor_code,
					check_num,
					cash_acct_code,
					print_batch_num,
					payment_num,
					payment_type,
					print_acct_num,
					payment_memo,
					voucher_classification,
					voucher_comment,
					voucher_memo,
					voucher_num,
					amt_paid,
					amt_disc_taken,
					amt_net,
					invoice_num,
					invoice_date,
					voucher_date_due,
					description,
					voucher_classify,
					voucher_internal_memo,
					comment_line,
					posted_flag,
					printed_flag,
					overflow_flag,
					nat_cur_code,
					history_flag
	FROM #apchkstb

	IF (@@error != 0)
		BEGIN
			ROLLBACK TRAN UPDPERM
		    RETURN -1
		END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkprt.cpp" + ", line " + STR( 431, 5 ) + " -- MSG: " + "Update apchkdsb"

	UPDATE apchkdsb
	SET apchkdsb.check_num = apchkstb.check_num,
	    apchkdsb.cash_acct_code = @cash_acct_code,
		apchkdsb.check_ctrl_num = apchkstb.payment_num
	FROM apchkdsb, #apchkstb apchkstb
	WHERE apchkdsb.apply_to_num = apchkstb.voucher_num
	AND apchkdsb.check_num = ""
	

	IF (@expense_dist = 1)
	   BEGIN
		   INSERT apexpdst (
				vendor_code,
				check_num,
				cash_acct_code,
				print_batch_num,
				payment_num,
				payment_type,
				voucher_num,
				sequence_id,
				amt_dist,
				gl_exp_acct,
				posted_flag,
				printed_flag,
				overflow_flag)
		   SELECT 
			   	vendor_code,
				check_num,
				cash_acct_code,
				print_batch_num,
				payment_num,
				payment_type,
				voucher_num,
				sequence_id,
				amt_dist,
				gl_exp_acct,
				posted_flag,
				printed_flag,
				overflow_flag
		   FROM #apexpdst

			IF (@@error != 0)
			BEGIN
				ROLLBACK TRAN UPDPERM
			    RETURN -1
			END
	   END

	IF (@voids_exist = 1)
	  BEGIN
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkprt.cpp" + ", line " + STR( 483, 5 ) + " -- MSG: " + "Insert void records"
		INSERT apvchdr  ( 
						trx_ctrl_num,
						doc_ctrl_num,
						batch_code,
						date_applied,
						date_doc,
						date_entered,
						vendor_code,
						pay_to_code,
						cash_acct_code,
						payment_code,
						state_flag,
						void_flag,
						amt_net,
						amt_discount,
						user_id,
						print_batch_num,
						process_ctrl_num,
						currency_code
						 ) 

		SELECT   
						 trx_ctrl_num,
						 doc_ctrl_num,
						 batch_code,
						 date_applied,
						 date_doc,
						 @sys_date,           
						 vendor_code,        
						 pay_to_code,        
						 cash_acct_code,     
						 payment_code,       
						 -1,        
						 void_flag,          
						 0.0,
						 0.0,
						 user_id,            
						 @print_batch_num,     
						 @process_group_num,
						 nat_cur_code
		FROM #aptrx_work
		
		IF (@@error != 0)
		BEGIN
			ROLLBACK TRAN UPDPERM
		    RETURN -1
		END

	 END
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkprt.cpp" + ", line " + STR( 533, 5 ) + " -- MSG: " + "Commit transaction"
COMMIT TRAN UPDPERM

DROP TABLE #apchkstb
DROP TABLE #apexpdst
DROP TABLE #aptrx_work

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apchkprt.cpp" + ", line " + STR( 540, 5 ) + " -- EXIT: "

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[apchkprt_sp] TO [public]
GO

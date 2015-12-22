SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                



























CREATE PROC [dbo].[eft_apge_sp]
    @cash_acct_code                 varchar(32),
	@payment_code                   varchar(8),
	@file_fmt_code					varchar(8)



AS DECLARE
@payment_memo			smallint,
@print_acct_num			smallint,
@voucher_classification smallint,
@voucher_comment	    smallint,
@voucher_memo			smallint,
@process_group_num		varchar(16),
@print_batch_num		int,
@debug_level			smallint,
@set_posted_flag        smallint  ,
@result					smallint ,
@count_row 				int	  ,
@payment_num			varchar(16),
@payment_num_last		varchar(16),
@sequence_id			smallint,
@date_process			int				
 


SELECT 

@print_acct_num	   		= 0	 ,	
@voucher_classification = 0	 ,
@voucher_comment	    = 0	 ,
@voucher_memo			= 0	 ,
@payment_memo			= 0,
@debug_level			= 0 ,
@set_posted_flag        = -1 ,
@count_row 				= 0,
@payment_num_last		= " ",
@payment_num			= " " ,
@sequence_id			= 0






		
UPDATE	apnumber 
SET		next_print_batch_num = next_print_batch_num + 1

SELECT 	@print_batch_num = (next_print_batch_num - 1)
FROM 	apnumber 



SELECT @process_group_num =  convert(varchar(16),@print_batch_num	)








UPDATE apinppyt
SET    posted_flag = @set_posted_flag,
       print_batch_num = @print_batch_num ,
	   process_group_num = @process_group_num
FROM   apinppyt a, eft_pymeth b
WHERE  a.payment_code = b.payment_code
AND    a.payment_type = 1
AND    b.file_fmt_code = @file_fmt_code
AND    a.trx_type = 4111
AND    a.print_batch_num = 0
AND    a.posted_flag = 0
AND    a.printed_flag = 4	
AND    a.hold_flag = 0
AND    a.approval_flag = 0
AND    a.cash_acct_code = @cash_acct_code
AND	   a.void_type = 0 


		IF ( @debug_level > 1 ) 
		BEGIN
		SELECT "Update apinpppyt"
		SELECT * FROM apinppyt
		END 








EXEC eft_provld_sp @set_posted_flag, @file_fmt_code


                            
CREATE TABLE #eft_aptr 
(	vendor_code 		varchar(12),
	pay_to_code 		varchar(8),  
 	doc_ctrl_num 		varchar(16),
 	cash_acct_code 		varchar(32),  
	print_batch_num 	int, 
 	payment_num 		varchar(16),  
	payment_type 		smallint,  
	print_acct_num 		smallint,  
	payment_memo 		smallint, 
 	voucher_classification 	smallint,  
	voucher_comment 	smallint,  
	voucher_memo 		smallint, 
 	voucher_num 		varchar(16),  
	amt_paid 		float,  
	amt_disc_taken 		float,  
	amt_net 		float, 
 	invoice_num 		varchar(16),  
	invoice_date 		int,  
	voucher_date_due 	int,  
	description 		varchar(60), 
 	voucher_classify 	varchar(8),  
	voucher_internal_memo 	varchar(40),  
	comment_line 		varchar(40), 
 	posted_flag 		smallint,  
	printed_flag 		smallint,  
	overflow_flag 		smallint,
	nat_cur_code		varchar(8)
)
 

EXEC @result = eft_aptrans_sp 	@print_batch_num, 
						   		@print_acct_num,
						   		@payment_memo,
						   		@voucher_classification,
						   		@voucher_comment,
						   		@voucher_memo,
						   		@cash_acct_code,
						   		@process_group_num,
						   		@debug_level


		IF ( @debug_level > 1 ) 
		BEGIN
		SELECT "Call apchkstb_sp "
		SELECT * FROM apchkstb
		SELECT @result
		END 



IF (@result != 0 )
   RETURN @result


select @date_process = convert(int, getdate() + 693595)				
 




INSERT  eft_aptr
(	payment_num		,		
	sequence_id     ,      
	doc_ctrl_num	,		
	vendor_code		,		
	pay_to_code		,		
	cash_acct_code	,		
	payment_code	,		
	payment_type	,		
	voucher_num		,		
	amt_paid		,		
	amt_disc_taken  ,      
	amt_net			,		
	invoice_num		,		
	invoice_date	 ,		
	voucher_date_due ,		
	description		 ,		
	voucher_classify ,		
	voucher_internal_memo,	
	comment_line		,	
	dest_account_num	,	
	dest_account_name	,	
	dest_aba_num		,	
	dest_account_type   ,  
	print_batch_num	   ,		
	eft_batch_num	   ,		
	process_flag	   ,		
	process_date	   ,
	nat_cur_code	)
	
 SELECT 		
	a.payment_num		,		
	0     ,      
	a.doc_ctrl_num	,		
	a.vendor_code		,		
	a.pay_to_code		,		
	a.cash_acct_code	,		
	b.payment_code	,		
	a.payment_type	,		
	a.voucher_num		,		
	a.amt_paid		,		
	a.amt_disc_taken  ,      
	a.amt_net			,		
	a.invoice_num		,		
	a.invoice_date	 ,		
	a.voucher_date_due ,		
	a.description		 ,		
	a.voucher_classify ,		
	a.voucher_internal_memo,
	a.comment_line		,	
	" "	,	
	" "	,	
	" "   , 
	0, 
	a.print_batch_num	   ,		
	0	   ,		
	0	   ,		
	@date_process		,				
	a.nat_cur_code

 FROM  #eft_aptr  a, apinppyt b
 WHERE payment_num = trx_ctrl_num






			WHILE 1=1 
			BEGIN
			SET ROWCOUNT 1

			SELECT @sequence_id = 0
			SELECT @count_row = 0

			SELECT 
       	   	@payment_num = payment_num 
       	   	FROM   eft_aptr
			WHERE payment_num > @payment_num_last 
			AND   print_batch_num = @print_batch_num
			ORDER BY cash_acct_code,payment_num
						

			IF @@rowcount = 0 
			BREAK 
			SET ROWCOUNT 0

		   	SELECT 
			@count_row   = count(payment_num)
       	   	FROM   eft_aptr
			WHERE payment_num = @payment_num 


   				WHILE @sequence_id < @count_row
    
    			BEGIN
    
    			SET ROWCOUNT 1   
                
					SELECT @sequence_id = @sequence_id + 1			

					UPDATE eft_aptr
					SET sequence_id = @sequence_id
					WHERE payment_num = @payment_num
					AND   print_batch_num = @print_batch_num
					AND   sequence_id = 0

					SELECT @payment_num_last = @payment_num

				END				


			END








SET ROWCOUNT 0


UPDATE eft_aptr
SET dest_account_num = bank_account_num  ,
    dest_account_name = bank_name,
	dest_aba_num = aba_number,       
	dest_account_type = account_type,
	bank_account_encrypted = b.bank_account_encrypted 
	FROM   eft_aptr a , eft_apms	b
	WHERE  a.vendor_code  = b.vendor_code
	AND    a.pay_to_code =  b.pay_to_code                       











		 	UPDATE 	apinppyt 
			SET 	posted_flag = -2, 
				process_group_num = " ",
				printed_flag = 3
			WHERE 	process_group_num = @process_group_num 
			AND 	posted_flag = -1 

DROP TABLE #eft_aptr

GO
GRANT EXECUTE ON  [dbo].[eft_apge_sp] TO [public]
GO

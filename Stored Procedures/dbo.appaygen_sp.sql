SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[appaygen_sp]	@pay_trx_ctrl_num	varchar(16),
				@trx_type		smallint,
				@doc_ctrl_num		varchar(16),
				@trx_desc		varchar(40),
				@batch_code		varchar(16),
				@cash_acct_code		varchar(32),
				@date_entered		int,
				@date_applied		int,
				@date_doc		int,
				@vendor_code		varchar(12),
				@payment_code		varchar(8),
				@amt_payment		float,
				@approval_flag		smallint,
				@user_id		smallint,
				@amt_disc_taken		float,
				@trx_ctrl_num		varchar(16),
				@payment_type		smallint

AS	DECLARE			@amt_on_acct		float,
					@batch_proc_flag 	smallint,
					@jul_date			int,
        			@jul_time			int,
					@company_code		varchar(12),
					@org_id			varchar(30),
					@str_msg_at		VARCHAR(255)



SELECT @amt_on_acct = ABS(@amt_payment - amt_net),
       @org_id = org_id  
FROM apvohdr
WHERE trx_ctrl_num = @trx_ctrl_num
AND   @amt_payment > amt_net

INSERT apinppyt (
timestamp,
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
payee_name,
settlement_ctrl_num,
org_id
)
SELECT 
NULL,
@pay_trx_ctrl_num,
@trx_type,
@doc_ctrl_num,
@trx_desc,
@batch_code,
@cash_acct_code,
@date_entered,
@date_applied,
@date_doc,
@vendor_code,
vo.pay_to_code,
vo.approval_code,
@payment_code,
@payment_type,
@amt_payment,
ISNULL(@amt_on_acct,0.0),
0,0,0,
@approval_flag,
0,
@user_id,
0,
@amt_disc_taken,
0,
p.company_code,
NULL,
vo.currency_code,
vo.rate_type_home,
vo.rate_type_oper,
vo.rate_home,
vo.rate_oper,
NULL,
NULL,
vo.org_id
FROM apvohdr vo, appymeth m, glco p
WHERE vo.trx_ctrl_num = @trx_ctrl_num
AND   m.payment_code = @payment_code




INSERT apinppdt (
timestamp,
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
org_id
)
SELECT 
NULL,
@pay_trx_ctrl_num,
@trx_type,
1,
trx_ctrl_num,
4091,
@amt_payment - ISNULL(@amt_on_acct,0.0),
@amt_disc_taken,
doc_desc,
0,
0,
vendor_code,
@amt_payment - ISNULL(@amt_on_acct,0.0),
@amt_disc_taken,
0.0,
0.0,
currency_code,
org_id
FROM apvohdr
WHERE trx_ctrl_num = @trx_ctrl_num






SELECT 	@batch_proc_flag = batch_proc_flag 
FROM	apco

IF @batch_proc_flag = 1
BEGIN
	


	EXEC appdate_sp @jul_date output
	EXEC apptime_sp @jul_time output 

	SELECT 	@company_code = company_code
	FROM	glco

	EXEC appgetstring_sp 'STR_STD_TRANS', @str_msg_at  OUT

	INSERT batchctl (	batch_ctrl_num, 		batch_description,				
			start_date,			start_time,				
			completed_date,			completed_time,				
			control_number,			control_total,				
			actual_number,			actual_total,
			batch_type,			document_name,
			hold_flag,			posted_flag,
			void_flag,			selected_flag,
			number_held,			date_applied,
			date_posted,			time_posted,
			start_user,			completed_user,
			posted_user,		  	company_code, 
			org_id )
	SELECT 			@batch_code, 			@str_msg_at,	
			@jul_date, 			@jul_time, 	
			0, 				0, 
			0, 				0.0, 
			0, 				0.0, 
			4040, 				@str_msg_at,
			0, 				0, 
			0, 				0, 
			0, 				@jul_date, 
			0, 				0, 
			'',				'', 
			" ", 				@company_code,
			@org_id   

END



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[appaygen_sp] TO [public]
GO

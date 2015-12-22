SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[arpycrh_sp]	@module_id		smallint,
					@val_mode		smallint,
					@trx_ctrl_num		varchar(16) OUTPUT,
					@doc_ctrl_num		varchar(16),
					@trx_desc		varchar(40),
					@batch_code		varchar(16),
					@trx_type		smallint,
					@non_ar_flag		smallint,
					@non_ar_doc_num	varchar(16),
					@gl_acct_code		varchar(32),
					@date_entered		int,
					@date_applied		int,
					@date_doc		int,
    					@customer_code	varchar(8),
					@payment_code		varchar(8),
					@payment_type		smallint,
					@amt_payment		float,
					@amt_on_acct		float,
					@prompt1_inp		varchar(30),
					@prompt2_inp		varchar(30),
					@prompt3_inp		varchar(30),
					@prompt4_inp		varchar(30),
					@deposit_num		varchar(16),
					@bal_fwd_flag		smallint,
					@printed_flag		smallint,
					@posted_flag		smallint,
					@hold_flag		smallint,
					@wr_off_flag		smallint,
					@on_acct_flag		smallint,
					@user_id		smallint,
					@max_wr_off		float, 
					@days_past_due	int,   
					@void_type		smallint,  
					@cash_acct_code	varchar(32),
				    	@origin_module_flag	smallint,
					@process_group_num	varchar(16),
					@source_trx_ctrl_num	varchar(16) = ' ',
					@source_trx_type	smallint = 0,
					@nat_cur_code		varchar(8),
					@rate_type_home	varchar(8),		
					@rate_type_oper	varchar(8),	
					@rate_home		float,
					@rate_oper		float,
					@reference_code	varchar(32) = NULL,
					@org_id		varchar(30)	= ''					
	
AS

BEGIN
	DECLARE 	@result	int
	
	


	IF @org_id = ''
	BEGIN
		SELECT 	@org_id  = organization_id
		FROM	Organization
		WHERE	outline_num = '1'	
	END


	IF ( @val_mode NOT IN ( 1, 2 ) )
		RETURN  32501

	



	IF  ( ( LTRIM(@trx_ctrl_num) IS NULL OR LTRIM(@trx_ctrl_num) = ' ' ) )
	BEGIN
		EXEC @result = arnewnum_sp	@trx_type, 
						@trx_ctrl_num  OUTPUT
		IF ( @result != 0 )
			RETURN @result
	END

	


	INSERT  #arinppyt
	(
		trx_ctrl_num,			doc_ctrl_num,		trx_desc,
		batch_code,    		trx_type,		non_ar_flag,
		non_ar_doc_num,		gl_acct_code,		date_entered,
		date_applied,			date_doc,    		customer_code,
		payment_code,			payment_type,		amt_payment,
		amt_on_acct,			prompt1_inp,		prompt2_inp,
		prompt3_inp,			prompt4_inp,		deposit_num,
		bal_fwd_flag,			printed_flag,		posted_flag,
		hold_flag,			wr_off_flag,		on_acct_flag,
		user_id,			max_wr_off, 		days_past_due,   
		void_type,  			cash_acct_code,    	origin_module_flag, 
	 	process_group_num,		trx_state,		mark_flag,
		source_trx_ctrl_num,		source_trx_type,	nat_cur_code,
		rate_type_home,		rate_type_oper,	rate_home,
		rate_oper,			reference_code,		org_id
	)       
	VALUES 
	(	
		@trx_ctrl_num,		@doc_ctrl_num,	@trx_desc,
		@batch_code,    		@trx_type,		@non_ar_flag,
		@non_ar_doc_num,		@gl_acct_code,	@date_entered,
		@date_applied,		@date_doc,    	@customer_code,
		@payment_code,		@payment_type,	@amt_payment,
		@amt_on_acct,			@prompt1_inp,		@prompt2_inp,
		@prompt3_inp,			@prompt4_inp,		@deposit_num,
		@bal_fwd_flag,		@printed_flag,	@posted_flag,
		@hold_flag,			@wr_off_flag,		@on_acct_flag,
		@user_id,			@max_wr_off, 		@days_past_due,   
		@void_type,  			@cash_acct_code,    	@origin_module_flag, 
	 	@process_group_num,		0,		0,
		@source_trx_ctrl_num,	@source_trx_type,	@nat_cur_code,
		@rate_type_home,		@rate_type_oper,	@rate_home,
		@rate_oper,			@reference_code,	@org_id
	)

	IF ( @@error != 0 )
		RETURN  32502
	
	RETURN  0
END
GO
GRANT EXECUTE ON  [dbo].[arpycrh_sp] TO [public]
GO

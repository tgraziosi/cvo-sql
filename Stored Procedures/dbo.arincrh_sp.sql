SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 




















































































































































































































































































































































































































































































































































































































































































CREATE  PROCEDURE [dbo].[arincrh_sp]	@module_id			smallint,
					@val_mode			smallint,
					@trx_ctrl_num			varchar(16) OUTPUT,
					@doc_ctrl_num			varchar(16),
					@doc_desc			varchar(40),
		    			@apply_to_num			varchar(16),
					@apply_trx_type		smallint,
					@order_ctrl_num		varchar(16),
					@batch_code			varchar(16),
    					@trx_type			smallint,
					@date_entered			int,
					@date_applied			int,
					@date_doc			int,
					@date_shipped			int,
					@date_required		int,
					@date_due			int,
					@date_aging			int,
    					@customer_code		varchar(8),
    					@ship_to_code			varchar(8),
    					@salesperson_code		varchar(8),
					@territory_code		varchar(8),
					@comment_code			varchar(8),
					@fob_code			varchar(8),
					@freight_code			varchar(8),
					@terms_code			varchar(8),
					@fin_chg_code			varchar(8),
					@price_code			varchar(8),
					@dest_zone_code		varchar(8),
					@posting_code			varchar(8),
					@recurring_flag		smallint,
					@recurring_code		varchar(8),
					@tax_code			varchar(8),
					@cust_po_num			varchar(20),
					@total_weight			float,
    					@amt_gross			float,
    					@amt_freight			float,
    					@amt_tax			float,
    					@amt_discount			float,
    					@amt_net			float,
					@amt_paid			float,
					@amt_due			float,
					@amt_cost			float,
					@amt_profit			float,
					@next_serial_id		smallint,
					@printed_flag			smallint,
					@posted_flag			smallint,
					@hold_flag			smallint,
					@hold_desc			varchar(40),
					@user_id			smallint,
					@customer_addr1		varchar(40),
					@customer_addr2		varchar(40),
					@customer_addr3		varchar(40),
					@customer_addr4		varchar(40),
					@customer_addr5		varchar(40),
					@customer_addr6		varchar(40),
					@ship_to_addr1		varchar(40),
					@ship_to_addr2		varchar(40),
					@ship_to_addr3		varchar(40),
					@ship_to_addr4		varchar(40),
					@ship_to_addr5		varchar(40),
					@ship_to_addr6		varchar(40),
					@attention_name		varchar(40),
					@attention_phone		varchar(30),
					@amt_rem_rev			float,
					@amt_rem_tax			float,
					@date_recurring		int,
					@location_code		varchar(8),
					@process_group_num 		varchar(16),
					@amt_discount_taken		float = 0.0,
					@amt_write_off_given		float = 0.0,
					@source_trx_ctrl_num		varchar(16) = ' ',
					@source_trx_type 		smallint = 0,
					@nat_cur_code			varchar(8),			
					@rate_type_home		varchar(8),		
					@rate_type_oper		varchar(8),
					@amt_tax_included		float,
					@org_id			varchar(30) = ''
AS
BEGIN
	DECLARE	@result		int,
			@rate_home		float,			
			@rate_oper		float,
			@divide_flag_h	smallint,
			@divide_flag_o	smallint,
			@home_currency	varchar(8),
			@oper_currency	varchar(8)			


	SELECT	@home_currency = home_currency,
		@oper_currency = oper_currency
	FROM	glco	


	EXEC @result = CVO_Control..mccurate_sp
				@date_applied,
				@nat_cur_code,	
				@home_currency,		
				@rate_type_home,	
				@rate_home		OUTPUT,
				0,
				@divide_flag_h	OUTPUT
	
	IF ( @result != 0 )
		SELECT @rate_home = 0

	EXEC @result = CVO_Control..mccurate_sp
				@date_applied,
				@nat_cur_code,	
				@oper_currency,		
				@rate_type_oper,	
				@rate_oper		OUTPUT,
				0,
				@divide_flag_o	OUTPUT
				
	IF ( @result != 0 )
		SELECT @rate_oper = 0
		
	IF ( @val_mode NOT IN ( 1, 2 ) )
		RETURN  32501

	



	IF  ( RTRIM( @trx_ctrl_num ) IS NULL )
	BEGIN
		EXEC @result = arnewnum_sp	@trx_type,  
						@trx_ctrl_num OUTPUT
		IF ( @result != 0 )
			RETURN @result
	END

	


	

	


	

	


	INSERT  #arinpchg
	(
		trx_ctrl_num,			doc_ctrl_num,			doc_desc,
    		apply_to_num,			apply_trx_type,		order_ctrl_num,
		batch_code,    		trx_type,			date_entered,
		date_applied,			date_doc,			date_shipped,
		date_required,		date_due,			date_aging,
    		customer_code,    		ship_to_code,    		salesperson_code,
		territory_code,		comment_code,			fob_code,
		freight_code,			terms_code,			fin_chg_code,
		price_code,			dest_zone_code,		posting_code,
    		recurring_flag,		recurring_code,		tax_code,
    		cust_po_num,			total_weight,    		amt_gross,
    		amt_freight,    		amt_tax,    			amt_discount,
    		amt_net,			amt_paid,			amt_due,				
		amt_cost,			amt_profit,			next_serial_id,
		printed_flag,			posted_flag,			hold_flag,
		hold_desc,			user_id,			customer_addr1,
		customer_addr2,		customer_addr3,		customer_addr4,
		customer_addr5,		customer_addr6,		ship_to_addr1,
		ship_to_addr2,		ship_to_addr3,		ship_to_addr4,
		ship_to_addr5,		ship_to_addr6,		attention_name,
		attention_phone,		amt_rem_rev,			amt_rem_tax,
		date_recurring,		location_code,		process_group_num,
		trx_state,			mark_flag,			amt_discount_taken,
		amt_write_off_given,		source_trx_ctrl_num,		source_trx_type,
		nat_cur_code,			rate_type_home,		rate_type_oper,
		rate_home,			rate_oper,			edit_list_flag,      
		amt_tax_included,		org_id
	)       
	VALUES 
	(
		@trx_ctrl_num,		@doc_ctrl_num,		@doc_desc,
    		@apply_to_num,		@apply_trx_type,		@order_ctrl_num,
		@batch_code,    		@trx_type,			@date_entered,
		@date_applied,		@date_doc,			@date_shipped,
		@date_required,		@date_due,			@date_aging,
    		@customer_code, 		@ship_to_code,    		@salesperson_code,
		@territory_code,		@comment_code,		@fob_code,
		@freight_code,		@terms_code,			@fin_chg_code,
		@price_code,			@dest_zone_code,		@posting_code,
    		@recurring_flag,		@recurring_code,		@tax_code,
    		@cust_po_num,			@total_weight,    		@amt_gross,
    		@amt_freight,    		@amt_tax,    			@amt_discount,
    		@amt_net,			@amt_paid,			@amt_due,
		@amt_cost,			@amt_profit,			@next_serial_id,
		@printed_flag,		@posted_flag,			@hold_flag,
		@hold_desc,			@user_id,			@customer_addr1,
		@customer_addr2,		@customer_addr3,		@customer_addr4,
		@customer_addr5,		@customer_addr6,		@ship_to_addr1,
		@ship_to_addr2,		@ship_to_addr3,		@ship_to_addr4,
		@ship_to_addr5,		@ship_to_addr6,		@attention_name,
		@attention_phone,		@amt_rem_rev,			@amt_rem_tax,
		@date_recurring,		@location_code,		@process_group_num,
		0,			0,				@amt_discount_taken,
		@amt_write_off_given,	@source_trx_ctrl_num,	@source_trx_type,
		@nat_cur_code,		@rate_type_home,		@rate_type_oper,
		@rate_home,			@rate_oper,			0,
		@amt_tax_included,		@org_id
	)
	IF ( @@error != 0 )
		RETURN  32502
	
	RETURN  0
END
GO
GRANT EXECUTE ON  [dbo].[arincrh_sp] TO [public]
GO

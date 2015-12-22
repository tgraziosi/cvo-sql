SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[arincrd_sp] 
	@module_id		int,
	@interface_mode	smallint,
	@trx_ctrl_num		varchar(16),
	@doc_ctrl_num		varchar(16),
	@sequence_id		int,
	@trx_type		smallint,
	@location_code	varchar(8),
	@item_code		varchar(30),
	@bulk_flag		smallint,
	@date_entered		int,
	@line_desc		varchar(60), 
	@qty_ordered		float,
	@qty_shipped		float,
	@unit_code		varchar(8),
	@unit_price		float,
	@unit_cost		float,
	@weight		float,
	@serial_id		int,
	@tax_code		varchar(8),
	@gl_rev_acct		varchar(32),
	@disc_prc_flag	smallint,
	@discount_amt		float,
	@commission_flag	smallint,
	@rma_num		varchar(16),
	@return_code		varchar(8),
	@qty_returned		float,
	@qty_prev_returned	float,
	@new_gl_rev_acct	varchar(32),
	@iv_post_flag		smallint,
	@oe_orig_flag		smallint,
	@discount_prc		float,
	@extended_price	float,
	@calc_tax		float,
	@reference_code  	varchar(32),
	@cust_po		  	varchar(20) = '',			
	@org_id 			varchar(30)	= ''			



AS

DECLARE @result                 int



IF ( @interface_mode NOT IN ( 1, 2 ) )
BEGIN   
	RETURN 32501
END







SELECT  @sequence_id = ISNULL(MAX( sequence_id ),0) + 1
FROM    #arinpcdt        
WHERE   trx_ctrl_num = @trx_ctrl_num
AND     trx_type     = @trx_type




INSERT  #arinpcdt (
	trx_ctrl_num,
	doc_ctrl_num,
	sequence_id,
	trx_type,
	location_code,
	item_code,
	bulk_flag,
	date_entered,
	line_desc, 
	qty_ordered,
	qty_shipped,
	unit_code,
	unit_price,
	unit_cost,
	weight,
	serial_id,
	tax_code,
	gl_rev_acct,
	disc_prc_flag,
	discount_amt,
	commission_flag,
	rma_num,
	return_code,
	qty_returned,
	qty_prev_returned,
	new_gl_rev_acct,
	iv_post_flag,
	oe_orig_flag,
	trx_state,
	mark_flag,
	discount_prc,
	extended_price,
	calc_tax,
	reference_code,
	cust_po,					
	org_id)						

VALUES (
	@trx_ctrl_num,
	@doc_ctrl_num,
	@sequence_id,
	@trx_type,
	@location_code,
	@item_code,
	@bulk_flag,
	@date_entered,
	@line_desc, 
	@qty_ordered,
	@qty_shipped,
	@unit_code,
	@unit_price,
	@unit_cost,
			@weight,
	@serial_id,
	@tax_code,
	@gl_rev_acct,
	@disc_prc_flag,
	@discount_amt,
	@commission_flag,
	@rma_num,
	@return_code,
	@qty_returned,
	@qty_prev_returned,
	@new_gl_rev_acct,
	@iv_post_flag,
	@oe_orig_flag,
	0,
	0,
	@discount_prc,
	@extended_price,
	@calc_tax,
	@reference_code,
	@cust_po,					
	@org_id						
	)

IF ( @@error != 0 )
	RETURN  32502
	
RETURN  0

GO
GRANT EXECUTE ON  [dbo].[arincrd_sp] TO [public]
GO

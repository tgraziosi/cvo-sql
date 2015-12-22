SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[appycrd_sp] 
	@module_id		int,
	@interface_mode	smallint,
	@trx_ctrl_num		varchar(16),
	@trx_type		smallint,
	@sequence_id		int OUTPUT,	
	@apply_to_num		varchar(16),
	@apply_trx_type		smallint,	
	@amt_applied		float,		
	@amt_disc_taken		float,	
	@line_desc		varchar(40),
	@void_flag		smallint,
	@payment_hold_flag	smallint,
	@vendor_code		varchar(12),
	@vo_amt_applied		float,
	@vo_amt_disc_taken	float,
	@gain_home			float,
	@gain_oper			float,
	@nat_cur_code		varchar(8),
	@org_id			varchar(30) = ''		   


AS

DECLARE @result                 int



IF @org_id = ''
BEGIN
	SELECT 	@org_id  = organization_id
	FROM	Organization
	WHERE	outline_num = '1'
END







SELECT  @sequence_id = ISNULL(MAX( sequence_id ),0) + 1
FROM    #apinppdt        
WHERE   trx_ctrl_num = @trx_ctrl_num




INSERT  #apinppdt (
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
		mark_flag	
		)

VALUES (
		@trx_ctrl_num,
		@trx_type,
		@sequence_id,
		@apply_to_num,
		@apply_trx_type,	
		@amt_applied,
		@amt_disc_taken,
		@line_desc,
		@void_flag,
		@payment_hold_flag,
		@vendor_code,
		@vo_amt_applied,
		@vo_amt_disc_taken,
		@gain_home,
		@gain_oper,
		@nat_cur_code,
		0,
		@org_id,
		0	
		)
		
		
		IF ( @@error != 0 )
	RETURN  -1
	

RETURN  0

GO
GRANT EXECUTE ON  [dbo].[appycrd_sp] TO [public]
GO

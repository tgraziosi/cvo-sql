SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[arpycrd_sp] 
	@module_id		int,
	@interface_mode	smallint,
	@trx_ctrl_num		varchar(16),
	@doc_ctrl_num		varchar(16),
	@sequence_id		int,
	@trx_type		smallint,
	@apply_to_num		varchar(16),
	@apply_trx_type	smallint,
	@customer_code	varchar(8),
	@date_aging		int,
	@amt_applied		float,
	@amt_disc_taken	float,
	@wr_off_flag		smallint,
	@amt_max_wr_off	float,
	@void_flag		smallint,
	@line_desc		varchar(40),
	@sub_apply_num	varchar(16),
	@sub_apply_type	smallint,
	@amt_tot_chg		float,
	@amt_paid_to_date	float,
	@terms_code		varchar(8),
	@posting_code		varchar(8),
	@date_doc		int, 
	@amt_inv		float,
	@gain_home 		float,		
	@gain_oper 		float,
	@inv_amt_applied	float,
	@inv_amt_disc_taken	float,
	@inv_amt_max_wr_off	float,		
	@inv_cur_code	varchar(8),
	@org_id		varchar(30)	= ''						


AS

DECLARE @result		int




IF @org_id = ''
BEGIN
	SELECT 	@org_id  = organization_id
	FROM	Organization
	WHERE	outline_num = '1'	
END





IF ( @interface_mode NOT IN ( 1, 2 ) )
BEGIN   
	RETURN 32501
END







SELECT  @sequence_id = ISNULL(MAX( sequence_id ),0) + 1
FROM    #arinppdt        
WHERE   trx_ctrl_num = @trx_ctrl_num




INSERT  #arinppdt	(
			trx_ctrl_num,
			doc_ctrl_num,
			sequence_id,
			trx_type,
			apply_to_num,
			apply_trx_type,
			customer_code,
			date_aging,
			amt_applied,
			amt_disc_taken,
			wr_off_flag,
			amt_max_wr_off,
			void_flag,
			line_desc,
			sub_apply_num,
			sub_apply_type,
			amt_tot_chg,
			amt_paid_to_date,
			terms_code,
			posting_code,
			date_doc, 
			amt_inv,
			gain_home,		
			gain_oper,
			inv_amt_applied,
			inv_amt_disc_taken,
			inv_amt_max_wr_off,		
			inv_cur_code,
	   		trx_state,
			mark_flag,
			org_id	
			)

VALUES 
			(
	  		@trx_ctrl_num,
			@doc_ctrl_num,
			@sequence_id,
			@trx_type,
			@apply_to_num,
			@apply_trx_type,
			@customer_code,
			@date_aging,
			@amt_applied,
			@amt_disc_taken,
			@wr_off_flag,
			@amt_max_wr_off,
			@void_flag,
			@line_desc,
			@sub_apply_num,
			@sub_apply_type,
			@amt_tot_chg,
			@amt_paid_to_date,
			@terms_code,
			@posting_code,
			@date_doc, 
			@amt_inv,
			@gain_home,
			@gain_oper,
			@inv_amt_applied,
			@inv_amt_disc_taken,
			@inv_amt_max_wr_off,	
			@inv_cur_code,	
			0,
			0,
			@org_id
			)
		
		
		IF ( @@error != 0 )
	RETURN  32502
	
RETURN  0

GO
GRANT EXECUTE ON  [dbo].[arpycrd_sp] TO [public]
GO

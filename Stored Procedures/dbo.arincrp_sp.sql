SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[arincrp_sp] 
	@trx_ctrl_num		varchar(16),	
	@doc_ctrl_num		varchar(16),	
	@trx_desc		varchar(40),
	@date_doc		int,
	@customer_code	varchar(8),
	@payment_code		varchar(8),
	@amt_payment		float,
	@prompt1_inp		varchar(30),
	@prompt2_inp		varchar(30),
	@prompt3_inp		varchar(30),
	@prompt4_inp		varchar(30),
	@amt_disc_taken	float,
	@cash_acct_code	varchar(32)


AS

DECLARE @result int


INSERT #arinptmp (
	trx_ctrl_num,
	doc_ctrl_num,
	trx_desc,
	date_doc,
	customer_code,
	payment_code,
	amt_payment,
	prompt1_inp,
	prompt2_inp,
	prompt3_inp,
	prompt4_inp,
	amt_disc_taken,
	cash_acct_code
	)
VALUES
	(
	@trx_ctrl_num,
	@doc_ctrl_num,
	@trx_desc,
	@date_doc,
	@customer_code,
	@payment_code,
	@amt_payment,
	@prompt1_inp,
	@prompt2_inp,
	@prompt3_inp,
	@prompt4_inp,
	@amt_disc_taken,
	@cash_acct_code
	)

IF ( @@error != 0 )
	RETURN 32502
	

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[arincrp_sp] TO [public]
GO

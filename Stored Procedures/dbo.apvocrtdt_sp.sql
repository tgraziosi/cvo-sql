SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvocrtdt_sp] 
	@trx_ctrl_num           varchar(16),
	@trx_type               smallint,
	@sequence_id		integer,
	@tax_sequence_id	integer,
	@detail_sequence_id	integer,
	@tax_type_code		varchar(8),
	@amt_taxable		float,
	@amt_gross		float,
	@amt_tax		float,
	@amt_final_tax		float,
	@recoverable_flag	integer,
	@account_code		varchar(32)
AS

DECLARE @result                 int





SELECT  @sequence_id = ISNULL(MAX( sequence_id ),0) + 1
FROM    #apinptaxdtl        
WHERE   trx_ctrl_num = @trx_ctrl_num
AND     trx_type     = @trx_type




INSERT  #apinptaxdtl (
	trx_ctrl_num,
	sequence_id,
	trx_type,
	tax_sequence_id,
	detail_sequence_id,
	tax_type_code,
	amt_taxable,
	amt_gross,
	amt_tax,
	amt_final_tax,
	recoverable_flag,
	account_code,
	mark_flag)

VALUES (
	@trx_ctrl_num,
	@sequence_id,
	@trx_type,
	@tax_sequence_id,
	@detail_sequence_id,
	@tax_type_code,
	@amt_taxable,
	@amt_gross,
	@amt_tax,
	@amt_final_tax,
	@recoverable_flag,
	@account_code,
	0)

IF ( @@error != 0 )
	RETURN  -1
	
RETURN  0

GO
GRANT EXECUTE ON  [dbo].[apvocrtdt_sp] TO [public]
GO

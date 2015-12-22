SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apvocrt_sp] 
	@module_id              int,
	@interface_mode smallint,
	@trx_ctrl_num			varchar(16),
	@trx_type			smallint,
	@sequence_id			int,
	@tax_type_code			varchar(8),
	@amt_taxable			float,
	@amt_gross			float,
	@amt_tax				float,
	@amt_final_tax			float

AS

DECLARE @result                 int







SELECT  @sequence_id = ISNULL(MAX( sequence_id ),0) + 1
FROM    #apinptax        
WHERE   trx_ctrl_num = @trx_ctrl_num
AND     trx_type     = @trx_type




INSERT  #apinptax (
	trx_ctrl_num,
	trx_type,
	sequence_id,
	tax_type_code,
	amt_taxable,
	amt_gross,
	amt_tax,
	amt_final_tax,
	trx_state,
	mark_flag
	)

VALUES (
	@trx_ctrl_num,
	@trx_type,
	@sequence_id,
	@tax_type_code,
	@amt_taxable,
	@amt_gross,
	@amt_tax,
	@amt_final_tax,
	2,		   
	0
	       )

IF ( @@error != 0 )
	RETURN  -1
	

RETURN  0

GO
GRANT EXECUTE ON  [dbo].[apvocrt_sp] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[artxdist_sp]	@TaxCode char(8), @GrossAmt float, @TrxType smallint,
	@TrxCtrlNum char(16)
AS

DECLARE	@seq_id smallint


INSERT	#arinptax(
	trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,
	amt_taxable,	amt_gross,	amt_tax,	amt_final_tax
	)
SELECT @TrxCtrlNum, @TrxType, 0, tax_type_code, @GrossAmt, @GrossAmt, 0, 0
FROM	artaxdet
WHERE	tax_code = @TaxCode

SELECT	@seq_id = 1
SET	ROWCOUNT 1

WHILE	( 1 = 1 )
BEGIN
	UPDATE	#arinptax
	SET	sequence_id = @seq_id
	WHERE	sequence_id = 0

	IF ( @@ROWCOUNT = 0 )
		BREAK

	SELECT	@seq_id = @seq_id + 1
END

SET	ROWCOUNT 0

GO
GRANT EXECUTE ON  [dbo].[artxdist_sp] TO [public]
GO

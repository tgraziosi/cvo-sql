SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




































































































































































  



					  

























































 




























































































































































































































































































CREATE PROC [dbo].[arnaradj_sp]
        @trx_ctrl_num varchar(16),
        @doc_ctrl_num varchar(16),
        @cust_code  varchar(8),
        @trx_type  smallint
AS
DECLARE         @void_flag  smallint, 
		@non_ar_flag smallint, 
		@old_trx varchar(16),
		@tax_type_code varchar(8), 
		@amt_taxable float, 
		@amt_gross float, 
		@amt_tax float,
		@sequence smallint

	SELECT @old_trx = trx_ctrl_num
	FROM artrx
	WHERE doc_ctrl_num = @doc_ctrl_num
	AND customer_code = @cust_code

	SELECT @sequence = 0

	DELETE arnonardet WHERE trx_ctrl_num = @trx_ctrl_num

	INSERT arnonardet ( 
		trx_ctrl_num,
		trx_type,
		sequence_id,
		line_desc,
		tax_code,
		gl_acct_code,
		unit_price,
		extended_price,
		reference_code,
		amt_tax,
		qty_shipped,
		org_id )
	SELECT trx_ctrl_num,
		@trx_type,
		sequence_id,
		line_desc,
		tax_code,
		gl_acct_code,
		unit_price,
		extended_price,
		reference_code,
		amt_tax,
		qty_shipped,
		org_id
	FROM #arnonardet

	DELETE arinptax WHERE trx_ctrl_num = @trx_ctrl_num

	DECLARE tax_records CURSOR FOR
		SELECT tax_type_code, amt_taxable, amt_gross, amt_tax
		FROM artrxtax
		WHERE doc_ctrl_num = @old_trx
		AND trx_type = 2111

	OPEN tax_records

	FETCH NEXT FROM tax_records into @tax_type_code, @amt_taxable, @amt_gross, @amt_tax

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @sequence = @sequence + 1

		INSERT arinptax (
			trx_ctrl_num,	trx_type,	sequence_id,
			tax_type_code,	amt_taxable,	amt_gross,
			amt_tax,	amt_final_tax )
		VALUES (
			@trx_ctrl_num,	@trx_type,	@sequence,
			@tax_type_code,	@amt_taxable,	@amt_gross,
			@amt_tax,	@amt_tax
			)
		
		FETCH NEXT FROM tax_records into @tax_type_code, @amt_taxable, @amt_gross, @amt_tax
	END
  
	CLOSE tax_records
	DEALLOCATE tax_records

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[arnaradj_sp] TO [public]
GO

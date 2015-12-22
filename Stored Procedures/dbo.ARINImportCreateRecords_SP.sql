SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[ARINImportCreateRecords_SP]	@process_ctrl_num	varchar(16),
							@user_id		smallint,
							@debug_level		smallint = 0

AS
	DECLARE
		@date_entered int
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinicr.sp" + ", line " + STR( 25, 5 ) + " -- ENTRY: "
	
	SELECT	@date_entered = datediff(dd,"1/1/80",getdate())+722815
	


	DECLARE @trx_type  int	
	
CREATE TABLE #TxLineInput
(
	control_number		varchar(16),
	reference_number	int,
	tax_code			varchar(8),
	quantity			float,
	extended_price		float,
	discount_amount		float,
	tax_type			smallint,
	currency_code		varchar(8)
)


	IF ( @@error != 0 )
	BEGIN
		RETURN 34563
	END

	INSERT INTO #TxLineInput
	(
		control_number,	reference_number,			tax_code,
		quantity,		extended_price,			discount_amount,
		tax_type,		currency_code
	)
	SELECT	hdr.trx_ctrl_num,	cdt.sequence_id,			cdt.tax_code,
		cdt.qty_shipped,	cdt.extended_price + cdt.discount_amt,	cdt.discount_amt,
		0,			hdr.nat_cur_code
	FROM	#arinpcdt cdt, #arinpchg hdr
	WHERE	cdt.trx_ctrl_num = hdr.trx_ctrl_num

	IF ( @@error != 0 )
	BEGIN
		RETURN 34563
	END

	INSERT INTO #TxLineInput
	(
		control_number,		reference_number,	tax_code,
		quantity,			extended_price,	discount_amount,
		tax_type,			currency_code
	)
	SELECT	trx_ctrl_num,		0,			tax_code,
		1,				amt_freight,		0,
		1,				nat_cur_code
	FROM	#arinpchg hdr
	WHERE	((amt_freight) > (0.0) + 0.0000001)

	IF ( @@error != 0 )
	BEGIN
		RETURN 34563
	END

	
	
CREATE TABLE #TxInfo
(
	control_number		varchar(16),
	sequence_id		int,
	tax_type_code		varchar(8),
	amt_taxable			float,
	amt_gross			float,
	amt_tax				float,
	amt_final_tax		float,
	currency_code		varchar(8),
	tax_included_flag	smallint

)


	IF ( @@error != 0 )
	BEGIN
		RETURN 34563
	END

	
	
CREATE TABLE #TxLineTax
(
	control_number		varchar(16),
	reference_number	int,
	tax_amount			float,
	tax_included_flag	smallint
)



	IF ( @@error != 0 )
	BEGIN
		RETURN 34563
	END

	
	CREATE TABLE #txdetail
	(
		control_number	varchar(16),
		reference_number	int,
		tax_type_code		varchar(8),
		amt_taxable		float
	)


	CREATE TABLE #txinfo_id
	(
		id_col			numeric identity,
		control_number	varchar(16),
		sequence_id		int,
		tax_type_code		varchar(8),
		currency_code		varchar(8)
	)


	CREATE TABLE #TXInfo_min_id (control_number varchar(16),min_id_col numeric)


	CREATE TABLE	#TxTLD
	(
		control_number	varchar(16),
		tax_type_code		varchar(8),
		tax_code		varchar(8),
		currency_code		varchar(8),
		tax_included_flag	smallint,
		base_id		int,
		amt_taxable		float,		
		amt_gross		float		
	)


	EXEC	TXCalculateTax_SP

	DROP TABLE #txdetail
	DROP TABLE #txinfo_id
	DROP TABLE #TXInfo_min_id 
	DROP TABLE #TxTLD

	UPDATE	#arinpcdt
	SET	calc_tax = #TxLineTax.tax_amount
	FROM	#TxLineTax
	WHERE	#arinpcdt.trx_ctrl_num = #TxLineTax.control_number
	AND	#arinpcdt.sequence_id = #TxLineTax.reference_number

	IF ( @@error != 0 )
	BEGIN
		RETURN 34563
	END



	SELECT @trx_type = MAX(trx_type) FROM #arinpchg



	INSERT #arinptax
	(
		trx_ctrl_num,		trx_type,	tax_type_code,
		amt_taxable,		amt_gross,	amt_tax,
		amt_final_tax,	sequence_id
	)
	SELECT	control_number,	@trx_type,	tax_type_code,
		amt_taxable,		amt_gross,	amt_tax,
		amt_final_tax,	sequence_id
	FROM	#TxInfo

	IF ( @@error != 0 )
	BEGIN
		RETURN 34563
	END

	SELECT control_number, SUM(amt_final_tax) amt_tax, SUM(tax_included_flag * amt_final_tax ) amt_tax_included
	INTO	#inptax
	FROM	#TxInfo
	GROUP BY control_number

	IF ( @@error != 0 )
	BEGIN
		RETURN 34563
	END

	DROP TABLE #TxLineInput
	DROP TABLE #TxInfo
	DROP TABLE #TxLineTax

	CREATE TABLE #cdt
	(
		trx_ctrl_num	varchar(16),		
		sequence_id	int,
		price		float,
		discount	float,
		cost		float,
		weight		float
	)

	INSERT	#cdt
	SELECT	trx_ctrl_num, 
		MAX(sequence_id),
		SUM(extended_price),		
		SUM(discount_amt),
		SUM(unit_cost),	
		SUM(weight)
	FROM	#arinpcdt
	GROUP BY trx_ctrl_num

	IF ( @@error != 0 )
	BEGIN
		RETURN 34563
	END

	UPDATE	#arinpchg
	SET	next_serial_id = cdt.sequence_id,
		amt_discount = cdt.discount,
		amt_gross = cdt.price - tax.amt_tax_included + cdt.discount,
		amt_net = cdt.price - tax.amt_tax_included + tax.amt_tax,
		amt_tax_included = tax.amt_tax_included,
		amt_due = cdt.price - tax.amt_tax_included + tax.amt_tax,
		amt_cost = cdt.cost,
		amt_profit = cdt.price - cdt.cost,
		amt_tax = tax.amt_tax,
		total_weight = cdt.weight
	FROM	#cdt cdt, #inptax tax
	WHERE	#arinpchg.trx_ctrl_num = cdt.trx_ctrl_num
	AND	#arinpchg.trx_ctrl_num = tax.control_number

	IF ( @@error != 0 )
	BEGIN
		RETURN 34563
	END
	
	
	UPDATE	#arinpchg
	SET	amt_net = amt_net + amt_freight,
		amt_due = amt_due + amt_freight

	IF ( @@error != 0 )
	BEGIN
		RETURN 34563
	END
	
	DROP TABLE #cdt
	DROP TABLE #inptax

	IF NOT EXISTS (SELECT trx_ctrl_num FROM #arinpage )
	BEGIN
		INSERT #arinpage
		(
			trx_ctrl_num,			sequence_id,			doc_ctrl_num,
			apply_to_num,			apply_trx_type,		trx_type,
			date_applied,			date_due,			date_aging,
			customer_code,		salesperson_code,		territory_code,
			price_code,			amt_due
		)
		SELECT	hdr.trx_ctrl_num,		1,				hdr.doc_ctrl_num,
			hdr.apply_to_num,		hdr.apply_trx_type,		hdr.trx_type,
			hdr.date_applied,		hdr.date_due,			hdr.date_aging,
			hdr.customer_code,		hdr.salesperson_code,	hdr.territory_code,
			hdr.price_code,		hdr.amt_net
		FROM	#arinpchg hdr
		
		IF ( @@error != 0 )
		BEGIN
			RETURN 34563
		END
 END
 	
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "Dumping #arinpchg..."
		SELECT "trx_ctrl_num = " + trx_ctrl_num +
			"doc_ctrl_num = " + doc_ctrl_num +
			"amt_gross = " + STR(amt_gross, 10, 2) +
			"amt_net = " + STR(amt_net, 10, 2 ) +
			"amt_tax = " + STR(amt_tax, 10, 2 ) +
			"amt_discount = " + STR(amt_discount, 10, 2 ) +
			"amt_cost = " + STR(amt_cost, 10, 2 ) +
			"amt_profit = " + STR(amt_profit, 10, 2 )	+
			"amt_freight = " + STR(amt_freight, 10, 2)
		FROM	#arinpchg
		SELECT "Dumping #arinpcdt..."
		SELECT	"trx_ctrl_num = " + trx_ctrl_num +
			"sequence_id = " + STR(sequence_id, 5) +
			"extended_price = " + STR(extended_price, 10, 2) +
			"discount_amt = " + STR(discount_amt, 10, 2 )
		FROM	#arinpcdt
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinicr.sp" + ", line " + STR( 252, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINImportCreateRecords_SP] TO [public]
GO

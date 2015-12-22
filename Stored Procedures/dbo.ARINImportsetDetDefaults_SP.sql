SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[ARINImportsetDetDefaults_SP] 	@debug_level	smallint = 0,
						@mode		smallint = 0 



								
AS
BEGIN
	DECLARE
		@result		int

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinidd.sp' + ', line ' + STR( 20, 5 ) + ' -- ENTRY: '



	DECLARE @trx_type int

	


	UPDATE	#arinpcdt
	SET	iv_post_flag = 0,
		location_code = ISNULL(#arinpcdt.location_code,' '),
		item_code = ISNULL(#arinpcdt.item_code,' '),
		line_desc = ISNULL(#arinpcdt.line_desc,' '),
		qty_shipped = ISNULL(#arinpcdt.qty_shipped,1),
		qty_ordered = ISNULL(#arinpcdt.qty_ordered,ISNULL(#arinpcdt.qty_shipped,1)),
		unit_code = ISNULL(#arinpcdt.unit_code,' '),
		unit_cost = ISNULL(#arinpcdt.unit_cost,0.0),
		weight = ISNULL(#arinpcdt.weight,0.0),
		serial_id = ISNULL(#arinpcdt.serial_id,1),
		disc_prc_flag = ISNULL(disc_prc_flag,0),
		discount_amt = ISNULL(discount_amt,0.0),
		discount_prc = ISNULL(discount_prc, 0.0),
		oe_orig_flag = ISNULL(oe_orig_flag,0)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinidd.sp' + ', line ' + STR( 42, 5 ) + ' -- EXIT: '
	      	RETURN 34563
	END
	
	


	UPDATE	#arinpcdt
	SET	extended_price = unit_price * qty_shipped - discount_amt
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinidd.sp' + ', line ' + STR( 53, 5 ) + ' -- EXIT: '
	 	RETURN 34563

	END



	SELECT @trx_type = MAX(trx_type) FROM #arinpcdt
	


	IF (@mode = 1) AND (@trx_type = 2032)
	BEGIN
		UPDATE	#arinpcdt
		SET	extended_price = unit_price * qty_returned - discount_amt
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinidd.sp' + ', line ' + STR( 53, 5 ) + ' -- EXIT: '
	 		RETURN 34563
		END
	END
	
	

			
	UPDATE	#arinpcdt
	SET	tax_code = #arinpchg.tax_code
	FROM	#arinpchg
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinidd.sp' + ', line ' + STR( 65, 5 ) + ' -- EXIT: '
	 	RETURN 34563
	END
		

	


    
    IF @mode<>1 BEGIN	
	UPDATE	#arinpcdt				  
	SET	gl_rev_acct = araccts.rev_acct_code
	FROM	araccts, #arinpchg
	WHERE	#arinpchg.posting_code = araccts.posting_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinidd.sp' + ', line ' + STR( 78, 5 ) + ' -- EXIT: '
	 	RETURN 34563
	END
    END	
	
	


	UPDATE	#arinpcom
	SET	exclusive_flag = ISNULL(#arinpcom.exclusive_flag, 0),
		split_flag = ISNULL(#arinpcom.split_flag, 0),
		percent_flag = ISNULL(#arinpcom.percent_flag, 0)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinidd.sp' + ', line ' + STR( 91, 5 ) + ' -- EXIT: '
	 	RETURN 34563
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinidd.sp' + ', line ' + STR( 95, 5 ) + ' -- EXIT: '
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINImportsetDetDefaults_SP] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                









































  



					  

























































 

































































































































































































































































































CREATE PROCEDURE [dbo].[apsavetaxdetails_sp]  		@control_number		varchar(16),
						@trx_type		smallint,
						@currency_code		varchar(8)
						   
AS
	DECLARE @detail_sequence_id INTEGER
	DECLARE	@sequence_id	INTEGER
		
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

	CREATE TABLE #TxLineTax
	(
		control_number		varchar(16),
		reference_number	int,
		tax_amount			float,
		tax_included_flag	smallint
	)

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

	CREATE TABLE	#TxPrevCalculated
	(
		control_number	varchar(16),
		trx_type	smallint,
		sequence_id	int
	)



	CREATE TABLE #txconnhdrinput 
	(
		doccode	varchar(16),
		doctype	smallint,
		trx_type smallint,
		companycode 	varchar(25),
		docdate 	datetime,
		exemptionno 	varchar(20),
		salespersoncode varchar(20),
		discount 	float,		
		purchaseorderno varchar(20),
		customercode 	varchar(20),
		customerusagetype varchar(20) ,
		detaillevel 	varchar(20) ,
		referencecode 	varchar(20) ,
		oriaddressline1	varchar(40),
		oriaddressline2	varchar(40),
		oriaddressline3	varchar(40),
		oricity	varchar(40),
		oriregion	varchar(40),
		oripostalcode	varchar(40),
		oricountry	varchar(40),
		destaddressline1 varchar(40),
		destaddressline2 varchar(40),
		destaddressline3 varchar(40),
		destcity	varchar(40),
		destregion	varchar(40),
		destpostalcode	varchar(40),
		destcountry	varchar(40),
		currCode varchar(8),
		currRate decimal(20,8),
		currRateDate datetime null,
		locCode varchar(20) null,
		paymentDt datetime null,
		taxOverrideReason varchar(100) null,
		taxOverrideAmt decimal(20,8) null,
		taxOverrideDate datetime null,
		taxOverrideType int null,
		commitInd int null		
	)

	CREATE INDEX TCHI_1 on #txconnhdrinput( doctype, doccode)
	CREATE INDEX TCHI_2 on #txconnhdrinput( doccode)


	CREATE TABLE #txconnlineinput 
	(
		doccode varchar(16),
		no	varchar(20),
		oriaddressline1	varchar(40),
		oriaddressline2	varchar(40),
		oriaddressline3	varchar(40),
		oricity	varchar(40),
		oriregion	varchar(40),
		oripostalcode	varchar(40),
		oricountry	varchar(40),
		destaddressline1	varchar(40),
		destaddressline2	varchar(40),
		destaddressline3	varchar(40),
		destcity	varchar(40),
		destregion	varchar(40),
		destpostalcode	varchar(40),
		destcountry	varchar(40),
		qty	float,		
		amount	float,		
		discounted	smallint, 
		exemptionno	varchar(20),
		itemcode	varchar(40) ,
		ref1	varchar(20) ,
		ref2	varchar(20) ,
		revacct	varchar(20) ,
		taxcode	varchar(8),
		customerUsageType varchar(20) null,
		description varchar(255) null,
		taxIncluded int null,
		taxOverrideReason varchar(100) null,
		taxOverrideTaxAmount decimal(20,8) null,
		taxOverrideTaxDate datetime null,
		taxOverrideType int null
	)

	create index TCLI_1 on #txconnlineinput( doccode, no)




	IF (@trx_type= 4091)
	BEGIN

		INSERT INTO #TxPrevCalculated
		SELECT DISTINCT @control_number , @trx_type , detail_sequence_id
		FROM #apinptaxdtl3500


	   	INSERT INTO #TxLineInput (control_number, reference_number, tax_code,
	                              quantity,       extended_price,   discount_amount,
	                              tax_type,       currency_code)
	     	SELECT 		     trx_ctrl_num,	sequence_id, 	tax_code, 
				     1,			amt_extended, amt_discount,
				     0,			@currency_code
	     	FROM #apinpcdt3500
	     	WHERE trx_ctrl_num = @control_number 
			AND trx_type = @trx_type
			AND sequence_id NOT IN 
				(	SELECT DISTINCT detail_sequence_id 
					FROM #apinptaxdtl3500
					WHERE trx_ctrl_num = @control_number 
					AND trx_type = @trx_type)						
	END

	IF (@trx_type= 4092)
	BEGIN

		INSERT INTO #TxPrevCalculated
		SELECT DISTINCT @control_number , @trx_type , detail_sequence_id
		FROM #apinptaxdtl3560


	    	INSERT INTO #TxLineInput (control_number, reference_number, tax_code,
	                              quantity,       extended_price,   discount_amount,
	                              tax_type,       currency_code)
	     	SELECT 		     trx_ctrl_num,	sequence_id, 	tax_code, 
				     1,			amt_extended, amt_discount,
				     0,		@currency_code
	     	FROM #apinpcdt3560
	     	WHERE trx_ctrl_num = @control_number 
			AND trx_type = @trx_type
			AND sequence_id NOT IN 
				(	SELECT DISTINCT detail_sequence_id 
					FROM #apinptaxdtl3560
					WHERE trx_ctrl_num = @control_number 
					AND trx_type = @trx_type)						
	END


	insert #txconnhdrinput
	(doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,
	discount, purchaseorderno, customercode, customerusagetype, detaillevel,
	referencecode, oriaddressline1, oriaddressline2, oriaddressline3,
	oricity, oriregion, oripostalcode, oricountry, destaddressline1,
	destaddressline2, destaddressline3, destcity, destregion, destpostalcode,
	destcountry)
	select @control_number, 3, @trx_type, '', getdate(), '', '',
	0, '', '', '', 3,
	'', '', '', '',
	'', '', '', '', '',
	'', '', '', '', '',
	''


	

	EXEC TXCalculateTax_SP

	IF (@trx_type= 4091)
	BEGIN
		INSERT INTO #apinptaxdtl3500
		( 	trx_ctrl_num,	sequence_id,	trx_type,
			tax_sequence_id,	detail_sequence_id,	tax_type_code,	
			amt_taxable,	amt_gross,	amt_tax,	amt_final_tax,	
			recoverable_flag,	account_code )
	
		SELECT t.control_number,  0,	@trx_type,
			t.reference_number, 	t.reference_number,	t.tax_type_code,
			i.extended_price- i.discount_amount, 	 i.extended_price, 	t.amt_taxable, 	t.amt_taxable, 
			ISNULL(recoverable_flag,0), ''                                      
		FROM #txdetail t
			INNER JOIN #TxLineInput i
				ON t.control_number = i.control_number
				AND t.reference_number = i.reference_number
			INNER JOIN artxtype ty
				ON ty.tax_type_code = t.tax_type_code
		WHERE ty.cents_code_flag = 0
			AND (ty.base_range_flag= 0 OR ( ty.base_range_flag= 1 AND ty.base_range_type <> 2 ) )
			AND  (ty.tax_range_flag =0  OR ( ty.tax_range_flag= 1 AND ty.tax_range_type <> 1 ))
		ORDER BY t.reference_number, t.tax_type_code


		UPDATE 	#apinptaxdtl3500
		SET 	tax_sequence_id = tx.sequence_id
		FROM 	#apinptaxdtl3500 a, #apinpcdt3500 b, artaxdet tx
		WHERE 	a.detail_sequence_id = b.sequence_id
		AND	b.tax_code = tx.tax_code
		AND 	a.tax_type_code = tx.tax_type_code


		UPDATE 	#apinptaxdtl3500
		






		SET 	amt_taxable = amt_taxable + ( SELECT ISNULL( MIN( b.amt_final_tax ), ( SELECT z.amt_tax 
													FROM apinptax z
													WHERE z.trx_ctrl_num = a.trx_ctrl_num 
													AND z.sequence_id = tx.base_id
													AND z.trx_type = 4091 )  )
		


							FROM #apinptaxdtl3500 b 
							WHERE a.detail_sequence_id = b.detail_sequence_id
							AND b.tax_sequence_id = tx.base_id )
		FROM 	#apinptaxdtl3500 a, #apinpcdt3500 b,  artaxdet tx, artxtype ty
		WHERE 	a.detail_sequence_id = b.sequence_id
		AND	b.tax_code = tx.tax_code
		AND 	a.tax_type_code = tx.tax_type_code
		AND 	tx.tax_type_code = ty.tax_type_code
		AND 	a.tax_type_code = ty.tax_type_code
		AND 	ty.prc_type = 2
		AND 	a.tax_sequence_id > 1
		AND	b.sequence_id NOT IN (SELECT sequence_id FROM #TxPrevCalculated txPC WHERE txPC.control_number = @control_number 
							AND txPC.trx_type = @trx_type)


		SELECT @sequence_id = 0, @detail_sequence_id=1

		UPDATE #apinptaxdtl3500
		SET account_code = d.gl_exp_acct,
		    sequence_id = @sequence_id,
		    @sequence_id = CASE WHEN detail_sequence_id <> @detail_sequence_id THEN 1 ELSE  @sequence_id +1 END,
		    @detail_sequence_id = detail_sequence_id
		FROM #apinptaxdtl3500 t, #apinpcdt3500 d
		WHERE t.trx_ctrl_num =d.trx_ctrl_num
		  AND t.trx_type = d.trx_type
		  AND t.detail_sequence_id  = d.sequence_id

	       DELETE  apinptaxdtl
	       WHERE trx_ctrl_num = @control_number 
			AND trx_type = @trx_type

	       INSERT INTO apinptaxdtl (trx_ctrl_num,   sequence_id,	trx_type,    
					tax_sequence_id ,	detail_sequence_id, tax_type_code, 
					amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax,                              
					recoverable_flag,	account_code        )
	       SELECT 			trx_ctrl_num,   sequence_id,	trx_type,    
					tax_sequence_id ,	detail_sequence_id, tax_type_code, 
					amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax,                              
					recoverable_flag,	account_code    FROM #apinptaxdtl3500
	END

	IF (@trx_type= 4092)
	BEGIN	
		INSERT INTO #apinptaxdtl3560
		( 	trx_ctrl_num,	sequence_id,	trx_type,
			tax_sequence_id,	detail_sequence_id,	tax_type_code,	
			amt_taxable,	amt_gross,	amt_tax,	amt_final_tax,	
			recoverable_flag,	account_code )
	
		SELECT t.control_number,  0,	@trx_type,
			t.reference_number, 	t.reference_number,	t.tax_type_code,
			i.extended_price- i.discount_amount, 	 i.extended_price, 	t.amt_taxable, 	t.amt_taxable, 
			ISNULL(recoverable_flag,0), ''                                      
		FROM #txdetail t
			INNER JOIN #TxLineInput i
				ON t.control_number = i.control_number
				AND t.reference_number = i.reference_number
			INNER JOIN artxtype ty
				ON ty.tax_type_code = t.tax_type_code
		WHERE ty.cents_code_flag = 0
			AND (ty.base_range_flag= 0 OR ( ty.base_range_flag= 1 AND ty.base_range_type <> 2 ) )
			AND  (ty.tax_range_flag =0  OR ( ty.tax_range_flag= 1 AND ty.tax_range_type <> 1 ))
		ORDER BY t.reference_number, t.tax_type_code
		

		UPDATE 	#apinptaxdtl3560
		SET 	tax_sequence_id = tx.sequence_id
		FROM 	#apinptaxdtl3560 a, #apinpcdt3560 b, artaxdet tx
		WHERE 	a.detail_sequence_id = b.sequence_id
		AND	b.tax_code = tx.tax_code
		AND 	a.tax_type_code = tx.tax_type_code


		UPDATE 	#apinptaxdtl3560
		






		SET 	amt_taxable = amt_taxable + ( SELECT ISNULL( MIN( b.amt_final_tax ), ( SELECT z.amt_tax 
													FROM apinptax z
													WHERE z.trx_ctrl_num = a.trx_ctrl_num 
													AND z.sequence_id = tx.base_id
													AND z.trx_type = 4092 )  )
		


							FROM #apinptaxdtl3560 b 
							WHERE a.detail_sequence_id = b.detail_sequence_id
							AND b.tax_sequence_id = tx.base_id )
		FROM 	#apinptaxdtl3560 a, #apinpcdt3560 b,  artaxdet tx, artxtype ty
		WHERE 	a.detail_sequence_id = b.sequence_id
		AND	b.tax_code = tx.tax_code
		AND 	a.tax_type_code = tx.tax_type_code
		AND tx.tax_type_code = ty.tax_type_code
		AND a.tax_type_code = ty.tax_type_code
		AND ty.prc_type = 2
		AND a.tax_sequence_id > 1
		AND	b.sequence_id NOT IN (SELECT sequence_id FROM #TxPrevCalculated txPC WHERE txPC.control_number = @control_number 
								AND txPC.trx_type = @trx_type)



		SELECT @sequence_id = 0, @detail_sequence_id=1
		UPDATE #apinptaxdtl3560
		SET account_code = d.gl_exp_acct,
		    sequence_id = @sequence_id,
		    @sequence_id = CASE WHEN detail_sequence_id <> @detail_sequence_id THEN 1 ELSE  @sequence_id +1 END,
		    @detail_sequence_id = detail_sequence_id
		FROM #apinptaxdtl3560 t, #apinpcdt3560 d
		WHERE t.trx_ctrl_num =d.trx_ctrl_num
		  AND t.trx_type = d.trx_type
		  AND t.detail_sequence_id  = d.sequence_id

	       DELETE  apinptaxdtl
	       WHERE trx_ctrl_num = @control_number 
			AND trx_type = @trx_type
		
	       INSERT INTO apinptaxdtl (trx_ctrl_num,   sequence_id,	trx_type,    
					tax_sequence_id ,	detail_sequence_id, tax_type_code, 
					amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax,                              
					recoverable_flag,	account_code        )
	       SELECT 			trx_ctrl_num,   sequence_id,	trx_type,    
					tax_sequence_id ,	detail_sequence_id, tax_type_code, 
					amt_taxable,  	amt_gross, 	amt_tax, 	amt_final_tax,                              
					recoverable_flag,	account_code    FROM #apinptaxdtl3560
	END



	DROP TABLE #TxInfo
	DROP TABLE #TxLineInput
	DROP TABLE #TxLineTax
	DROP TABLE #txdetail
	DROP TABLE #txinfo_id
	DROP TABLE #TxTLD
	DROP TABLE #TxPrevCalculated
GO
GRANT EXECUTE ON  [dbo].[apsavetaxdetails_sp] TO [public]
GO

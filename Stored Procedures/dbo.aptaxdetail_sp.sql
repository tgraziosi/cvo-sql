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









































  



					  

























































 

































































































































































































































































































CREATE PROCEDURE [dbo].[aptaxdetail_sp]  		@control_number		varchar(16),
						@reference_number	int,
						@tax_code			varchar(8),
						@extended_price		float,
						@discount_amount		float,
						@currency_code		varchar(8),
						@trx_type		smallint
						   
AS

		
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


	
	    INSERT INTO #TxLineInput (control_number, reference_number, tax_code,
	                              quantity,       extended_price,   discount_amount,
	                              tax_type,       currency_code)
	     VALUES		   (	@control_number , 0, @tax_code,
				       	1,      @extended_price,  @discount_amount,
				    	0,  @currency_code)
	

	
	
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




	insert #txconnhdrinput
	(doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,
	discount, purchaseorderno, customercode, customerusagetype, detaillevel,
	referencecode, oriaddressline1, oriaddressline2, oriaddressline3,
	oricity, oriregion, oripostalcode, oricountry, destaddressline1,
	destaddressline2, destaddressline3, destcity, destregion, destpostalcode,
	destcountry)
	select @control_number, 2, @trx_type, '', getdate(), '', '',
	0, '', '', '', 3,
	'', '', '', '',
	'', '', '', '', '',
	'', '', '', '', '',
	''

	
	
	EXEC TXCalculateTax_SP

	IF (@trx_type= 4091)
	BEGIN
		DELETE #apinptaxdtl3500
		WHERE trx_ctrl_num =@control_number
			AND trx_type = @trx_type
			AND detail_sequence_id = @reference_number
	
		INSERT INTO #apinptaxdtl3500
		( 	trx_ctrl_num,	sequence_id,	trx_type,
			tax_sequence_id,	detail_sequence_id,	tax_type_code,	
			amt_taxable,	amt_gross,	amt_tax,	amt_final_tax,	
			recoverable_flag,	account_code )
	
		SELECT control_number,  sequence_id,	@trx_type,
			@reference_number, 	@reference_number,	t.tax_type_code,
			t.amt_taxable, 	 t.amt_gross, 	t.amt_tax, 	t.amt_final_tax, 
			ISNULL(recoverable_flag,0),	''
		FROM #TxInfo t
			INNER JOIN artxtype ty
			ON ty.tax_type_code = t.tax_type_code
		WHERE ty.cents_code_flag = 0
			AND (ty.base_range_flag= 0 OR ( ty.base_range_flag= 1 AND ty.base_range_type <> 2 ) )
			AND  (ty.tax_range_flag =0  OR ( ty.tax_range_flag= 1 AND ty.tax_range_type = 1 ))
	END

	IF (@trx_type= 4092)
	BEGIN
		DELETE #apinptaxdtl3560
		WHERE trx_ctrl_num =@control_number
			AND trx_type = @trx_type
			AND detail_sequence_id = @reference_number
	
		INSERT INTO #apinptaxdtl3560
		( 	trx_ctrl_num,	sequence_id,	trx_type,
			tax_sequence_id,	detail_sequence_id,	tax_type_code,	
			amt_taxable,	amt_gross,	amt_tax,	amt_final_tax,	
			recoverable_flag,	account_code )
	
		SELECT control_number,  sequence_id,	@trx_type,
			@reference_number, 	@reference_number,	t.tax_type_code,
			t.amt_taxable, 	 t.amt_gross, 	t.amt_tax, 	t.amt_final_tax, 
			ISNULL(recoverable_flag,0),	''
		FROM #TxInfo t
			INNER JOIN artxtype ty
			ON ty.tax_type_code = t.tax_type_code
		WHERE ty.cents_code_flag = 0
			AND (ty.base_range_flag= 0 OR ( ty.base_range_flag= 1 AND ty.base_range_type <> 2 ) )
			AND  (ty.tax_range_flag =0  OR ( ty.tax_range_flag= 1 AND ty.tax_range_type = 1 ))

	END


	DROP TABLE #TxInfo
	DROP TABLE #TxLineInput
	DROP TABLE #TxLineTax
	DROP TABLE #txdetail
	DROP TABLE #txinfo_id
	DROP TABLE #TxTLD


GO
GRANT EXECUTE ON  [dbo].[aptaxdetail_sp] TO [public]
GO

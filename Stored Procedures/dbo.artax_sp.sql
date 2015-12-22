SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                













































CREATE PROC [dbo].[artax_sp]	
	@action smallint, @trx_ctrl_num varchar(16),
	@trx_type smallint, @tax_code varchar(8),
	@cents_code varchar(8), @taxtypecode varchar(8)
AS

IF	@action = 0
	RETURN



IF @action = 1
BEGIN
	SELECT	COUNT(*)
	FROM	artaxdet
	WHERE	tax_code = @tax_code
	RETURN
END




IF @action = 2
BEGIN
	SELECT	COUNT(*)
	FROM	arcendet
	WHERE	cents_code = @cents_code
	RETURN
END




IF @action = 3
BEGIN
	SELECT	to_cent, tax_cents
	FROM	arcendet
	WHERE	cents_code = @cents_code
	RETURN
END




IF @action = 4
BEGIN
	SELECT	a.tax_included_flag,
		b.tax_type_code,
		b.base_id,
		amt_tax,
		prc_flag,
		prc_type,
		cents_code_flag,
		cents_code,
		tax_based_type,
		c.tax_included_flag,
		modify_base_prc,
		base_range_flag,
		base_range_type,
		base_taxed_type,
		min_base_amt,
		max_base_amt,
		tax_range_flag,
		tax_range_type,
		min_tax_amt,
		max_tax_amt,
		1
	FROM	artax a, artaxdet b, artxtype c
	WHERE	a.tax_code = @tax_code
	AND	a.tax_code = b.tax_code
	AND	b.tax_type_code = c.tax_type_code
	RETURN
END




IF @action = 5
BEGIN

		SELECT	a.tax_type_code,
			amt_gross,
			amt_taxable,
			a.amt_tax,
			amt_final_tax,
			b.amt_tax,
			prc_flag,
			prc_type,
			cents_code_flag,
			cents_code,
			tax_based_type,
			tax_included_flag,
			modify_base_prc,
			base_range_flag,
			base_range_type,
			base_taxed_type,
			min_base_amt,
			max_base_amt,
			tax_range_flag,
			tax_range_type,
			min_tax_amt,
			max_tax_amt,
			1
		FROM	arinptax a, artxtype b
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND	trx_type = @trx_type
		AND	a.tax_type_code = b.tax_type_code
		RETURN




		
END




IF @action = 6
BEGIN
	SELECT	amt_tax,
		prc_flag,
		prc_type,
		cents_code_flag,
		cents_code,
		tax_based_type,
		tax_included_flag,
		modify_base_prc,
		base_range_flag,
		base_range_type,
		base_taxed_type,
		min_base_amt,
		max_base_amt,
		tax_range_flag,
		tax_range_type,
		min_tax_amt,
		max_tax_amt
	FROM	artxtype 
	WHERE	tax_type_code = @taxtypecode
	RETURN
END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[artax_sp] TO [public]
GO

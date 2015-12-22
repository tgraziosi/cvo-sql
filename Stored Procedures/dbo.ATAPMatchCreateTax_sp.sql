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









































  



					  

























































 

































































































































































































































































































CREATE PROCEDURE [dbo].[ATAPMatchCreateTax_sp] @debug_flag int = 0
AS
    
DECLARE @rowcount		INT
DECLARE @error			INT
DECLARE @errmsg			VARCHAR(128)
DECLARE @log_activity		VARCHAR(128)
DECLARE @procedure_name		VARCHAR(128)
DECLARE @location		VARCHAR(128)
DECLARE @buf			VARCHAR(1000)
DECLARE @ret			INT
DECLARE @text_value		VARCHAR(255)
DECLARE @int_value		INT
DECLARE @return_value		INT
DECLARE @transaction_started	INT
DECLARE @date_entered             INT
DECLARE @curr_precision         SMALLINT


DECLARE @trx_ctrl_num		varchar(16),	@sequence_id		int,		
	@amt_final_tax		float,	        @recoverable_flag	int,            @amt_nonrecoverable_tax float,          
        @amt_tax_det            float,		@tax_type_code		varchar(8)


SELECT @date_entered = DATEDIFF(DD,'1/1/80',GETDATE())+722815

SELECT @curr_precision = curr_precision
FROM glco, glcurr_vw
WHERE glco.home_currency = glcurr_vw.currency_code
    
CREATE TABLE #TxLineInput(	control_number	varchar(16),	reference_number	int,	tax_code		varchar(8),
				quantity	float,		extended_price		float,	discount_amount		float,
				tax_type	smallint,	currency_code		varchar(8)	)
    
INSERT INTO #TxLineInput( control_number,	reference_number,	tax_code,	quantity,	extended_price,	discount_amount,
			tax_type,	currency_code)
SELECT 			hdr.trx_ctrl_num, 	cdt.sequence_id,  	cdt.tax_code,	cdt.qty_received,cdt.amt_extended,	cdt.amt_discount,
	                   0,		hdr.nat_cur_code
FROM 	#apinpcdt cdt,	#apinpchg hdr
WHERE	hdr.trx_ctrl_num 	= cdt.trx_ctrl_num
AND 	hdr.trx_type 		= cdt.trx_type
AND	cdt.trx_type = 4091

INSERT INTO #TxLineInput( control_number,	reference_number,	tax_code,	quantity,	extended_price,	discount_amount,
			tax_type,	currency_code)
SELECT 			trx_ctrl_num, 		0,			tax_code,	1,		amt_freight,	0,
			1,		nat_cur_code
FROM #apinpchg
WHERE ((amt_freight) > (0.0) + 0.0000001)
    
CREATE TABLE #TxInfo (
	control_number		varchar(16),	sequence_id	int,	tax_type_code	varchar(8),	amt_taxable	float,
	amt_gross		float,		amt_tax		float,	amt_final_tax	float,		currency_code	varchar(8),
	tax_included_flag	smallint	)



CREATE TABLE #TxLineTax
(
	control_number	varchar(16),	reference_number	int,	tax_amount	float,	tax_included_flag	smallint )

CREATE TABLE #txdetail	(control_number	varchar(16),	reference_number	int,	tax_type_code	varchar(8),	amt_taxable	float	)

CREATE TABLE #txinfo_id	(id_col		numeric identity,	control_number	varchar(16),	sequence_id	int,	tax_type_code	varchar(8),	currency_code	varchar(8)	)

CREATE TABLE #TXInfo_min_id (control_number varchar(16),min_id_col numeric)

CREATE TABLE	#TxTLD	(control_number	varchar(16),	tax_type_code	varchar(8),	tax_code	varchar(8),	currency_code	varchar(8),
		tax_included_flag	smallint,	base_id		int,		amt_taxable	float,		amt_gross	float	)



	
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





declare @h_doc_type smallint,
        @tax_connect_flag       int,
        @tax_authcode_connect   varchar(8)



        select @h_doc_type = 3   -- purchase 2 , voucher 3

	INSERT #txconnhdrinput
		   (doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,
		    discount, purchaseorderno, customercode, customerusagetype, detaillevel, referencecode,
		    oriaddressline1, oriaddressline2, oriaddressline3, oricity, oriregion, 
		    oripostalcode, oricountry, 
		    destaddressline1, destaddressline2, destaddressline3, 
		    destcity, destregion, destpostalcode,     destcountry, 
			currCode, currRate)
	SELECT hdr.trx_ctrl_num, @h_doc_type, 4091, isnull(tc_companycode ,''), getdate(), '', '',
		     0,                    '', hdr.vendor_code,                 '',           3,     '', 
		    v.addr1 ,        v.addr2 ,                v.addr3 , v.city ,  v.state ,
		    v.postal_code , v.country_code ,
		    isnull(Org.addr1,''),    isnull(Org.addr2,''),     isnull(Org.addr3,''),  
		    isnull(Org.city,''),  isnull(Org.state,''), isnull(Org.postal_code,'' ), 
                    isnull(Org.country,''),
            hdr.nat_cur_code, hdr.rate_home
	FROM   #apinpchg hdr , 	Organization_all Org (nolock) , apmaster_all v (nolock)
	WHERE  hdr.org_id = Org.organization_id 
	  AND  hdr.vendor_code =  v.vendor_code 

IF (@debug_flag > 0)
BEGIN
 select '#txconnhdrinput'
 select * from #txconnhdrinput
 select '#TxLineInput'
 select * from #TxLineInput 
 select '#apinpchg'
 select * from #apinpchg
 select '#apinpcdt' 
 select * from #apinpcdt
 select '#epmchdtl'
select * from #epmchdtl 

END









EXEC TXCalculateTax_SP                    -- NOTE: TXCalculateTax_SP does not return a value


IF (@debug_flag > 0)
BEGIN

   SELECT @procedure_name = 'ATAPMatchCreateTax_sp'

    SELECT @procedure_name + ': #txdetail:'
    SELECT * FROM #txdetail

    SELECT @procedure_name + ': #txinfo_id:'
    SELECT * FROM #txinfo_id

    SELECT @procedure_name + ': #TXInfo_min_id:'
    SELECT * FROM #TXInfo_min_id

    SELECT @procedure_name + ': #TxTLD:'
    SELECT * FROM #TxTLD

END



UPDATE 	#apinpcdt
SET 	calc_tax = #TxLineTax.tax_amount
FROM 	#TxLineTax
WHERE 	#apinpcdt.trx_ctrl_num = #TxLineTax.control_number
AND 	#apinpcdt.sequence_id = #TxLineTax.reference_number






INSERT #apinptax (	trx_ctrl_num,		trx_type,		sequence_id,		tax_type_code,		
			amt_taxable,    	amt_gross,		amt_tax,		amt_final_tax,	
			trx_state,		mark_flag)
SELECT     		a.control_number,    	b.trx_type,    		a.sequence_id,    	a.tax_type_code,     
			a.amt_taxable, 		a.amt_gross,  b.amt_tax , b.amt_tax,  
			0,  			0
FROM     #TxInfo a, #apinpchg b --left outer join #apinpcdt_ATTax at 
WHERE  a.control_number = b.trx_ctrl_num
 AND b.at_tax_calc_flag = 1 AND exists ( select 1 from aptaxdet d where d.tax_type_code = a.tax_type_code AND d.tax_code = b.tax_code )


INSERT #apinptax (	trx_ctrl_num,		trx_type,		sequence_id,		tax_type_code,		
			amt_taxable,    	amt_gross,		amt_tax,		amt_final_tax,	
			trx_state,		mark_flag)
SELECT     		a.control_number,    	b.trx_type,    		a.sequence_id,    	a.tax_type_code,     
			a.amt_taxable, 		a.amt_gross,		a.amt_tax,           	a.amt_final_tax,  
			0,  			0
FROM     #TxInfo a, #apinpchg b
WHERE  a.control_number = b.trx_ctrl_num
AND b.at_tax_calc_flag = 0 




INSERT #apinptaxdtl(	trx_ctrl_num,				sequence_id,			trx_type,			
			tax_sequence_id,			detail_sequence_id,		tax_type_code,				
			amt_taxable,				amt_gross,			amt_tax,
			amt_final_tax,				recoverable_flag,		account_code) 
SELECT 		   	#txdetail.control_number,		id.sequence_id, 		#apinpcdt.trx_type,				
			#apinpcdt.sequence_id,			#apinpcdt.sequence_id,		#txdetail.tax_type_code,	
			#apinpcdt.amt_extended,			#apinpcdt.amt_extended,		#txdetail.amt_taxable ,		
			#txdetail.amt_taxable,			type.recoverable_flag,		#apinpcdt.gl_exp_acct 
FROM   #txdetail, #apinpcdt, aptxtype type, #txinfo_id id
WHERE  #txdetail.control_number 	= #apinpcdt.trx_ctrl_num 
AND    #txdetail.reference_number 	= #apinpcdt.sequence_id
AND    type.tax_type_code 		= #txdetail.tax_type_code
AND    #txdetail.control_number 	= id.control_number 
AND    #txdetail.tax_type_code 	        = id.tax_type_code
AND    type.cents_code_flag = 0
AND   ( type.tax_based_type != 2)
AND   ( type.tax_range_flag  = 0 OR ( type.tax_range_flag  = 1 AND type.tax_range_type != 0)) 
AND   ( type.base_range_flag = 0 OR ( type.base_range_flag = 1 AND type.base_range_type != 2 ))
AND exists (select 1 from #apinpchg 
				where #apinpchg.trx_ctrl_num = #apinpcdt.trx_ctrl_num and #apinpchg.trx_type = #apinpcdt.trx_type
				and #apinpchg.at_tax_calc_flag = 0 )


INSERT #apinptaxdtl(	trx_ctrl_num,				sequence_id,			trx_type,			
			tax_sequence_id,			detail_sequence_id,		tax_type_code,				
			amt_taxable,				amt_gross,			amt_tax,
			amt_final_tax,				recoverable_flag,		account_code) 
SELECT 		   	#txdetail.control_number,		id.sequence_id, 		#apinpcdt.trx_type,				
			#apinpcdt.sequence_id,			#apinpcdt.sequence_id,		#txdetail.tax_type_code,	
			#apinpcdt.amt_extended,			#apinpcdt.amt_extended,		#apinpcdt.calc_tax ,		
			#apinpcdt.calc_tax,			type.recoverable_flag,		#apinpcdt.gl_exp_acct 
FROM   #txdetail, #apinpcdt, aptxtype type, #txinfo_id id
WHERE  #txdetail.control_number 	= #apinpcdt.trx_ctrl_num 
AND    #txdetail.reference_number 	= #apinpcdt.sequence_id
AND    type.tax_type_code 		= #txdetail.tax_type_code
AND    #txdetail.control_number 	= id.control_number 
AND    #txdetail.tax_type_code 	        = id.tax_type_code
AND    type.cents_code_flag = 0
AND   ( type.tax_based_type != 2)
AND   ( type.tax_range_flag  = 0 OR ( type.tax_range_flag  = 1 AND type.tax_range_type != 0)) 
AND   ( type.base_range_flag = 0 OR ( type.base_range_flag = 1 AND type.base_range_type != 2 ))
AND exists (select 1 from #apinpchg 
				where #apinpchg.trx_ctrl_num = #apinpcdt.trx_ctrl_num and #apinpchg.trx_type = #apinpcdt.trx_type
				and #apinpchg.at_tax_calc_flag = 1 )


DECLARE update_header SCROLL CURSOR FOR
	SELECT 	tax.trx_ctrl_num ,  tax.tax_type_code
	FROM 	#apinptax tax, aptxtype type
	WHERE	tax.tax_type_code 	= type.tax_type_code
	AND    	type.tax_based_type 	= 2 
	AND 	recoverable_flag 	= 0
	ORDER BY tax.trx_ctrl_num, tax.tax_type_code

OPEN update_header

FETCH update_header INTO @trx_ctrl_num, @tax_type_code

WHILE @@FETCH_STATUS = 0
BEGIN

	SELECT 	@amt_nonrecoverable_tax = SUM(amt_final_tax)
	FROM	#apinptax
	WHERE	trx_ctrl_num 	= @trx_ctrl_num
	AND	tax_type_code 	= @tax_type_code

	UPDATE	#apinpchg
	SET	tax_freight_no_recoverable 	= tax_freight_no_recoverable + ISNULL(@amt_nonrecoverable_tax,0)
	WHERE	trx_ctrl_num 			= @trx_ctrl_num


	FETCH update_header INTO @trx_ctrl_num, @tax_type_code

END

CLOSE update_header
DEALLOCATE update_header

IF OBJECT_ID('tempdb..#epmchdtl') IS NOT NULL 
BEGIN
	UPDATE 	h
	SET      h.tax_code = dt.tax_code 
	FROM #apinpchg h, #epmchdtl dt, aptax tx (nolock)
	WHERE 	h.trx_ctrl_num 	= dt.match_ctrl_num AND 
		dt.tax_code	= tx.tax_code AND
		tx.tax_connect_flag 	= 1
END



DECLARE	trx_ctrl_num_sum SCROLL CURSOR FOR
		SELECT 	#apinptaxdtl.trx_ctrl_num, #apinptaxdtl.detail_sequence_id, #apinptaxdtl.amt_final_tax, #apinptaxdtl.recoverable_flag
		FROM 	#apinptaxdtl
		ORDER BY #apinptaxdtl.trx_ctrl_num, #apinptaxdtl.sequence_id

OPEN	trx_ctrl_num_sum 

FETCH	trx_ctrl_num_sum
INTO	@trx_ctrl_num, @sequence_id, @amt_final_tax, @recoverable_flag

SELECT @amt_nonrecoverable_tax= 0
SELECT @amt_tax_det = 0  

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @recoverable_flag = 0
	BEGIN
       		SELECT @amt_tax_det = 0
		SELECT @amt_nonrecoverable_tax = @amt_final_tax
        END
     	ELSE	
	BEGIN
		SELECT @amt_nonrecoverable_tax = 0
      		SELECT @amt_tax_det = @amt_final_tax 
	END
			
	UPDATE 	#apinpcdt
	SET 	amt_nonrecoverable_tax 	= amt_nonrecoverable_tax + @amt_nonrecoverable_tax,
		amt_tax_det 		= amt_tax_det + @amt_tax_det
	WHERE 	#apinpcdt.trx_ctrl_num 	= @trx_ctrl_num
	AND 	#apinpcdt.sequence_id 	= @sequence_id  
		
	FETCH trx_ctrl_num_sum
	INTO	@trx_ctrl_num, @sequence_id,@amt_final_tax,@recoverable_flag

END

CLOSE trx_ctrl_num_sum
DEALLOCATE trx_ctrl_num_sum





DROP TABLE #txdetail
DROP TABLE #txinfo_id
DROP TABLE #TXInfo_min_id
DROP TABLE #TxTLD

IF (@debug_flag > 0)
BEGIN

    SELECT @procedure_name + ': #apinptax:'
    SELECT * FROM #apinptax

    SELECT @procedure_name + ': #apinptaxdtl:'
    SELECT * FROM #apinptaxdtl


END


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[ATAPMatchCreateTax_sp] TO [public]
GO

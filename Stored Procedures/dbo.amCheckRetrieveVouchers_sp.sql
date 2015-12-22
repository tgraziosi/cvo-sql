SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCheckRetrieveVouchers_sp]
(
	@company_id			smCompanyID,		
	@all_vouchers		smLogical,			



	@debug_level		smDebugLevel = 0	
)
AS

DECLARE
	@result				smErrorCode,
	@message			smErrorLongDesc,
 	@voucher_ctrl_num	smControlNumber		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amchrtvc.cpp" + ", line " + STR( 67, 5 ) + " -- ENTRY: "





CREATE TABLE #retrieve_vouchers
(
    trx_ctrl_num		varchar(16),
	hits_fac			tinyint
)




INSERT INTO #retrieve_vouchers
(
		trx_ctrl_num,
		hits_fac
)
SELECT	
		trx_ctrl_num,
		0
FROM 	amapnew

SELECT	@result = @@error
IF @result <> 0
	RETURN @result


UPDATE 	#retrieve_vouchers
SET		hits_fac 			= 1
FROM	#retrieve_vouchers tmp,
		apvodet		apdet,
		amfac		fac
WHERE	apdet.trx_ctrl_num 	= tmp.trx_ctrl_num
AND		fac.company_id		= @company_id
AND		apdet.gl_exp_acct 	LIKE RTRIM(fac.fac_mask)
		
IF @debug_level >= 5
	SELECT * 
	FROM	#retrieve_vouchers
				
IF @all_vouchers = 1
BEGIN
	INSERT INTO #amrtvch
	SELECT DISTINCT	tmp.trx_ctrl_num,
			ap.doc_ctrl_num,
			ap.vendor_code,
			ap.currency_code,
			cur.currency_mask,
			ap.amt_net,
			tmp.hits_fac,
			ap.org_id,
			dbo.IBGetParent_fn (ap.org_id)  
	FROM	#retrieve_vouchers			tmp,
			apvohdr				ap,
			CVO_Control..mccurr	cur,
			region_vw r
	WHERE	tmp.trx_ctrl_num 	= ap.trx_ctrl_num
	AND ap.org_id = r.org_id
	AND		ap.currency_code		= cur.currency_code
	ORDER BY	tmp.trx_ctrl_num
END
ELSE
BEGIN
	INSERT INTO #amrtvch
	SELECT DISTINCT	tmp.trx_ctrl_num,
			ap.doc_ctrl_num,
			ap.vendor_code,
			ap.currency_code,
			cur.currency_mask,
			ap.amt_net,
			tmp.hits_fac,
			ap.org_id,
			dbo.IBGetParent_fn (ap.org_id)   
	FROM	#retrieve_vouchers			tmp,
			apvohdr				ap,
			CVO_Control..mccurr	cur,
			region_vw r
	WHERE	tmp.trx_ctrl_num 	= ap.trx_ctrl_num
	AND ap.org_id = r.org_id
	AND		ap.currency_code	= cur.currency_code
	AND		tmp.hits_fac		= 1
	ORDER BY	tmp.trx_ctrl_num
END
			
DROP TABLE #retrieve_vouchers

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amchrtvc.cpp" + ", line " + STR( 156, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCheckRetrieveVouchers_sp] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[apdehdr4_sp] @error_level smallint, @debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdehdr4.cpp' + ', line ' + STR( 28, 5 ) + ' -- ENTRY: '






	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdehdr4.cpp' + ', line ' + STR( 35, 5 ) + ' -- MSG: ' + 'Validate posting code account status'

	SELECT DISTINCT posting_code,
	                date_applied,
					org_id
	INTO #post_codes
	FROM #apdmvchg 

	SELECT b.posting_code,
		   a.date_applied,
	       acct_code = dbo.IBAcctMask_fn(b.ap_acct_code,a.org_id),
	       flag	= 0
	INTO #posting_accts
	FROM #post_codes a, apaccts b
	WHERE a.posting_code = b.posting_code


	INSERT #posting_accts
	SELECT b.posting_code,
	       a.date_applied,
	       dbo.IBAcctMask_fn(b.purc_ret_acct_code,a.org_id),
		   0
	FROM #post_codes a, apaccts b
	WHERE a.posting_code = b.posting_code

	INSERT #posting_accts
	SELECT b.posting_code,
	       a.date_applied,
	       dbo.IBAcctMask_fn(b.freight_acct_code, a.org_id),
		   0
	FROM #post_codes a, apaccts b
	WHERE a.posting_code = b.posting_code

	INSERT #posting_accts
	SELECT b.posting_code,
	       a.date_applied,
	       dbo.IBAcctMask_fn(b.disc_given_acct_code,a.org_id),
		   0
	FROM #post_codes a, apaccts b
	WHERE a.posting_code = b.posting_code

	INSERT #posting_accts
	SELECT b.posting_code,
	       a.date_applied,
	       dbo.IBAcctMask_fn(b.disc_taken_acct_code,a.org_id),
		   0
	FROM #post_codes a, apaccts b
	WHERE a.posting_code = b.posting_code

	INSERT #posting_accts
	SELECT b.posting_code,
	       a.date_applied,
	       dbo.IBAcctMask_fn(b.misc_chg_acct_code,a.org_id),
		   0
	FROM #post_codes a, apaccts b
	WHERE a.posting_code = b.posting_code

	INSERT #posting_accts
	SELECT b.posting_code,
	       a.date_applied,
	       dbo.IBAcctMask_fn(b.sales_tax_acct_code,a.org_id),
		   0
	FROM #post_codes a, apaccts b
	WHERE a.posting_code = b.posting_code



IF (SELECT err_type FROM apedterr WHERE err_code = 20005) <= @error_level
BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdehdr4.cpp' + ', line ' + STR( 104, 5 ) + ' -- MSG: ' + 'check if account is inactive'
      UPDATE #posting_accts
	  SET flag = 1
      FROM #posting_accts a, glchart b
	  WHERE a.acct_code = b.account_code
	  AND b.inactive_flag = 1


      INSERT #ewerror
	  SELECT 4000,
	  		 20005,
			 b.posting_code + '--' + c.acct_code,
			 '',
			 0,
			 0.0,
			 1,
	  		 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apdmvchg b, #posting_accts c
	  WHERE b.posting_code = c.posting_code
	  AND b.date_applied = c.date_applied
	  AND c.flag = 1

END


IF (SELECT err_type FROM apedterr WHERE err_code = 20007) <= @error_level
BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdehdr4.cpp' + ', line ' + STR( 134, 5 ) + ' -- MSG: ' + 'check if account is invalid for the apply date'
	  UPDATE #posting_accts
	  SET flag = 2
	  FROM #posting_accts a, glchart b
	  WHERE a.acct_code = b.account_code
	  AND ((a.date_applied < b.active_date
	        AND b.active_date != 0)
	  OR (a.date_applied > b.inactive_date
	       AND b.inactive_date != 0))



      INSERT #ewerror
	  SELECT 4000,
			 20007,
			 b.posting_code + '--' + c.acct_code,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apdmvchg b, #posting_accts c
	  WHERE b.posting_code = c.posting_code
	  AND b.date_applied = c.date_applied
	  AND c.flag = 2
END


IF (SELECT err_type FROM apedterr WHERE err_code = 20505) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdehdr4.cpp' + ', line ' + STR( 167, 5 ) + ' -- MSG: ' + 'Validate nat_cur_code exists'
	


      INSERT #ewerror
	  SELECT 4000,
			 20505,
			 nat_cur_code,
			 '',
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apdmvchg 
  	  WHERE nat_cur_code NOT IN (SELECT currency_code FROM glcurr_vw)
END

IF (SELECT err_type FROM apedterr WHERE err_code = -20109) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdehdr4.cpp' + ', line ' + STR( 189, 5 ) + ' -- MSG: ' + 'Validate nat_cur_code for tax connect service'
	


      INSERT #ewerror
	  SELECT 4000,
			 -20109,
			 a.nat_cur_code,
			 '',
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apdmvchg a, apinpchg ap (nolock), aptax tax
  	  WHERE a.trx_ctrl_num = ap.trx_ctrl_num and ap.tax_code = tax.tax_code 
			and tax.tax_connect_flag = 1 and a.nat_cur_code NOT IN (SELECT currency_code FROM gltc_currency)
END

IF (SELECT err_type FROM apedterr WHERE err_code = 20506) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdehdr4.cpp' + ', line ' + STR( 212, 5 ) + ' -- MSG: ' + 'Validate rate_type_home exists'
	


      INSERT #ewerror
	  SELECT 4000,
			 20506,
			 rate_type_home,
			 '',
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apdmvchg 
  	  WHERE rate_type_home NOT IN (SELECT rate_type FROM glrtype_vw)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 20507) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdehdr4.cpp' + ', line ' + STR( 236, 5 ) + ' -- MSG: ' + 'Validate rate_type_oper exists'
	


      INSERT #ewerror
	  SELECT 4000,
			 20507,
			 rate_type_oper,
			 '',
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apdmvchg 
  	  WHERE rate_type_oper NOT IN (SELECT rate_type FROM glrtype_vw)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 20508) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdehdr4.cpp' + ', line ' + STR( 260, 5 ) + ' -- MSG: ' + 'Verification of posting code is valid for currency voucher'
	


      INSERT #ewerror
	  SELECT 4000,
			 20508,
			 b.posting_code,
			 '',
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 '',
			 0
	  FROM #apdmvchg b, apaccts c
  	  WHERE b.posting_code = c.posting_code
      AND b.nat_cur_code != c.nat_cur_code
      AND c.nat_cur_code != '' 
END



DROP TABLE #posting_accts
DROP TABLE #post_codes



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdehdr4.cpp' + ', line ' + STR( 289, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apdehdr4_sp] TO [public]
GO

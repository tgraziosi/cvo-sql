SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[apvehdr6_sp] @error_level smallint, @debug_level smallint = 0
AS

DECLARE @credit_invoice_flag smallint


DECLARE @posting_accts TABLE( posting_code varchar(8),
		   		date_applied int,
    	       			acct_code varchar(32),
	       			flag	smallint)

DECLARE @post_codes TABLE (posting_code varchar(8),
	                date_applied int,
			org_id varchar(30))

declare @ib_offset smallint, @ib_seg smallint, @ib_length smallint, @segment_length smallint, @ib_flag smallint 

select @ib_offset = ib_offset, @ib_seg = ib_segment, @ib_length = ib_length, @ib_flag = ib_flag from glco 
--select @segment_length = ISNULL(sum(length),0) from glaccdef where acct_level < @ib_seg
-- scr 38330

  select @segment_length = ISNULL(start_col - 1, 0 ) from glaccdef where acct_level = @ib_seg 

-- end 38330	



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 70, 5 ) + " -- ENTRY: "


IF (SELECT err_type FROM apedterr WHERE err_code = 10710) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 75, 5 ) + " -- MSG: " + "Check if amt_tax exceeds tax detail distribution"

      INSERT #ewerror
	  SELECT 4000,
			 10710,
			 "",
			 "",
			 0,
			 b.amt_tax,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, #apvovtax c
  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_tax
	  HAVING 
((ABS(b.amt_tax)) > (SUM(ABS(c.amt_final_tax))) + 0.0000001)	
END




SELECT @credit_invoice_flag = credit_invoice_flag FROM apco

IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 10740) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 105, 5 ) + " -- MSG: " + "Check if amt_freight is negative"

      INSERT #ewerror
	  SELECT 4000,
			 10740,
			 "",
			 "",
			 0,
			 amt_freight,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE ((amt_freight) < (0.0) - 0.0000001)
END

END

IF (SELECT err_type FROM apedterr WHERE err_code = 10730) <= @error_level
BEGIN
  	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 127, 5 ) + " -- MSG: " + "Check if amt_freight = line item distribution"

      INSERT #ewerror
	  SELECT 4000,
			 10730,
			 "",
			 "",
			 0,
			 b.amt_freight,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, #apvovcdt c
  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_freight
	  HAVING 
(ABS((b.amt_freight)-(SUM(c.amt_freight))) > 0.0000001)
END

IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 10760) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 152, 5 ) + " -- MSG: " + "Check if amt_misc is negative"

      INSERT #ewerror
	  SELECT 4000,
			 10760,
			 "",
			 "",
			 0,
			 amt_misc,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg
  	  WHERE ((amt_misc) < (0.0) - 0.0000001)
END

END

IF (SELECT err_type FROM apedterr WHERE err_code = 10750) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 174, 5 ) + " -- MSG: " + "Check if amt_misc = line item distribution"

      INSERT #ewerror
	  SELECT 4000,
			 10750,
			 "",
			 "",
			 0,
			 b.amt_misc,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, #apvovcdt c
  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_misc
	  HAVING 
(ABS((b.amt_misc)-(SUM(c.amt_misc))) > 0.0000001) 
END

IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 10770) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 199, 5 ) + " -- MSG: " + "Check if amt_paid is negative"
	
      INSERT #ewerror
	  SELECT 4000,
			 10770,
			 "",
			 "",
			 0,
			 amt_paid,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg
  	  WHERE ((amt_paid) < (0.0) - 0.0000001)
END

END

IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 10780) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 223, 5 ) + " -- MSG: " + "Check if amt_paid > amt_net"
	
      INSERT #ewerror
	  SELECT 4000,
			 10780,
			 "",
			 "",
			 0,
			 amt_paid,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE ((amt_paid) > (amt_net) + 0.0000001)
END

END

IF (SELECT err_type FROM apedterr WHERE err_code = 10790) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 245, 5 ) + " -- MSG: " + "Check if any amount paid will be put on account"

      INSERT #ewerror
	  SELECT 4000,
			 10790,
			 "",
			 "",
			 0,
			 b.amt_paid - SUM(c.amt_payment),
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, #apvovtmp c
  	  WHERE b.trx_ctrl_num = c.trx_ctrl_num
	  GROUP BY b.trx_ctrl_num, b.amt_paid
	  HAVING ((b.amt_paid) < (SUM(c.amt_payment)) - 0.0000001)
END

IF @credit_invoice_flag = 0
BEGIN
IF (SELECT err_type FROM apedterr WHERE err_code = 10820) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 269, 5 ) + " -- MSG: " + "Check if amt_net is negative"
      INSERT #ewerror
	  SELECT 4000,
			 10820,
			 "",
			 "",
			 0,
			 amt_net,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE ((amt_net) < (0.0) - 0.0000001)
END

END


IF (SELECT err_type FROM apedterr WHERE err_code = 10800) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 291, 5 ) + " -- MSG: " + "Check if amt_net = gross + tax + freight + freight tax no recoverable  + misc - disc"
      INSERT #ewerror
	  SELECT 4000,
			 10800,
			 "",
			 "",
			 0,
			 amt_net,
			 4,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE 
(ABS((amt_net)-(amt_gross + amt_tax + amt_freight + tax_freight_no_recoverable + amt_misc - amt_discount)) > 0.0000001)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10810) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 312, 5 ) + " -- MSG: " + "Check if voucher of same amount and vendor already exists"






















        INSERT #ewerror
	  SELECT 4000,
			 10810,
			 "",
			 "",
			 0,
			 b.amt_net,
			 4,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, apinpchg_all c (nolock)
	  WHERE c.vendor_code = b.vendor_code
	  AND c.amt_net = b.amt_net
	  AND c.trx_ctrl_num != b.trx_ctrl_num
	  AND c.trx_type = 4091


END	






	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 361, 5 ) + " -- MSG: " + "Validate posting code account status"




	INSERT INTO @post_codes	
	SELECT DISTINCT posting_code,
	                date_applied,
			org_id
	FROM #apvovchg 

	INSERT INTO @posting_accts
	SELECT b.posting_code,
		   a.date_applied,
    	   acct_code = CASE WHEN @ib_flag = 0 THEN b.ap_acct_code
						ELSE STUFF(b.ap_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END,  
	       flag	= 0
	FROM @post_codes a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		INNER JOIN Organization c ON a.org_id = c.organization_id

	UNION ALL


	SELECT b.posting_code,
	       a.date_applied,
	       CASE WHEN @ib_flag = 0 THEN b.purc_ret_acct_code
			ELSE STUFF(b.purc_ret_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
	       0
	FROM @post_codes a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		INNER JOIN Organization c ON a.org_id = c.organization_id

	UNION ALL


	SELECT b.posting_code,
	       a.date_applied,
			CASE WHEN @ib_flag = 0 THEN b.freight_acct_code
				ELSE STUFF(b.freight_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
		   0
	FROM @post_codes a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		INNER JOIN Organization c ON a.org_id = c.organization_id

	UNION ALL


	SELECT b.posting_code,
	       a.date_applied,
			CASE WHEN @ib_flag = 0 THEN b.disc_given_acct_code
			ELSE STUFF(b.disc_given_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
		   0
	FROM @post_codes a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		INNER JOIN Organization c ON a.org_id = c.organization_id

	UNION ALL


	SELECT b.posting_code,
	       a.date_applied,
			CASE WHEN @ib_flag = 0 THEN b.disc_taken_acct_code
			ELSE STUFF(b.disc_taken_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
		   0
	FROM @post_codes a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		INNER JOIN Organization c ON a.org_id = c.organization_id

	UNION ALL


	SELECT b.posting_code,
	       a.date_applied,
			CASE WHEN @ib_flag = 0 THEN b.misc_chg_acct_code
			ELSE STUFF(b.misc_chg_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
		   0
	FROM @post_codes a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		INNER JOIN Organization c ON a.org_id = c.organization_id

	UNION ALL


	SELECT b.posting_code,
	       a.date_applied,
	       CASE WHEN @ib_flag = 0 THEN b.sales_tax_acct_code
		   ELSE STUFF(b.sales_tax_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
		   0
	FROM @post_codes a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		INNER JOIN Organization c ON a.org_id = c.organization_id



IF (SELECT err_type FROM apedterr WHERE err_code = 10005) <= @error_level
BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 458, 5 ) + " -- MSG: " + "check if account is inactive"
	UPDATE @posting_accts
	  SET flag = 1
	FROM @posting_accts a, glchart b	
	  WHERE a.acct_code = b.account_code
	  AND b.inactive_flag = 1


      INSERT #ewerror
	  SELECT 4000,
	  		 10005,
			 b.posting_code + "--" + c.acct_code,
			 "",
			 0,
			 0.0,
			 1,
	  		 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, @posting_accts c
	  WHERE b.posting_code = c.posting_code
	  AND b.date_applied = c.date_applied
	  AND c.flag = 1

END


IF (SELECT err_type FROM apedterr WHERE err_code = 10007) <= @error_level
BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 488, 5 ) + " -- MSG: " + "check if account is invalid for the apply date"
	  UPDATE @posting_accts	
	  SET flag = 2
	  FROM @posting_accts a, glchart b	
	  WHERE a.acct_code = b.account_code
	  AND ((a.date_applied < b.active_date
	        AND b.active_date != 0)
	  OR (a.date_applied > b.inactive_date
	       AND b.inactive_date != 0))



      INSERT #ewerror
	  SELECT 4000,
			 10007,
			 b.posting_code + "--" + c.acct_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, @posting_accts c
	  WHERE b.posting_code = c.posting_code
	  AND b.date_applied = c.date_applied
	  AND c.flag = 2
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10505) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 521, 5 ) + " -- MSG: " + "Validate nat_cur_code exists"
	


      INSERT #ewerror
	  SELECT 4000,
			 10505,
			 nat_cur_code,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE nat_cur_code NOT IN (SELECT currency_code FROM glcurr_vw)
END

IF (SELECT err_type FROM apedterr WHERE err_code = -10109) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 543, 5 ) + " -- MSG: " + "Validate nat_cur_code for tax connect service"
	


      INSERT #ewerror
	  SELECT 4000,
			 -10109,
			 a.nat_cur_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg a, apinpchg ap, aptax tax
  	  WHERE a.trx_ctrl_num = ap.trx_ctrl_num and ap.tax_code = tax.tax_code 
			and tax.tax_connect_flag = 1 and a.nat_cur_code NOT IN (SELECT currency_code FROM gltc_currency)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 10506) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 568, 5 ) + " -- MSG: " + "Validate rate_type_home exists"
	


      INSERT #ewerror
	  SELECT 4000,
			 10506,
			 rate_type_home,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE rate_type_home NOT IN (SELECT rate_type FROM glrtype_vw)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 10507) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 592, 5 ) + " -- MSG: " + "Validate rate_type_oper exists"
	


      INSERT #ewerror
	  SELECT 4000,
			 10507,
			 rate_type_oper,
			 "",
			 0,
			 0.0,
			 1,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE rate_type_oper NOT IN (SELECT rate_type FROM glrtype_vw)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 10508) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 616, 5 ) + " -- MSG: " + "Verification of posting code is valid for currency voucher"
	


      INSERT #ewerror
	  SELECT 4000,
			 10508,
			 b.posting_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b, apaccts c
  	  WHERE b.posting_code = c.posting_code
      AND b.nat_cur_code != c.nat_cur_code
      AND c.nat_cur_code != "" 
END





IF (SELECT err_type FROM apedterr WHERE err_code = 19230) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 607, 5 ) + " -- MSG: " + "Verification of Home rate is valid for currency voucher"



     INSERT #ewerror
	  SELECT 4000,
			 19230,
			 a.rate_home,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg a, glcurr_vw  gl 
	  WHERE  a.nat_cur_code = gl.currency_code 
	  and a.rate_home = 0
END

IF (((SELECT err_type FROM apedterr WHERE err_code = 19240) <= @error_level) AND (2 = (select  multi_currency_flag from glco)))
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 631, 5 ) + " -- MSG: " + "Verification of Operational rate is valid for currency voucher"
	


     INSERT #ewerror
	  SELECT 4000,
			 19240,
			 a.rate_oper,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg a, glcurr_vw  gl 
	  WHERE  a.nat_cur_code = gl.currency_code 
	  and a.rate_oper = 0
END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr6.cpp" + ", line " + STR( 652, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvehdr6_sp] TO [public]
GO

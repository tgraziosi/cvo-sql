SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvehdr2_sp] @error_level smallint, @debug_level smallint = 0
AS

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 35, 5 ) + " -- ENTRY: "



IF (SELECT err_type FROM apedterr WHERE err_code = 10300) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 41, 5 ) + " -- MSG: " + "Validate if class_code is valid or blank"
	


      INSERT #ewerror
	  SELECT 4000,
			 10300,
			 a.class_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg a
		LEFT JOIN apclass b ON a.class_code = b.class_code 
  	  WHERE a.class_code != "" AND b.class_code IS NULL
END
	  						 

IF (SELECT err_type FROM apedterr WHERE err_code = 10310) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 65, 5 ) + " -- MSG: " + "Check if class_code is vendors default"
	


      

















	 INSERT #ewerror
		 SELECT 4000,
				 10310,
				 b.class_code,
				 "",
				 0,
				 0.0,
				 1,
				 b.trx_ctrl_num,
				 0,
				 "",
				 0
		 FROM #apvovchg b
			INNER JOIN apmaster_all c (nolock) ON b.vendor_code = c.vendor_code AND b.class_code != c.vend_class_code 
			INNER JOIN apclass d (nolock) ON b.class_code = d.class_code
	 	 WHERE c.address_type = 0

END


IF ((SELECT aprv_voucher_flag FROM apco) = 1)
 BEGIN
   IF (SELECT err_type FROM apedterr WHERE err_code = 10330) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 111, 5 ) + " -- MSG: " + "Check if approval code is blank"
		


      INSERT #ewerror
	  SELECT DISTINCT 4000,
			 10330,
			 a.approval_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
		  FROM #apvovchg a
			INNER JOIN apaprtrx b ON a.trx_ctrl_num = b.trx_ctrl_num
	  	  WHERE b.trx_type = 4091
	  	  AND a.approval_code = ""
	 END


   IF (SELECT err_type FROM apedterr WHERE err_code = 10320) <= @error_level
    BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 136, 5 ) + " -- MSG: " + "Check if approval code is not valid and is not blank"
		


      INSERT #ewerror
	  SELECT 4000,
			 10320,
			 b.approval_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
		  FROM #apvovchg b
			LEFT JOIN apapr c ON b.approval_code = c.approval_code 
	  	  WHERE b.approval_code != ""
			AND c.approval_code  IS NULL
	 END

	 IF ((SELECT default_aprv_flag FROM apco) = 1)
	    BEGIN
			 IF ((SELECT aprv_opr_flag FROM apco) = 0)
			   BEGIN
				  IF (SELECT err_type FROM apedterr WHERE err_code = 10360) <= @error_level
				   BEGIN
				      INSERT #ewerror
					  SELECT 4000,
							 10360,
							 b.approval_code,
							 "",
							 0,
							 0.0,
							 1,
						 	 b.trx_ctrl_num,
							 0,
						 	 "",
						 	 0
					  FROM #apvovchg b
						LEFT JOIN apco c ON b.approval_code = c.default_aprv_code 
			  		  WHERE b.approval_code != ""
						AND c.default_aprv_code IS NULL
				  END
			  END
			ELSE
			  BEGIN
				IF (SELECT err_type FROM apedterr WHERE err_code = 10370) <= @error_level
				 BEGIN
					      INSERT #ewerror
						  SELECT 4000,
						  		 10370,
						  		 b.approval_code,
						  		 "",
						  		 0,
						  		 0.0,
						  		 1,
						  		 b.trx_ctrl_num,
								 0,
								 "",
								 0
					  FROM #apvovchg b
						LEFT JOIN apco c ON b.approval_code = c.default_aprv_code 
			  		  WHERE b.approval_code != ""
						AND c.default_aprv_code  IS NULL
				END
			 END
		END
   ELSE
	BEGIN
	  IF (SELECT err_type FROM apedterr WHERE err_code = 10350) <= @error_level
	   BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 209, 5 ) + " -- MSG: " + "Check if approval code is not valid and is not blank"
			


			      INSERT #ewerror
				  SELECT 4000,
						 10350,
						 b.approval_code,
						 "",
						 0,
						 0.0,
						 1,
						 b.trx_ctrl_num,
						 0,
						 "",
					 	 0
			  FROM #apvovchg b
				LEFT JOIN apapr c ON b.approval_code = c.approval_code 
		  	  WHERE b.approval_code != ""
				AND c.approval_code  IS NULL
	   END
	 END
END



IF (SELECT err_type FROM apedterr WHERE err_code = 10590) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 237, 5 ) + " -- MSG: " + "Check if approval flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10590,
			 "",
			 "",
			 approval_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE approval_flag NOT IN (0,1)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10580) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 260, 5 ) + " -- MSG: " + "Check if voucher isn't approved"
	


      INSERT #ewerror
	  SELECT 4000,
		     10580,
			 "",
			 "",
			 approval_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg 
  	  WHERE approval_flag = 1
END



IF (SELECT err_type FROM apedterr WHERE err_code = 10390) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 284, 5 ) + " -- MSG: " + "Check if comment code is not valid and is not blank"
	


      INSERT #ewerror
	  SELECT 4000,
			 10390,
			 b.comment_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b
		LEFT JOIN apcommnt c ON b.comment_code = c.comment_code 
  	  WHERE b.comment_code != ""
		AND c.comment_code  IS NULL
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10380) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 309, 5 ) + " -- MSG: " + "Check if comment code is not the default"
	


	

















	 INSERT #ewerror
		 SELECT 4000,
				 10380,
				 b.comment_code,
				 "",
				 0,
				 0.0,
				 1,
				 b.trx_ctrl_num,
				 0,
				 "",
				 0
		 FROM #apvovchg b, apcommnt c (nolock), apmaster_all d (nolock)
	 	 WHERE b.comment_code = c.comment_code
		 AND b.vendor_code = d.vendor_code
		 AND b.comment_code != d.comment_code
		 AND d.address_type = 0


END


IF (SELECT err_type FROM apedterr WHERE err_code = 10410) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 355, 5 ) + " -- MSG: " + "Check if fob code is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10410,
			 a.fob_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg a
		LEFT JOIN apfob b ON a.fob_code = b.fob_code 
  	  WHERE a.fob_code != ""
		AND b.fob_code  IS NULL
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10400) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 380, 5 ) + " -- MSG: " + "Check if fob code is not the default"
	


	


















--REV 2.1
      INSERT #ewerror
	 SELECT 4000,
			 10400,
			 b.fob_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovchg b, apfob c (nolock), apmaster_all d (nolock)
 	 WHERE b.fob_code = c.fob_code
	 AND b.vendor_code = d.vendor_code
	 AND b.fob_code != d.fob_code
	 AND b.pay_to_code = ""
	 AND d.address_type  = 0	


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 424, 5 ) + " -- MSG: " + "Check if fob code is not the default"
	


	


















--REV 2.1
	 INSERT #ewerror
		 SELECT 4000,
				 10400,
				 b.fob_code,
				 "",
				 0,
				 0.0,
				 1,
				 b.trx_ctrl_num,
				 0,
				 "",
				 0
		 FROM #apvovchg b, apfob c (nolock), apmaster_all d (nolock)
	 	 WHERE b.fob_code = c.fob_code
		 AND b.vendor_code = d.vendor_code
		 AND b.pay_to_code = d.pay_to_code
		 AND b.fob_code != d.fob_code
		 AND d.address_type  = 1
	
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10420) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 472, 5 ) + " -- MSG: " + "Check if terms code is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10420,
			 a.terms_code,
			 "",
			 0,
			 0.0,
			 1,
			 a.trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg a
		LEFT JOIN apterms b ON a.terms_code = b.terms_code 
  	  WHERE a.terms_code != ""
		AND b.terms_code IS NULL
END


IF (SELECT err_type FROM apedterr WHERE err_code = 10430) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 497, 5 ) + " -- MSG: " + "Check if terms code is not the default"
	


	


















 	INSERT #ewerror
	 SELECT 4000,
			 10430,
			 b.terms_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovchg b, apterms c (NOLOCK), apmaster_all d  (nolock)
 	 WHERE b.terms_code = c.terms_code
	 AND b.vendor_code = d.vendor_code
	 AND b.terms_code != d.terms_code
	 AND b.pay_to_code = ""
	 AND d.address_type = 0

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 539, 5 ) + " -- MSG: " + "Check if terms code is not the default"
	


	


















	INSERT #ewerror
	 SELECT 4000,
			 10430,
			 b.terms_code,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 0,
			 "",
			 0
	 FROM #apvovchg b, apterms c (nolock), apmaster_all d (nolock)
 	 WHERE b.terms_code = c.terms_code   
	 AND b.vendor_code = d.vendor_code
	 AND b.pay_to_code = d.pay_to_code
	 AND b.terms_code != d.terms_code
	 AND d.address_type = 1

END


IF (SELECT err_type FROM apedterr WHERE err_code = 10600) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 586, 5 ) + " -- MSG: " + "Check if recurring flag is valid"
	


      INSERT #ewerror
	  SELECT 4000,
			 10600,
			 "",
			 "",
			 recurring_flag,
			 0.0,
			 2,
			 trx_ctrl_num,
			 0,
			 "",
			 0
	  FROM #apvovchg b
  	  WHERE b.recurring_flag NOT IN (0,1)
END





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr2.cpp" + ", line " + STR( 610, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apvehdr2_sp] TO [public]
GO

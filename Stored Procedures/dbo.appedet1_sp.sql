SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[appedet1_sp] @error_level smallint, @called_from smallint = 0, @debug_level smallint = 0
WITH RECOMPILE
AS
	DECLARE @ib_flag		INTEGER

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 53, 5 ) + " -- ENTRY: "

SELECT 	@ib_flag = 0
SELECT 	@ib_flag = ib_flag
FROM 	glco




IF @ib_flag = 1 
BEGIN
	


	IF (SELECT err_type FROM apedterr WHERE err_code = 920) <= @error_level
  	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 72, 5 ) + " -- MSG: " + "Validate organization exists and is active in Detail"
		UPDATE 	#appyvpdt
		SET 	temp_flag = 0

		UPDATE 	#appyvpdt
		SET 	temp_flag = 1
 		FROM 	#appyvpdt a, Organization o
		WHERE 	a.org_id = o.organization_id
		AND  	o.active_flag = 1

		INSERT INTO #ewerror
		(       module_id,      	err_code,       info1,
			info2,          	infoint,        infofloat,
			flag1,          	trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000, 	920, 		org_id,
			org_id, 		0, 		0.0,
			0, 			trx_ctrl_num, 	sequence_id,
			"", 			0
		FROM 	#appyvpdt
		WHERE 	temp_flag = 0
  	END
	
END
ELSE
BEGIN
	


	IF (SELECT err_type FROM apedterr WHERE err_code = 930) <= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvehdr1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate all organizations are the same apinpchg/apinpcdt"

		


		UPDATE 	#appyvpdt
	        SET 	temp_flag = 0

		



		UPDATE 	#appyvpdt
	        SET 	temp_flag = 1
		FROM 	#appyvpdt a, #appyvpyt b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		ANd	a.trx_type = b.trx_type
		AND 	a.org_id = b.org_id

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	4000,	930, 			b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 		0.0,
			0, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#appyvpdt a, #appyvpyt b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.temp_flag = 0
	END
END

IF (SELECT err_type FROM apedterr WHERE err_code = 540) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 149, 5 ) + " -- MSG: " + "Check if voucher is on payment more than once"
	


	  INSERT #ewerror
	  SELECT 4000,
			 540,
			 b.apply_to_num,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
	  FROM #appyvpdt b
	  WHERE EXISTS (SELECT * FROM #appyvpdt c
	              WHERE c.trx_ctrl_num = b.trx_ctrl_num
				  AND c.sequence_id != b.sequence_id
				  AND c.apply_to_num = b.apply_to_num)
END


IF (SELECT err_type FROM apedterr WHERE err_code = 550) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 175, 5 ) + " -- MSG: " + "Check if sequence_id <= 0"
	


	  INSERT #ewerror
	  SELECT 4000,
			 550,
			 "",
			 "",
			 sequence_id,
			 0.0,
			 2,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #appyvpdt 
	  WHERE sequence_id <= 0
END


IF (SELECT err_type FROM apedterr WHERE err_code = 590) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 198, 5 ) + " -- MSG: " + "Check if one_check_flag is set on voucher"
	


	  INSERT #ewerror
	  SELECT 4000,
			 590,
			 b.apply_to_num,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
	  FROM #appyvpdt b, apvohdr c
	  WHERE b.apply_to_num = c.trx_ctrl_num
	  AND c.one_check_flag = 1
	  AND EXISTS (SELECT * FROM #appyvpdt d
	       WHERE d.trx_ctrl_num = b.trx_ctrl_num
		   AND d.sequence_id > 1) 
END


IF @called_from != 1	
   BEGIN
		IF (SELECT err_type FROM apedterr WHERE err_code = 560) <= @error_level
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 227, 5 ) + " -- MSG: " + "Check if apply_to_num exists in apvohdr"
			


			  INSERT #ewerror
			  SELECT 4000,
					 560,
					 apply_to_num,
					 "",
					 0,
					 0.0,
					 1,
					 trx_ctrl_num,
					 sequence_id,
					 "",
					 0
			  FROM #appyvpdt 
			  WHERE apply_to_num NOT IN (SELECT trx_ctrl_num FROM apvohdr)
		END
END






IF (SELECT err_type FROM apedterr WHERE err_code = 570) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 255, 5 ) + " -- MSG: " + "Check if voucher already paid"
	


	  INSERT #ewerror
	  SELECT 4000,
			 570,
			 b.apply_to_num,
			 "",
			 0,
			 0.0,
			 1,					   
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
	  FROM #appyvpdt b, apvohdr c
	  WHERE b.apply_to_num = c.trx_ctrl_num
	  AND @called_from != 4112
	  AND ((abs(c.amt_net) - abs(c.amt_paid_to_date)) <= (0.0) + 0.0000001)
 	  AND c.paid_flag = 1
END


IF (SELECT err_type FROM apedterr WHERE err_code = 580) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 281, 5 ) + " -- MSG: " + "Check if remit to codes match"
	


	  INSERT #ewerror
	  SELECT 4000,
			 580,
			 b.apply_to_num,
			 "",
			 0,
			 0.0,
			 1,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
	  FROM #appyvpdt b, apvohdr c, #appyvpyt d
	  WHERE b.apply_to_num = c.trx_ctrl_num
	  AND b.trx_ctrl_num = d.trx_ctrl_num
	  AND c.pay_to_code != d.pay_to_code
END



IF (SELECT err_type FROM apedterr WHERE err_code = 600) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 307, 5 ) + " -- MSG: " + "Check if amt_applied <= 0.0"
	


	  INSERT #ewerror
	  SELECT 4000,
			 600,
			 "",
			 "",
			 0,
			 amt_applied,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #appyvpdt, apco
	  WHERE ((abs(amt_applied)) <= (0.0) + 0.0000001)
	  AND ar_flag = 0
END



IF (SELECT err_type FROM apedterr WHERE err_code = 610) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 332, 5 ) + " -- MSG: " + "Check if amt_applied > voucher balance"
	


	  INSERT #ewerror
	  SELECT 4000,
			 610,
			 "",
			 "",
			 0,
			 b.amt_applied,
			 4,
			 b.trx_ctrl_num,
			 b.sequence_id,
			 "",
			 0
	  FROM #appyvpdt b, apvohdr c
	  WHERE b.apply_to_num = c.trx_ctrl_num
	  AND @called_from != 4112
	  AND ((abs(c.amt_net) - abs(c.amt_paid_to_date)) < (b.vo_amt_applied) - 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 620) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 358, 5 ) + " -- MSG: " + "Check if amt_discount < 0.0"
	


	  INSERT #ewerror
	  SELECT 4000,
			 620,
			 "",
			 "",
			 0,
			 amt_disc_taken,
			 4,
			 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #appyvpdt
	  WHERE ((amt_disc_taken) < (0.0) - 0.0000001)
	  
END



IF (SELECT err_type FROM apedterr WHERE err_code = 630) <= @error_level
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 383, 5 ) + " -- MSG: " + "Check if amt_discount > amt_applied"
	


	  INSERT #ewerror
	  SELECT 4000,
	  		 630,
			 "",
			 "",
			 0,
			 amt_disc_taken,
			 4,
	  		 trx_ctrl_num,
			 sequence_id,
			 "",
			 0
	  FROM #appyvpdt 
	  WHERE ((amt_disc_taken) > (amt_applied) + 0.0000001)
END



IF (SELECT err_type FROM apedterr WHERE err_code = 530) <= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 407, 5 ) + " -- MSG: " + "Check if details exist if not fully on-account"
		


		  INSERT #ewerror
		  SELECT 4000,
				 530,
				 "",
				 "",
				 0,
				 0.0,
				 0,
				 trx_ctrl_num,
				 0,
				 "",
				 0
		  FROM #appyvpyt 
		  WHERE (ABS((amt_payment)-(amt_on_acct)) > 0.0000001)
		  AND trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM #appyvpdt WHERE trx_type IN (4111,4011))
	END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appedet1.cpp" + ", line " + STR( 430, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[appedet1_sp] TO [public]
GO

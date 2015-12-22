SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[epinvhdr1_sp] @error_level smallint
AS
IF (SELECT err_type FROM epedterr WHERE err_code = 10010) <= @error_level
BEGIN
	
	INSERT #ewerror
	SELECT 4000,
			 10010,
			 "",
			 "",
			 company_id,
			 0.0,
			 2,
			 receipt_ctrl_num,
			 0,
			 "",
			 0
	 FROM #epinvhdr b
 	 WHERE b.company_id NOT IN (SELECT company_id FROM glco )
END


IF (SELECT err_type FROM epedterr WHERE err_code = 10020) <= @error_level
BEGIN
	
 	INSERT #ewerror
	SELECT 4000,
	 		 10020,
	 		 vendor_code,
			 "",
			 0,
			 0.0,
			 1,
			 receipt_ctrl_num,
			 0,
			 "",
			 0
	 FROM #epinvhdr b
 	 WHERE vendor_code NOT IN (SELECT vendor_code FROM apvend)
END


IF (SELECT err_type FROM epedterr WHERE err_code = 10021) <= @error_level
BEGIN
	
	INSERT #ewerror
	SELECT 4000,
	 		 10021,
	 		 b.vendor_code,
	 		 "",
			 0,
			 0.0,
			 1,
			 b.receipt_ctrl_num,
			 0,
			 "",
			 0
	 FROM #epinvhdr b, apvend c
 	 WHERE b.vendor_code = c.vendor_code
	 AND c.status_type != 5
END 


IF ( (SELECT multi_currency_flag FROM glco) = 0 )
  BEGIN
		IF (SELECT err_type FROM epedterr WHERE err_code = 10030) <= @error_level
		BEGIN
	
		 	INSERT #ewerror
			SELECT 4000,
			 		 10030,
			 		 nat_cur_code,
					 "",
					 0,
					 0.0,
					 1,
					 receipt_ctrl_num,
					 0,
					 "",
					 0
			 FROM #epinvhdr b
		 	 WHERE nat_cur_code NOT IN (SELECT home_currency FROM glco)
		END
  END
ELSE
  BEGIN
	IF (SELECT err_type FROM epedterr WHERE err_code = 10030) <= @error_level
	BEGIN
	
	 	INSERT #ewerror
		SELECT 4000,
		 		 10030,
		 		 nat_cur_code,
				 "",
				 0,
				 0.0,
				 1,
				 receipt_ctrl_num,
				 0,
				 "",
				 0
		 FROM #epinvhdr b
	 	 WHERE nat_cur_code NOT IN (SELECT currency_code FROM CVO_Control..mccurr)
	END

	IF (SELECT err_type FROM epedterr WHERE err_code = 10030) <= @error_level
	BEGIN
	
	 	INSERT #ewerror
		SELECT 4000,
		 		 10030,
		 		 b.nat_cur_code,
				 "",
				 0,
				 0.0,
				 1,
				 receipt_ctrl_num,
				 0,
				 "",
				 0
		 FROM #epinvhdr b, apvend c, appayto d
	 	 WHERE 
			b.vendor_code = c.vendor_code	and
			c.vendor_code = d.vendor_code	and
			c.pay_to_code = d.pay_to_code   and
			d.one_cur_vendor = 1		and
			b.nat_cur_code <> d.nat_cur_code	 
	END

	IF (SELECT err_type FROM epedterr WHERE err_code = 10030) <= @error_level
	BEGIN
	
	 	INSERT #ewerror
		SELECT 4000,
		 		 10030,
		 		 b.nat_cur_code,
				 "",
				 0,
				 0.0,
				 1,
				 receipt_ctrl_num,
				 0,
				 "",
				 0
		 FROM #epinvhdr b, apvend c
	 	 WHERE 
			b.vendor_code = c.vendor_code	and
			c.one_cur_vendor = 1		and
			c.pay_to_code = ""		and
			b.nat_cur_code <> c.nat_cur_code	 
	END
  END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[epinvhdr1_sp] TO [public]
GO

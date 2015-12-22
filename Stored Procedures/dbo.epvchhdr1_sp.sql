SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[epvchhdr1_sp] @error_level smallint
AS
DECLARE @one_time_vend_code varchar(12)

SELECT @one_time_vend_code = one_time_vend_code
FROM	apco


IF (SELECT err_type FROM epedterr WHERE err_code = 00010) <= @error_level
BEGIN
	
	INSERT #ewerror
	SELECT 4000,
	 		 00010,
	 		 b.vendor_code,
	 		 "",
			 0,
			 0.0,
			 1,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	 FROM #epvchhdr b, apvend c
 	 WHERE b.vendor_code = c.vendor_code
	 AND c.status_type != 5
END 

IF (SELECT err_type FROM epedterr WHERE err_code = 00020) <= @error_level
BEGIN
	


	      INSERT #ewerror
		  SELECT 4000,
				 00020,
				 b.vendor_invoice_no,
				 "",
				 0,
				 0.0,
				 1,
				 b.match_ctrl_num,
				 0,
				 "",
				 0
		  FROM #epvchhdr b, apinpchg c
	  	  WHERE c.trx_type = 4091
		  AND b.vendor_invoice_no = c.doc_ctrl_num
		  AND b.vendor_code = c.vendor_code
		  AND b.vendor_code != @one_time_vend_code
		  AND b.match_ctrl_num <> c.trx_ctrl_num

	


	      INSERT #ewerror
		  SELECT 4000,
				 00020,
				 "",
				 b.vendor_invoice_no,
				 0,
				 0.0,
				 1,
				 b.match_ctrl_num,
				 0,
				 "",
				 0
		  FROM #epvchhdr b, apvohdr c
	  	  WHERE b.vendor_invoice_no = c.doc_ctrl_num
		  AND b.vendor_code = c.vendor_code

END

IF (SELECT err_type FROM epedterr WHERE err_code = 00030) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00030,
			 vendor_invoice_no,
			 "",
			 0,
			 0.0,
			 1,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr 
  	  WHERE vendor_invoice_no = ''
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00040) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00040,
			 "",
			 "",
			 vendor_invoice_date,
			 0.0,
			 3,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr 
  	  WHERE vendor_invoice_date <= 0
END


IF (SELECT err_type FROM epedterr WHERE err_code = 00050) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00050,
			 "",
			 "",
			 due_date,
			 0.0,
			 3,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr
  	  WHERE due_date <= 0
END


IF (SELECT err_type FROM epedterr WHERE err_code = 00060) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00060,
			 "",
			 "",
			 b.due_date,
			 0.0,
			 3,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr b, apterms c
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_type = 1
	  AND b.due_date != b.vendor_invoice_date + c.days_due

	  SELECT b.match_ctrl_num,
			 b.due_date,
			 c.days_due,
			 c.min_days_due,
			 dtdate_doc = dateadd(dd,b.vendor_invoice_date,"1/1/1800"),
			 dtdate_due = dateadd(dd,b.due_date,"1/1/1800"),
			 dtdate_calc = dateadd(dd,b.vendor_invoice_date,"1/1/1800")
	  INTO #date_calc
	  FROM #epvchhdr b, apterms c
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_type = 2


	  DELETE #date_calc
	  WHERE dtdate_doc < "1/3/3552"
	  OR dtdate_due < "1/3/3552"


	  UPDATE #date_calc
	  SET dtdate_doc = dateadd(dd,-657072,dtdate_doc),
	      dtdate_due = dateadd(dd,-657072,dtdate_due),
	  dtdate_calc = dateadd(dd,-657072,dtdate_calc)      

      UPDATE #date_calc
	  SET dtdate_calc = dateadd(mm,1,dtdate_calc)
	  FROM #date_calc
	  WHERE datepart(dd,dtdate_doc) > days_due - min_days_due

	  UPDATE #date_calc
	  SET dtdate_calc = dateadd(dd,days_due,     dateadd(dd,-datepart(dd,dtdate_doc),dtdate_calc)  )
	  FROM #date_calc


	  UPDATE #date_calc
	  SET dtdate_calc = dateadd(dd,   -datepart(dd,dtdate_calc),  dtdate_calc)
	  FROM #date_calc
	  WHERE datepart(dd,dtdate_calc) < days_due
      


      INSERT #ewerror
	  SELECT 4000,
			 00060,
			 "",
			 "",
			 due_date,
			 0.0,
			 3,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #date_calc
	  WHERE dtdate_due != dtdate_calc

	  DROP TABLE #date_calc


      INSERT #ewerror
	  SELECT 4000,
			 00060,
			 "",
			 "",
			 b.due_date,
			 0.0,
			 3,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr b, apterms c
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_type = 3
	  AND b.due_date != c.date_due 

END

IF (SELECT err_type FROM epedterr WHERE err_code = 00070) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00070,
			 "",
			 "",
			 date_match,
			 0.0,
			 3,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr
  	  WHERE date_match <= 0
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00080) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00080,
			 "",
			 "",
			 discount_date,
			 0.0,
			 3,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr
  	  WHERE discount_date> due_date
END


IF (SELECT err_type FROM epedterr WHERE err_code = 00090) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00090,
			 "",
			 "",
			 b.discount_date,
			 0.0,
			 3,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr b, apterms c
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_type = 1
	  AND b.discount_date != b.vendor_invoice_date + c.discount_days


	  SELECT b.match_ctrl_num,
			 b.discount_date,
			 c.discount_days,
			 c.min_days_due,
			 dtdate_doc = dateadd(dd,b.vendor_invoice_date,"1/1/1800"),
			 dtdate_discount = dateadd(dd,b.discount_date,"1/1/1800"),
			 dtdate_calc = dateadd(dd,b.vendor_invoice_date,"1/1/1800")
	  INTO #date_calc2
	  FROM #epvchhdr b, apterms c
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_type = 2


	  DELETE #date_calc2
	  WHERE dtdate_doc < "1/3/3552"
	  OR dtdate_discount < "1/3/3552"


	  UPDATE #date_calc2
	  SET dtdate_doc = dateadd(dd,-657072,dtdate_doc),
	      dtdate_discount = dateadd(dd,-657072,dtdate_discount),
		  dtdate_calc = dateadd(dd,-657072,dtdate_calc)      


      UPDATE #date_calc2
	  SET dtdate_calc = dateadd(mm,1,dtdate_calc)
	  FROM #date_calc2
	  WHERE datepart(dd,dtdate_doc) > discount_days - min_days_due



	  UPDATE #date_calc2
	  SET dtdate_calc = dateadd(dd,discount_days,     dateadd(dd,-datepart(dd,dtdate_doc),dtdate_calc)  )
	  FROM #date_calc2


	  UPDATE #date_calc2
	  SET dtdate_calc = dateadd(dd,   -datepart(dd,dtdate_calc),  dtdate_calc)
	  FROM #date_calc2
	  WHERE datepart(dd,dtdate_calc) < discount_days
      


      INSERT #ewerror
	  SELECT 4000,
			 00090,
			 "",
			 "",
			 discount_date,
			 0.0,
			 3,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #date_calc2
	  WHERE dtdate_discount != dtdate_calc

	  DROP TABLE #date_calc2


      INSERT #ewerror
	  SELECT 4000,
			 00090,
			 "",
			 "",
			 b.discount_date,
			 0.0,
			 3,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr b, apterms c
  	  WHERE b.terms_code = c.terms_code
	  AND c.terms_type = 3
	  AND b.discount_date != c.date_discount 

END

IF (SELECT err_type FROM epedterr WHERE err_code = 00100) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00100,
			 "",
			 "",
			 discount_date,
			 0.0,
			 3,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr
  	  WHERE discount_date <= 0
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00110) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00110,
			 "",
			 "",
			 apply_date,
			 0.0,
			 3,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr
  	  WHERE apply_date <= 0
END


IF (SELECT err_type FROM epedterr WHERE err_code = 00120) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00120,
			 "",
			 "",
			 b.apply_date,
			 0.0,
			 3,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr b, apco c
  	  WHERE b.apply_date > c.period_end_date
END


IF (SELECT err_type FROM epedterr WHERE err_code = 00130) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00130,
			 "",
			 "",
			 b.apply_date,
			 0.0,
			 3,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr b, glprd c, apco d
  	  WHERE b.apply_date < c.period_start_date
	  AND c.period_end_date = d.period_end_date
END


IF (SELECT err_type FROM epedterr WHERE err_code = 00140) <= @error_level
BEGIN
	


      UPDATE #epvchhdr
      SET flag = 1
	  FROM #epvchhdr, glprd c
  	  WHERE #epvchhdr.apply_date BETWEEN c.period_start_date AND c.period_end_date


      INSERT #ewerror
	  SELECT 4000,
			 00140,
			 "",
			 "",
			 apply_date,
			 0.0,
			 3,
			 match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr 
  	  WHERE flag = 0


     UPDATE #epvchhdr
     SET flag = 0
END



IF (SELECT err_type FROM epedterr WHERE err_code = 00150) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00150,
			 "",
			 "",
			 b.apply_date,
			 0.0,
			 3,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr b, apco c
  	  WHERE abs(b.apply_date - b.date_match) > c.date_range_verify
END

IF (SELECT err_type FROM epedterr WHERE err_code = 00200) <= @error_level
BEGIN
	


      INSERT #ewerror
	  SELECT 4000,
			 00200,
			 b.org_id,
			 "",
			 0.0,
			 0.0,
			 3,
			 b.match_ctrl_num,
			 0,
			 "",
			 0
	  FROM #epvchhdr b
  	  WHERE b.org_id NOT IN ( SELECT org_id FROM dbo.IB_Organization_vw )
END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[epvchhdr1_sp] TO [public]
GO

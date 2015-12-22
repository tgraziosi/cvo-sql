SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[appoxhd1_sp] @process_ctrl_num varchar(16) AS DECLARE @first_gl_period int, 
 @last_gl_period int,  @intercompany_flag int,  @result int    SELECT @first_gl_period = MIN(period_start_date) 
 FROM glprd  SELECT @last_gl_period = MAX(period_end_date)  FROM glprd  INSERT mterror 
 SELECT @process_ctrl_num,  4000,  00140,  "",  "",  date_applied,  0.0,  1,  match_ctrl_num, 
 0,  "",  0  FROM #apinpchg  WHERE date_applied NOT BETWEEN @first_gl_period AND @last_gl_period 
   INSERT mterror  SELECT @process_ctrl_num,  4000,  00190,  user_trx_type_code, 
 "",  0,  0.0,  0,  match_ctrl_num,  1,  "",  0  FROM #apinpchg  WHERE user_trx_type_code = " " 
 OR user_trx_type_code NOT IN (SELECT user_trx_type_code  FROM apusrtyp)  INSERT mterror 
 SELECT @process_ctrl_num,  4000,  00200,  vendor_code,  "",  0,  0.0,  0,  match_ctrl_num, 
 1,  "",  0  FROM #apinpchg  WHERE vendor_code = " "  OR vendor_code NOT IN (SELECT vendor_code 
 FROM apvend)  INSERT mterror  SELECT @process_ctrl_num,  4000,  00210,  tax_code, 
 "",  0,  0.0,  0,  match_ctrl_num,  1,  "",  0  FROM #apinpchg  WHERE tax_code = " " 
 OR tax_code NOT IN (SELECT tax_code  FROM aptax)  INSERT mterror  SELECT @process_ctrl_num, 
 4000,  00220,  posting_code,  "",  0,  0.0,  0,  match_ctrl_num,  1,  "",  0  FROM #apinpchg 
 WHERE posting_code = " "  OR posting_code NOT IN (SELECT posting_code  FROM apaccts) 
 INSERT mterror  SELECT @process_ctrl_num,  4000,  00230,  branch_code,  "",  0, 
 0.0,  0,  match_ctrl_num,  1,  "",  0  FROM #apinpchg  WHERE branch_code = " " 
 OR branch_code NOT IN (SELECT branch_code  FROM apbranch)  INSERT mterror  SELECT @process_ctrl_num, 
 4000,  00240,  class_code,  "",  0,  0.0,  0,  match_ctrl_num,  1,  "",  0  FROM #apinpchg 
 WHERE class_code = " "  OR class_code NOT IN (SELECT class_code  FROM apclass)  INSERT mterror 
 SELECT @process_ctrl_num,  4000,  00250,  payment_code,  "",  0,  0.0,  0,  match_ctrl_num, 
 1,  "",  0  FROM #apinpchg  WHERE payment_code = " "  OR payment_code NOT IN (SELECT payment_code 
 FROM appymeth)  INSERT mterror  SELECT @process_ctrl_num,  4000,  00260,  "",  "", 
 date_doc,  0.0,  0,  match_ctrl_num,  1,  "",  0  FROM #apinpchg  WHERE date_doc < 0 
 INSERT mterror  SELECT @process_ctrl_num,  4000,  00270,  "",  "",  date_received, 
 0.0,  0,  match_ctrl_num,  1,  "",  0  FROM #apinpchg  WHERE date_received < 0 
 INSERT mterror  SELECT @process_ctrl_num,  4000,  00280,  "",  "",  date_required, 
 0.0,  0,  match_ctrl_num,  1,  "",  0  FROM #apinpchg  WHERE date_required < 0 
 SELECT @intercompany_flag = intercompany_flag  FROM apco  INSERT mterror  SELECT @process_ctrl_num, 
 4000,  00290,  match_ctrl_num,  "",  0,  0.0,  0,  match_ctrl_num,  1,  "",  0  FROM #apinpchg 
 WHERE (intercompany_flag = 1 AND @intercompany_flag = 0)  SELECT @result = COUNT(*) 
 FROM mterror  WHERE process_ctrl_num = @process_ctrl_num RETURN @result 
GO
GRANT EXECUTE ON  [dbo].[appoxhd1_sp] TO [public]
GO

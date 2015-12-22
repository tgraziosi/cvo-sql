SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apchknmb_sp] @expense_dist smallint,  @cash_acct_code varchar(32), 
 @to_white_paper smallint,  @start_check int,  @last_check int OUTPUT,  @check_num_mask varchar(16), 
 @check_start_col smallint,  @check_length smallint,  @voids_exist smallint OUTPUT, 
 @lines_per_check smallint,  @debug_level smallint = 0 AS  DECLARE  @number_of_checks int, 
 @trx_ctrl_num varchar(16),  @doc_num varchar(16),  @check_num int,  @i int,  @j int, 
 @company_code varchar(8),  @OrderId int IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apchknmb.sp" + ", line " + STR( 59, 5 ) + " -- ENTRY: " 
SELECT @company_code = company_code FROM glco CREATE TABLE #check_num_temp (  trx_ctrl_num varchar(16), 
 numb smallint) IF (@@error != 0)  RETURN -1 INSERT #check_num_temp (trx_ctrl_num, 
 numb) SELECT payment_num,  SUM(lines) FROM #apchkstb GROUP BY payment_num UPDATE #check_num_temp 
SET numb = CEILING(convert(float,numb)/convert(float,@lines_per_check)) IF (@@error != 0) 
 RETURN -1 IF (@to_white_paper = 1)  SELECT @number_of_checks = count(*) FROM #check_num_temp 
ELSE  SELECT @number_of_checks = SUM(numb) FROM #check_num_temp IF (@@error != 0) 
 RETURN -1 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apchknmb.sp" + ", line " + STR( 92, 5 ) + " -- MSG: " + "number of checks is " + str(@number_of_checks) 
SELECT @last_check = @start_check + @number_of_checks - 1    IF (datalength(convert(varchar(16),@last_check)) > @check_length) 
 RETURN -8    SELECT @check_num = @start_check SELECT @OrderId = 0 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apchknmb.sp" + ", line " + STR( 113, 5 ) + " -- MSG: " + "Assign check numbers" 
WHILE (1=1) BEGIN  SET ROWCOUNT 1  SELECT @OrderId = @OrderId + 1  SELECT @trx_ctrl_num = trx_ctrl_num FROM #check_header 
 WHERE mark_flag = 0 and OrderId = @OrderId  IF @@rowcount < 1 BREAK  SET ROWCOUNT 0 
 SELECT @doc_num = SUBSTRING(@check_num_mask, 1,  @check_start_col -1) + RIGHT("0000000000000000" + 
 RTRIM(LTRIM(STR(@check_num, 16, 0))),  @check_length)  UPDATE #check_header  SET doc_ctrl_num = @doc_num, 
 mark_flag = 1  WHERE trx_ctrl_num = @trx_ctrl_num  IF (@@error != 0)  RETURN -1 
 IF (@to_white_paper = 1)  SELECT @check_num = @check_num + 1  ELSE  BEGIN  SELECT @j = 2 
 SELECT @i = numb  FROM #check_num_temp  WHERE trx_ctrl_num = @trx_ctrl_num  IF (@i > 1) SELECT @voids_exist = 1 
 WHILE (@j <= @i)  BEGIN  SELECT @j = @j + 1  SELECT @check_num = @check_num + 1 
 INSERT #aptrx_work (  trx_ctrl_num,  doc_ctrl_num,  batch_code,  date_applied, 
 date_doc,  vendor_code,  pay_to_code,  cash_acct_code,  payment_code,  void_flag, 
 user_id,  doc_desc,  company_code,  nat_cur_code  )  SELECT  @trx_ctrl_num,  SUBSTRING(@check_num_mask, 1, 
 @check_start_col -1) + RIGHT("0000000000000000" +  RTRIM(LTRIM(STR(@check_num, 16, 0))), 
 @check_length),  #check_header.batch_code,  #check_header.date_applied,  #check_header.date_doc, 
 #check_header.vendor_code,  #check_header.pay_to_code,  @cash_acct_code,  #check_header.payment_code, 
 3,  #check_header.user_id,  "Check Stub Overflow",  @company_code,  nat_cur_code 
 FROM #check_header  WHERE #check_header.trx_ctrl_num = @trx_ctrl_num  IF (@@error != 0) 
 RETURN -1  END  SELECT @check_num = @check_num + 1  IF (@@error != 0)  RETURN -1 
 END END SET ROWCOUNT 0 UPDATE #apchkstb SET check_num = doc_ctrl_num FROM #apchkstb, #check_header 
WHERE #apchkstb.payment_num = #check_header.trx_ctrl_num IF (@@error != 0)  RETURN -1 
IF (@expense_dist = 1)  BEGIN  UPDATE #apexpdst  SET check_num = doc_ctrl_num  FROM #apexpdst, #check_header 
 WHERE #apexpdst.payment_num = #check_header.trx_ctrl_num  IF (@@error != 0)  RETURN -1 
 END DROP TABLE #check_num_temp IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apchknmb.sp" + ", line " + STR( 237, 5 ) + " -- EXIT: " 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[apchknmb_sp] TO [public]
GO

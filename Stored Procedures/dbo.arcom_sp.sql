SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[arcom_sp] @system_date int,  @from_date int,  @thru_date int,  @from_salesperson varchar(8), 
 @thru_salesperson varchar(8),  @user_id smallint AS DECLARE @last_slp_code varchar(8), 
 @salesperson_code varchar(8),  @commission_code varchar(8),  @doc_ctrl_num varchar(16), 
 @trx_type smallint,  @amt_invoice float,  @date_applied int,  @date_paid int,  @paid_flag smallint, 
 @amt_cost float,  @base_type smallint,  @table_type smallint,  @calc_type smallint, 
 @when_paid smallint,  @date_used int,  @cust_code varchar(8),  @customer_name varchar(40), 
 @line_desc varchar(60),  @doc_date int,  @status int,  @min_doc_ctrl_num varchar(16), 
 @last_doc_ctrl_num varchar(16),  @curr_precision smallint CREATE TABLE #artrxtmp 
(
 doc_ctrl_num varchar(16),  trx_type smallint,  salesperson_code varchar(8),  commission_code varchar(8), 
 date_applied int,  paid_flag smallint,  date_paid int,  commission_flag smallint, 
 void_flag smallint 
)
BEGIN  SELECT @salesperson_code = SPACE(8)      DELETE arsalcom  DELETE arscomdt 
     UPDATE artrx  SET commission_flag = 0  WHERE commission_flag = 2  UPDATE artrxcom 
 SET commission_flag = 0  WHERE commission_flag = 2  UPDATE arcomadj  SET posted_flag = 0 
 WHERE posted_flag = 2       SELECT @doc_ctrl_num = "",  @min_doc_ctrl_num = ' ', 
 @trx_type = 0   INSERT #artrxtmp(doc_ctrl_num,  trx_type,  salesperson_code,  commission_code, 
 date_applied,  paid_flag,  date_paid,  commission_flag,  void_flag)  SELECT doc_ctrl_num, 
 trx_type,  a.salesperson_code,  commission_code,  date_applied,  paid_flag,  date_paid, 
 commission_flag,  void_flag  FROM artrx a, arsalesp c  WHERE a.salesperson_code = c.salesperson_code 
 AND a.trx_type IN (2031, 2021, 2032 )  AND ( LTRIM(c.commission_code) IS NOT NULL AND LTRIM(c.commission_code) != " " ) 
 AND (( a.date_applied BETWEEN @from_date AND @thru_date )  OR ( paid_flag * date_paid BETWEEN @from_date AND @thru_date )) 
 AND a.commission_flag = 0  AND a.void_flag = 0   WHILE ( 1 = 1 )  BEGIN  SELECT @last_doc_ctrl_num = @min_doc_ctrl_num 
 SELECT @min_doc_ctrl_num = ' '       SELECT @min_doc_ctrl_num = MIN(doc_ctrl_num) 
 FROM #artrxtmp, arsalesp  WHERE doc_ctrl_num > @last_doc_ctrl_num  AND trx_type IN (2031, 2021, 2032 ) 
  AND ( LTRIM(arsalesp.commission_code) IS NOT NULL AND LTRIM(arsalesp.commission_code) != " " ) 
 AND #artrxtmp.salesperson_code = arsalesp.salesperson_code  AND (( date_applied BETWEEN @from_date AND @thru_date ) 
 OR ( paid_flag * date_paid BETWEEN @from_date AND @thru_date ))  AND commission_flag = 0 
 AND void_flag = 0       SELECT @curr_precision = curr_precision  FROM glco, glcurr_vw 
 WHERE glco.home_currency = glcurr_vw.currency_code       SELECT @doc_ctrl_num = doc_ctrl_num, 
 @trx_type = trx_type,  @date_applied = date_applied,  @date_paid = date_paid * paid_flag, 
 @paid_flag = paid_flag,  @amt_cost = amt_cost,  @amt_invoice = ROUND((amt_gross - amt_discount) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @curr_precision), 
 @doc_date = date_doc,  @salesperson_code = arsalesp.salesperson_code,  @cust_code = arcust.customer_code, 
 @customer_name = arcust.customer_name,  @commission_code = arsalesp.commission_code, 
 @base_type = arcomm.base_type,  @table_type = arcomm.table_amt_type,  @calc_type = arcomm.calc_type, 
 @when_paid = arcomm.when_paid_type  FROM artrx, arcust, arsalesp, arcomm  WHERE doc_ctrl_num = @min_doc_ctrl_num 
 AND trx_type IN (2031, 2021, 2032 )  AND arcust.customer_code = artrx.customer_code 
 AND artrx.salesperson_code = arsalesp.salesperson_code  AND arsalesp.commission_code = arcomm.commission_code 
 IF @@ROWCOUNT = 0  BREAK                 IF( @trx_type = 2032 )  BEGIN  IF( @date_applied <= @thru_date AND @date_applied >= @from_date ) 
 SELECT @date_used = @date_applied  END  ELSE  BEGIN       IF @when_paid = 0  BEGIN 
 IF( @date_applied <= @thru_date AND @date_applied >= @from_date )  SELECT @date_used = @date_applied 
 ELSE  CONTINUE  END  ELSE  BEGIN  IF( @date_paid <= @thru_date AND @date_paid >= @from_date ) 
 SELECT @date_used = @date_paid  ELSE  CONTINUE  END  END          IF EXISTS(SELECT salesperson_code 
 FROM artrxcom  WHERE trx_type = @trx_type  AND doc_ctrl_num = @doc_ctrl_num  AND salesperson_code = @salesperson_code 
 AND (exclusive_flag = 1 OR split_flag = 1 ))  BEGIN       EXEC @status = arextcom_sp @salesperson_code, 
 @doc_ctrl_num,  @trx_type,  @calc_type,  @table_type,  @base_type,  @commission_code, 
 @customer_name,  @amt_invoice,  @amt_cost,  @date_used,  @system_date,  @doc_date, 
 @user_id,  @from_date,  @thru_date,  @cust_code  END  ELSE   BEGIN       IF ( @table_type = 0 ) 
 BEGIN  EXEC @status = arcomlin_sp @trx_type,  @doc_ctrl_num,  @salesperson_code, 
 @date_used,  @system_date,  100,  @doc_date,  @user_id,  @from_date,  @thru_date, 
 @cust_code,  @table_type  END      ELSE IF ( @table_type = 1 OR @table_type = 2 ) 
 BEGIN  EXEC @status = arcominv_sp @trx_type,  @doc_ctrl_num,  @salesperson_code, 
 @date_used,  @base_type,  @calc_type,  @commission_code,  @amt_invoice,  @amt_cost, 
 @system_date,  100,  @customer_name,  @doc_date,  @user_id,  @from_date,  @thru_date, 
 @cust_code,  @table_type  END      EXEC @status = arextcom_sp @salesperson_code, 
 @doc_ctrl_num,  @trx_type,  @calc_type,  @table_type,  @base_type,  @commission_code, 
 @customer_name,  @amt_invoice,  @amt_cost,  @date_used,  @system_date,  @doc_date, 
 @user_id,  @from_date,  @thru_date,  @cust_code  END       UPDATE artrx  SET commission_flag = 2 
 WHERE doc_ctrl_num = @doc_ctrl_num  AND trx_type = @trx_type  END       EXEC @status = arcomtol_sp @user_id 
 RETURN DROP TABLE #artrxtmp END 

 /**/
GO
GRANT EXECUTE ON  [dbo].[arcom_sp] TO [public]
GO

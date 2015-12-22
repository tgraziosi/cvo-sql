SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                



































CREATE PROC [dbo].[glcitrxd_sp] (
  @journal_ctrl_num varchar(16),
  @description    varchar(30),
  @seq_id     int,
  @company_code   varchar(8),
  @company_id   smallint,
  @account_code   varchar(32),
  @nat_balance    float,
  @p_home_currency  varchar(8),
  @s_currency   varchar(8),
  @rate_home    float,
  @trx_type   smallint,
  @applied_date   int,
  @detail_flag    smallint,
  @sub_journal_num  varchar(16),
  @p_oper_currency  varchar(8),
  @rate_oper              float,
  @rate_type_home         varchar(8),
  @rate_type_oper         varchar(8),
  @child_seq_id int = 0,
  @org_id varchar(30) = '' 
 ) AS

DECLARE @summary_not_there  tinyint,  
  @seg1_code    varchar(32),
  @seg2_code    varchar(32),
  @seg3_code    varchar(32),
  @seg4_code    varchar(32),
  @rec_insert   smallint,
  @new_balance_home float,
  @new_balance_oper float,
  @new_nat_balance  float,
  @ave_rate_home    float,
  @ave_rate_oper    float,
  @rounding_factor_home float,
  @rounding_factor_oper float,
  @precision_home   smallint,
  @precision_oper   smallint,
  @balance_home   float,
  @balance_oper   float






SET NOCOUNT ON




SELECT  @rec_insert = 0, @new_balance_home = 0, @new_balance_oper = 0, 
      @new_nat_balance = 0, @ave_rate_home = 0, @ave_rate_oper = 0




SELECT  @rounding_factor_home = rounding_factor,
  @precision_home = curr_precision
FROM  glcurr_vw
WHERE currency_code = @p_home_currency

SELECT  @rounding_factor_oper = rounding_factor,
  @precision_oper = curr_precision
FROM  glcurr_vw
WHERE currency_code = @p_oper_currency




EXEC CVO_Control..mclcd_sp @new_balance_home, @precision_home, 
  @rounding_factor_home, @new_balance_home OUTPUT, 0




EXEC CVO_Control..mclcd_sp @new_balance_oper, @precision_oper, 
  @rounding_factor_oper, @new_balance_oper OUTPUT, 0




SELECT @balance_home = ROUND((@nat_balance * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )), @precision_home)










SELECT @balance_oper = ROUND((@nat_balance * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )), @precision_oper)










SELECT  @seg1_code = seg1_code,
  @seg2_code = seg2_code,
  @seg3_code = seg3_code,
  @seg4_code = seg4_code
FROM  glchart
WHERE account_code = @account_code




IF @detail_flag = 0 AND NOT EXISTS ( SELECT *
             FROM   gltrxdet 
             WHERE  journal_ctrl_num = @journal_ctrl_num 
             AND    account_code = @account_code 
             AND    seq_ref_id = 0 )
  SELECT  @summary_not_there = 1
ELSE  
  SELECT  @summary_not_there = 0







IF  ( @detail_flag = 0 AND @summary_not_there = 1 ) OR @detail_flag = 1
BEGIN
  INSERT  gltrxdet (
    journal_ctrl_num, description,  sequence_id,
    rec_company_code, company_id, account_code,
    nat_balance,    nat_cur_code, rate,
    trx_type,   balance,  posted_flag,
    date_posted,    offset_flag,  document_1,
    document_2,   reference_code, seg1_code,
    seg2_code,    seg3_code,  seg4_code,
    seq_ref_id,     balance_oper,   rate_oper, 
    rate_type_home,   rate_type_oper, org_id ) 
  VALUES (
    @journal_ctrl_num,  @description, @seq_id,
    @company_code,    @company_id,  @account_code,
    @nat_balance,   @s_currency,  @rate_home,
    @trx_type,    @balance_home,  0,
    0,      0,    '',
    @sub_journal_num,   '',   @seg1_code, 
    @seg2_code,   @seg3_code, @seg4_code,
    @detail_flag,   @balance_oper,  @rate_oper,
    @rate_type_home,  @rate_type_oper, @org_id ) 

  


  SELECT @rec_insert = 1
END
ELSE  
BEGIN
  


  SELECT  @new_balance_home = balance +  @balance_home,
    @new_balance_oper = balance_oper +  @balance_oper,
    @new_nat_balance = nat_balance + @nat_balance
  FROM  gltrxdet
  WHERE journal_ctrl_num = @journal_ctrl_num
  AND account_code = @account_code
  AND seq_ref_id = 0

  


  IF  @new_nat_balance = 0.0
    SELECT  @ave_rate_home = @rate_home,
      @ave_rate_oper = @rate_oper
  ELSE    
    SELECT  @ave_rate_home = @new_balance_home / @new_nat_balance,
      @ave_rate_oper = @new_balance_oper / @new_nat_balance

  UPDATE  gltrxdet
  SET balance = @new_balance_home,
    balance_oper = @new_balance_oper,
    nat_balance = @new_nat_balance,
    rate = @ave_rate_home,
    rate_oper = @ave_rate_oper
  WHERE journal_ctrl_num = @journal_ctrl_num
  AND account_code = @account_code
  AND seq_ref_id = 0
END
    
SELECT @rec_insert
RETURN

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glcitrxd_sp] TO [public]
GO

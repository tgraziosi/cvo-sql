SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[arstlldoa_sp] @settlement_ctrl_num  varchar(16),
                              @customer_code        varchar(8),
                              @doc_ctrl_num         varchar(16),
                              @date_entered         int,
                              @date_applied         int,
                              @user_id              smallint
AS
DECLARE @trx_ctrl_num varchar(16),
        @bal_fwd_flag smallint,
        @num int

SELECT  @bal_fwd_flag = bal_fwd_flag
FROM    arcust  
WHERE   customer_code = @customer_code




EXEC ARGetNextControl_SP  2010,
                          @trx_ctrl_num OUTPUT,
                          @num OUTPUT

SELECT
  @settlement_ctrl_num, @trx_ctrl_num,      "",
  "",                   2111,               0,                  "",
  "",                   date_doc,
  @customer_code,       payment_code,       case when payment_type = 3 then 4 else 2 end,       amt_on_acct,
  amt_on_acct,          prompt1_inp,        prompt2_inp,        prompt3_inp,
  prompt4_inp,          "",                 @bal_fwd_flag,      0,
  0,                    0,                  0,                  0,
  @user_id,             0.0,                0,                  0,
  cash_acct_code,       rate_type_home,     rate_type_oper,
  rate_home,            rate_oper,          0.0,                "", nat_cur_code, date_applied, org_id    
FROM  artrx
WHERE doc_ctrl_num = @doc_ctrl_num
AND   customer_code = @customer_code
AND   amt_on_acct > 0
AND   void_flag = 0
AND   non_ar_flag = 0
AND   trx_type = 2111

RETURN
GO
GRANT EXECUTE ON  [dbo].[arstlldoa_sp] TO [public]
GO

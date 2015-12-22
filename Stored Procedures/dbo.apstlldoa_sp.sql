SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apstlldoa_sp] @settlement_ctrl_num  varchar(16),
                              @vendor_code        varchar(12),
                              @doc_ctrl_num         varchar(16),
                              @date_entered         int,
                              @date_applied         int,
                              @user_id              smallint
AS
DECLARE @trx_ctrl_num varchar(16),
        @num int





EXEC apnewnum_sp 4111, "", @trx_ctrl_num OUTPUT

SELECT
  @settlement_ctrl_num, @trx_ctrl_num,      "",
  "",                   4111,               0,                  "",
  "",                   date_doc,
  @vendor_code,        payment_code,       case when payment_type = 3 then 3 else 2 end,       amt_on_acct,
  amt_on_acct,          "",                 "",         	"",
  "",		        "",                 0,      		2,
  0,                    0,                  0,                  0,
  @user_id,             0.0,                0,                  0,
  cash_acct_code,       rate_type_home,     rate_type_oper,
  rate_home,            rate_oper,          0.0,                "",  currency_code,
  print_batch_num, 	approval_code,      pay_to_code, 	date_applied, org_id
FROM  appyhdr
WHERE doc_ctrl_num = @doc_ctrl_num
AND   vendor_code = @vendor_code
AND   amt_on_acct > 0
AND   void_flag = 0
AND   ( payment_type = 1 OR payment_type = 3 )  

RETURN
GO
GRANT EXECUTE ON  [dbo].[apstlldoa_sp] TO [public]
GO

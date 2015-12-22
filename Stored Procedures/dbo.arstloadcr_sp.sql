SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[arstloadcr_sp]    @customer_code  varchar(8),
                        @load_option  smallint,
                        @all_doc_date smallint,
                        @doc_date_from  int,
                        @doc_date_to    int,
			@org_id		varchar(30),
                        @cur_code_from  varchar(8),
                        @cur_code_to  varchar(8),
                        @include_na smallint

AS
DECLARE    @num  int,
                 @cnt  int














CREATE TABLE #avail_onacct_load
( 
  sec_id              numeric identity, 
  customer_code  varchar(8), 
  doc_ctrl_num    varchar(16), 
  payment_type    smallint,
  amt_on_acct     float,
  in_use              smallint 
)

CREATE TABLE #avail_doc
( 
  customer_code  varchar(8), 
  doc_ctrl_num    varchar(16), 
  payment_type    smallint,
  amt_on_acct     float,
  in_use              smallint 
)








CREATE TABLE #arvpay
(
   customer_code    varchar(8),
   customer_name            varchar(40),
   bal_fwd_flag             smallint,
   seq_id                   smallint
)

EXEC arvalpay_sp @customer_code




INSERT #avail_doc
(
  customer_code,  doc_ctrl_num, payment_type, amt_on_acct, in_use
)
SELECT
  t.customer_code, doc_ctrl_num, payment_type ,amt_on_acct, 0
FROM artrx t, #arvpay p
WHERE t.customer_code = p.customer_code
AND trx_type = 2111
AND payment_type in (1,3)
AND void_flag = 0
AND amt_on_acct > 0
AND nat_cur_code = @cur_code_from
AND org_id = @org_id




DELETE #avail_doc
FROM #avail_doc a, arinppyt p
WHERE p.trx_type = 2111
AND p.payment_type in ( 2, 4 )
AND p.non_ar_flag = 0
AND   a.doc_ctrl_num = p.doc_ctrl_num





INSERT #avail_onacct_load
(
  customer_code,  doc_ctrl_num, payment_type, amt_on_acct, in_use
)
SELECT
  t.customer_code, d.doc_ctrl_num, d.payment_type, d.amt_on_acct, 0
FROM artrx t , #avail_doc d
WHERE 
    t.customer_code = d.customer_code
AND t.doc_ctrl_num = d.doc_ctrl_num
AND t.trx_type = 2111
AND ( ( t.payment_type = case when @load_option = 0 then 1 else @load_option end ) 
  OR (  t.payment_type = case when @load_option = 0 then 3 else @load_option end ) )
AND t.void_flag = 0
AND t.amt_on_acct > 0
AND ( (t.date_doc BETWEEN  @doc_date_from AND @doc_date_to ) OR ( @all_doc_date = 1 ) )
AND ( (t.nat_cur_code BETWEEN  @cur_code_from AND @cur_code_to ) )
AND t.org_id = @org_id
ORDER BY t.doc_ctrl_num




DELETE #avail_onacct_ld_4750

INSERT #avail_onacct_ld_4750
(
   sec_id,customer_code,  doc_ctrl_num, payment_type, amt_on_acct, in_use
)
SELECT  sec_id, customer_code,  doc_ctrl_num,payment_type, amt_on_acct, in_use
FROM #avail_onacct_load  ORDER BY doc_ctrl_num


DROP TABLE #avail_onacct_load
DROP TABLE #arvpay
DROP TABLE #avail_doc

SELECT @cnt = MAX(sec_id) from #avail_onacct_ld_4750

SELECT @cnt
RETURN 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arstloadcr_sp] TO [public]
GO

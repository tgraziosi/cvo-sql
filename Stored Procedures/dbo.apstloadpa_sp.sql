SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[apstloadpa_sp]    @vendor_code  varchar(12),
                        @load_option  smallint,
                        @all_doc_date smallint,
                        @doc_date_from  int,
                        @doc_date_to    int,
                        @cur_code_from  varchar(8),
                        @cur_code_to  varchar(8),
			@org_id	      varchar(30)
                 

AS
DECLARE    @num  int,
           @cnt  int














CREATE TABLE #avail_onacct_load
( 
  sec_id          numeric identity, 
  vendor_code     varchar(12), 
  doc_ctrl_num    varchar(16), 
  payment_type    smallint,
  amt_on_acct     float,
  in_use          smallint,
  org_id	  varchar(30)
)

CREATE TABLE #avail_doc
( 
  vendor_code     varchar(12), 
  doc_ctrl_num    varchar(16), 
  payment_type    smallint,
  amt_on_acct     float,
  in_use          smallint,
  org_id   	  varchar(30)
)





INSERT #avail_doc
(
  vendor_code,  doc_ctrl_num, payment_type, amt_on_acct, in_use, org_id
)
SELECT
  vendor_code, doc_ctrl_num, case when payment_type = 1 then 1 else 3 end,amt_on_acct, 0, org_id
FROM appyhdr  
WHERE vendor_code = @vendor_code
AND payment_type in (1,3)
AND void_flag = 0
AND amt_on_acct > 0
AND currency_code = @cur_code_from
AND org_id = @org_id




DELETE #avail_doc
FROM #avail_doc a, apinppyt p
WHERE p.trx_type = 4111
AND  p.payment_type in ( 2, 4 )
AND   a.doc_ctrl_num = p.doc_ctrl_num


DELETE #avail_doc
FROM #avail_doc a, apinppyt p
WHERE p.trx_type = 4111
AND  p.payment_type in ( 1,3  )
AND  a.doc_ctrl_num = p.doc_ctrl_num







INSERT #avail_onacct_load
(
  vendor_code,  doc_ctrl_num, payment_type, amt_on_acct, in_use, org_id
)
SELECT
  t.vendor_code, d.doc_ctrl_num, d.payment_type, d.amt_on_acct, 0,t. org_id
FROM    appyhdr t , #avail_doc d
WHERE t.vendor_code = @vendor_code
AND t.vendor_code = d.vendor_code
AND t.doc_ctrl_num = d.doc_ctrl_num
AND ( ( t.payment_type = case when @load_option = 0 then 1 else @load_option end ) 
  OR (  t.payment_type = case when @load_option = 0 then 3 else @load_option end ) )
AND t.void_flag = 0
AND t.amt_on_acct > 0
AND ( t.date_doc in ( @doc_date_from, @doc_date_to ) OR ( @all_doc_date = 1 ) )
AND ( t.currency_code in ( @cur_code_from, @cur_code_to ) )
AND  t.org_id = @org_id
ORDER BY t.doc_ctrl_num




DELETE #avail_onacct_ld_3450

INSERT #avail_onacct_ld_3450
(
   sec_id,vendor_code,  doc_ctrl_num, payment_type, amt_on_acct, in_use,  org_id
)
SELECT  sec_id, vendor_code,  doc_ctrl_num,payment_type, amt_on_acct, in_use, org_id
FROM #avail_onacct_load  ORDER BY doc_ctrl_num

DROP TABLE #avail_onacct_load
DROP TABLE #avail_doc

SELECT @cnt = MAX(sec_id) from #avail_onacct_ld_3450

SELECT @cnt
RETURN 
GO
GRANT EXECUTE ON  [dbo].[apstloadpa_sp] TO [public]
GO

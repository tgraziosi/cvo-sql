SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create View [dbo].[cvo_ARGLacctCompare_vw] as 

select t2.order_no, t2.order_ext, t1.trx_ctrl_num, t1.doc_ctrl_num, 
t1.item_code, t1.line_desc, t1.qty_shipped, t1.qty_returned, t1.unit_price, 
t1.extended_price, t1.calc_tax,
t4.acct_code, t4.description, t1.gl_rev_acct,
date_entered,
date_posted,
date_applied, 
--convert(varchar,dateadd(d,t1.date_entered-711858,'1/1/1950'),101) AS Date_Entered,
--convert(varchar,dateadd(d,t1.date_posted-711858,'1/1/1950'),101) AS Date_Posted, 
--convert(varchar,dateadd(d,t1.date_applied-711858,'1/1/1950'),101) AS Date_Applied,
t1.reference_code, t4.sales_acct_code, t1.tax_code
 from artrxcdt t1
full outer join orders_invoice t2 on t1.doc_ctrl_num=t2.doc_ctrl_num
join inv_master t3 on t1.item_code=t3.part_no
join in_account t4 on t3.account=t4.acct_code
--Where date_applied between @JDateFrom and @JDateTo
--order by date_applied

GO
GRANT SELECT ON  [dbo].[cvo_ARGLacctCompare_vw] TO [public]
GO

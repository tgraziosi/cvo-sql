SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[CVO_IR_AR_GL_Recon_sp] @datefrom datetime, @dateto datetime
as 
BEGIN

-- Author: Tine Graziosi - 07/26/2013
-- Usage: exec cvo_ir_ar_gl_recon_sp '07/01/2013', '07/26/2013'
-- 02/25/2014 - tag - add 4530 for debit promos - consider as discount - 4500
-- declare @datefrom datetime, @dateto datetime

declare @jdatefrom int, @jdateto int

--select @datefrom = dateadd(mm,datediff(mm,0,dateadd(dd,datediff(dd,1,getdate()), 0)), 0)
--select @dateto = dateadd(dd,datediff(dd,1,getdate()), 0)

select @jdatefrom = dbo.adm_get_pltdate_f(@datefrom)
select @jdateto = dbo.adm_get_pltdate_f(@dateto)

-- select  dateadd(mm,datediff(mm,0,getdate()), 0), dateadd(dd,datediff(dd,0,getdate()), 0)

-- select @datefrom, @dateto

select 'AR        ' Source_Ledger , 'ALL     ' POSTED, round(sum(extended_price),2) Ext_sales from cvo_ar_tx_detail_vw
where date_applied between @jdatefrom and @jdateto
and naturalaccount in ('4000','4500','4530','4600','4999')

union all
select 'AR', CASE WHEN posted = 'POSTED' THEN 'YES' ELSE 'NO' END, 
round(sum(extended_price),2) Ext_sales from cvo_ar_tx_detail_vw
where date_applied between @jdatefrom and @jdateto
and naturalaccount in ('4000','4500','4530','4600','4999')
group by posted

UNION ALL
select 'GL', 'YES',
round(sum(isnull(balance,0)),2) gl_ext_sales From cvo_gl_tx_detail_vw 
where date_applied between @jdatefrom and @jdateto
and naturalaccount in ('4000','4500','4530','4600','4999')
AND DATE_POSTED <> 0

UNION ALL
select 'GL', 'NO',
round(sum(isnull(balance,0)),2) gl_ext_sales From cvo_gl_tx_detail_vw 
where date_applied between @jdatefrom and @jdateto
and naturalaccount in ('4000','4500','4530','4600','4999')
AND DATE_POSTED = 0
having sum(isnull(balance,0)) <> 0

UNION ALL
select 'IR', POSTED_FLAG, round(sum(amt_net),2) ir_ext_sales from cvo_invreg_vw
where date_applied between @jdatefrom and @jdateto
GROUP BY POSTED_FLAG

union all
select 'TSR', 'YES', ROUND(SUM(ANET),2) TSR_SALES FROM
cvo_csbm_shipto_daily where yyyymmdd between @datefrom and @dateto

END

GO
GRANT EXECUTE ON  [dbo].[CVO_IR_AR_GL_Recon_sp] TO [public]
GO

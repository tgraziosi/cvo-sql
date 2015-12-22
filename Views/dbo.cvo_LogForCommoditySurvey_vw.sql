SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ACCOUNTING - LOG FOR COMMODITY SURVEYS  (7/10/12 ELaBarbera)
-- 071812 - tag - Convert to EV

CREATE view [dbo].[cvo_LogForCommoditySurvey_vw] as 

--use cvo 
---- SETUP DATE VARIABLES
--DECLARE @DateFrom datetime
--DECLARE @DateTo datetime
--SET @DateFrom = '7/1/2012'
--SET @DateTo = '7/7/2012'
--SELECT @DateTo = DATEADD(mi, 59,(DATEADD(hh, 23, @DateTo)))
-- 
--declare @date1 datetime
--declare @JDateFrom int
--set @date1=@DateFrom
--select @JDateFrom = datediff(day,'1/1/1950',convert(datetime,
--  convert(varchar( 8), (year(@date1) * 10000) + (month(@date1) * 100) + day(@date1)))  ) + 711858
-- 
--declare @date2 datetime
--declare @JDateTo int
--set @date2=@DateTo
--select @JDateTo = datediff(day,'1/1/1950',convert(datetime,
--  convert(varchar( 8), (year(@date2) * 10000) + (month(@date2) * 100) + day(@date2)))  ) + 711858

-- AR POSTED
Select O1.ORDER_NO AS Order_no,
O1.EXT AS Ext,
o1.routing,
'' as DaysOfDelivery,
SubString(t1.doc_ctrl_num,4,10) as Invoice_no,
datepart(month,convert(varchar,dateadd(d,t1.DATE_APPLIED-711858,'1/1/1950'),101)) AS Month,
datepart(Day,convert(varchar,dateadd(d,t1.DATE_APPLIED-711858,'1/1/1950'),101)) AS Day,
A.address_name as Name,
CASE WHEN t1.trx_type = '2031' THEN (amt_net - (amt_freight+amt_tax)) ELSE (amt_net - (amt_freight+amt_tax)) * -1  END as Amount,
ISNULL((SELECT SUM(WEIGHT_EA) FROM ORD_LIST TT2 WHERE O1.ORDER_NO=TT2.ORDER_NO AND O1.EXT=TT2.ORDER_EXT),0) AS WEIGHT,
'38101' as SCTG_Code,
'Eyewear' as Commodity,
'N' AS TempControlled,
Ship_to_City,
Ship_to_State,
Ship_to_Zip,
date_applied
	FROM artrx t1(nolock)
LEFT OUTER JOIN CVO_ORDERS_ALL (NOLOCK) O2 ON CASE WHEN LEN(t1.order_ctrl_num) <9 THEN left(t1.order_ctrl_num,5) 
											WHEN LEN(t1.order_ctrl_num) =0 THEN '' 
											 ELSE left(t1.order_ctrl_num,7) END=O2.order_no AND right(t1.order_ctrl_num,1)=O2.EXT
LEFT OUTER JOIN ORDERS_ALL (NOLOCK) O1 ON
		(t1.order_ctrl_num = rtrim(ltrim(convert(varchar,o1.order_no) + '-' + convert(varchar,o1.ext))) ) 
LEFT JOIN arsalesp (nolock) t3 ON t1.salesperson_code = t3.salesperson_code
LEFT OUTER JOIN armaster (NOLOCK) A on t1.customer_code=A.customer_code AND t1.ship_to_code=A.ship_to_code
	WHERE t1.trx_type in ('2031','2032')
AND t1.DOC_DESC NOT LIKE 'CONVERTED%'
--and t1.DATE_APPLIED between @JDateFrom and @JDateTo
AND t1.doc_desc NOT LIKE '%NONSALES%'
AND t1.doc_ctrl_num NOT LIKE 'CB%'
AND t1.doc_ctrl_num NOT LIKE 'FIN%'
and t1.void_flag = 0
and t1.posted_flag = 1

UNION ALL
--AR UNPOSTED
Select O1.ORDER_NO AS Order_no,
O1.EXT AS Ext,
o1.routing,
'' as DaysOfDelivery,
SubString(t1.doc_ctrl_num,4,10) as Invoice_no,
datepart(month,convert(varchar,dateadd(d,t1.DATE_APPLIED-711858,'1/1/1950'),101)) AS Month,
datepart(Day,convert(varchar,dateadd(d,t1.DATE_APPLIED-711858,'1/1/1950'),101)) AS Day,
A.address_name as Name,
CASE WHEN t1.trx_type = '2031' THEN (amt_net - (amt_freight+amt_tax)) ELSE (amt_net - (amt_freight+amt_tax)) * -1 END as Amount,
ISNULL((SELECT SUM(WEIGHT_EA) FROM ORD_LIST TT2 WHERE O1.ORDER_NO=TT2.ORDER_NO AND O1.EXT=TT2.ORDER_EXT),0) AS WEIGHT,
'38101' as SCTG_Code,
'Eyewear' as Commodity,
'N' AS TempControlled,
O1.Ship_to_City,
O1.Ship_to_State,
O1.Ship_to_Zip,
date_applied
	FROM ARINPCHG t1(nolock)
LEFT OUTER JOIN ORDERS_ALL (NOLOCK) O1 ON
		(t1.order_ctrl_num = rtrim(ltrim(convert(varchar,o1.order_no) + '-' + convert(varchar,o1.ext))) ) 
LEFT JOIN arsalesp (nolock) t3 ON t1.salesperson_code = t3.salesperson_code
LEFT OUTER JOIN armaster (NOLOCK) A on t1.customer_code=A.customer_code AND t1.ship_to_code=A.ship_to_code
	where t1.trx_type in ('2031','2032')
AND DOC_DESC NOT LIKE 'CONVERTED%'
-- and t1.DATE_APPLIED between @JDateFrom and @JDateTo
AND t1.doc_ctrl_num NOT LIKE 'CB%'
AND t1.doc_ctrl_num NOT LIKE 'FIN%'
AND t1.doc_desc NOT LIKE '%NONSALES%'
 
GO
GRANT SELECT ON  [dbo].[cvo_LogForCommoditySurvey_vw] TO [public]
GO

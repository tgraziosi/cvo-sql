SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[CVO_REGISTER_TMP]
AS


-- invoice
SELECT
	distinct
	O.ORDER_NO,
	O.ext,
	'' as doc_ctrl_num,
	DATEDIFF(DD,'1/1/1753',CONVERT(DATETIME,CONVERT(VARCHAR(12),O.date_shipped,101))) +639906 AS TRXDATE
	,COUNT(distinct convert(varchar(10),O.ORDER_NO)+ '-'+convert(varchar(2),O.ext)) AS CNTINV
	,0 AS CNTCRD
	,SUM(L.Shipped * C.LIST_PRICE) AS NETLIST
	,SUM(L.Shipped * L.PRICE) AS NETSALES
	,0 AS CRDAMT
	,(	SUM(round((L.Shipped * C.LIST_PRICE),2))  - SUM(round((L.Shipped * L.PRICE),2) ) )AS NETDISC
	,MAX(O.total_tax) AS NETTAX
	,MAX(O.freight) AS NETFREIGHT
	,0 as CRDTAX
	,0 as CRDFREIGHT
	,DATEDIFF(DD,'1/1/1753',CONVERT(DATETIME,CONVERT(VARCHAR(12),date_shipped,101))) +639906 AS X_TRXDATE
FROM	
		orders_all AS O (nolock)
		INNER JOIN ord_list AS L (nolock) ON O.order_no = L.order_no AND	O.ext = L.order_ext
		INNER JOIN CVO_ord_list AS C (nolock) ON L.order_no = C.order_no AND	L.order_ext = C.order_ext AND L.line_no = C.line_no
WHERE O.STATUS = 'T' 
AND O.TYPE = 'I' 
AND l.shipped > 0
and O.terms not like 'INS%'
GROUP BY 
	DATEDIFF(DD,'1/1/1753',CONVERT(DATETIME,CONVERT(VARCHAR(12),O.date_shipped,101))) +639906,
	DATEDIFF(DD,'1/1/1753',CONVERT(DATETIME,CONVERT(VARCHAR(12),O.date_shipped,101))) +639906,	
	O.ORDER_NO, O.ext

UNION 

-- credit
SELECT 
distinct
	O.ORDER_NO,
	O.ext,
	'' as doc_ctrl_num,
	DATEDIFF(DD,'1/1/1753',CONVERT(DATETIME,CONVERT(VARCHAR(12),O.date_shipped,101))) +639906
	,0 AS CNTINV
	,COUNT(distinct convert(varchar(10),O.ORDER_NO)+ '-'+convert(varchar(2),O.ext)) AS CNTCRD
	,0 AS NETLIST
	,0 AS NETSALES
	,SUM(O.GROSS_SALES)*-1 AS CRDAMT
	,0 AS NETDISC
	,0 AS NETTAX
	,0 AS NETFREIGHT
	,MAX(O.total_tax)*-1  as CRDTAX
	,MAX(O.freight)*-1 as CRDFREIGHT
	,DATEDIFF(DD,'1/1/1753',CONVERT(DATETIME,CONVERT(VARCHAR(12),O.date_shipped,101))) +639906 AS X_TRXDATE
FROM	ORDERS_ALL O (nolock) --INNER JOIN CVO_ORD_LIST C 
--ON		O.ORDER_NO = C.ORDER_NO 
--AND		O.EXT = C.ORDER_EXT
where		O.STATUS = 'T'
AND		O.TYPE = 'C'
and O.terms not like 'INS%'
GROUP BY 
	DATEDIFF(DD,'1/1/1753',CONVERT(DATETIME,CONVERT(VARCHAR(12),O.date_shipped,101))) +639906,
	DATEDIFF(DD,'1/1/1753',CONVERT(DATETIME,CONVERT(VARCHAR(12),O.date_shipped,101))) +639906	,
	O.ORDER_NO, O.ext

--/*
UNION

-- Pull In AR records done thru AR directly

SELECT
distinct
	convert(int,left(order_ctrl_num,7)) as ORDER_NO , 
	convert(int,right(order_ctrl_num,1)) as ext,
	doc_ctrl_num,
	date_applied AS TRXDATE
	,COUNT(distinct doc_ctrl_num) AS CNTINV
	,0 AS CNTCRD
	,SUM(amt_gross) AS NETLIST
	,SUM(amt_net - amt_freight - amt_tax) AS NETSALES
	,0 AS CRDAMT
	,SUM(amt_discount) AS NETDISC
	,MAX(amt_tax) AS NETTAX
	,MAX(amt_freight) AS NETFREIGHT
	,0 as CRDTAX
	,0 as CRDFREIGHT
	,date_applied AS X_TRXDATE
FROM	
		artrx (nolock)
WHERE trx_type in (2031, 2021) 
AND (order_ctrl_num = '' or left(doc_desc,3) not in ('SO:', 'CM:') or terms_code like 'INS%')
AND doc_desc NOT LIKE '%NONSALES%'
GROUP BY 
	date_applied, doc_ctrl_num, trx_type, order_ctrl_num
	

UNION

SELECT
distinct
	convert(int,left(order_ctrl_num,7)) as ORDER_NO , 
	convert(int,right(order_ctrl_num,1)) as ext,
	doc_ctrl_num,
	date_applied AS TRXDATE
	,0 AS CNTINV
	,COUNT(distinct doc_ctrl_num) AS CNTCRD
	,0 AS NETLIST
	,0 AS NETSALES
	,SUM(amt_net - amt_freight - amt_tax)*-1 AS CRDAMT
	--,SUM(amt_gross)*-1 AS CRDAMT
	,0 AS NETDISC
	,0 AS NETTAX
	,0 AS NETFREIGHT
	,MAX(amt_tax)*-1 as CRDTAX
	,MAX(amt_freight)*-1 as CRDFREIGHT
	,date_applied AS X_TRXDATE
FROM	
		artrx (nolock)
WHERE trx_type = 2032 
AND (order_ctrl_num = '' or left(doc_desc,3) not in ('SO:', 'CM:') or terms_code like 'INS%')
AND doc_desc NOT LIKE '%NONSALES%'
GROUP BY 
	date_applied, doc_ctrl_num,trx_type,order_ctrl_num
--*/
UNION

-- Pull In unposte AR records done thru AR directly
SELECT
distinct
	convert(int,left(order_ctrl_num,7)) as ORDER_NO , 
	convert(int,right(order_ctrl_num,1)) as ext,
	doc_ctrl_num,
	date_applied AS TRXDATE
	,COUNT(distinct doc_ctrl_num) AS CNTINV
	,0 AS CNTCRD
	,SUM(amt_gross) AS NETLIST
	,SUM(amt_net - amt_freight - amt_tax) AS NETSALES
	,0 AS CRDAMT
	,SUM(amt_discount) AS NETDISC
	,MAX(amt_tax) AS NETTAX
	,MAX(amt_freight) AS NETFREIGHT
	,0 as CRDTAX
	,0 as CRDFREIGHT
	,date_applied AS X_TRXDATE
FROM	
		arinpchg_all (nolock)
WHERE trx_type  in (2031, 2021)
AND (order_ctrl_num = '' or left(doc_desc,3) not in ('SO:', 'CM:') or terms_code like 'INS%')
AND doc_desc NOT LIKE '%NONSALES%'
GROUP BY 
	date_applied, doc_ctrl_num, trx_type,order_ctrl_num
	

UNION

SELECT
distinct
	convert(int,left(order_ctrl_num,7)) as ORDER_NO , 
	convert(int,right(order_ctrl_num,1)) as ext,
	doc_ctrl_num,
	date_applied AS TRXDATE
	,0 AS CNTINV
	,COUNT(distinct doc_ctrl_num) AS CNTCRD
	,0 AS NETLIST
	,0 AS NETSALES
	--,SUM(amt_gross)*-1 AS CRDAMT
	,SUM(amt_net - amt_freight - amt_tax)*-1 AS CRDAMT
	,0 AS NETDISC
	,0 AS NETTAX
	,0 AS NETFREIGHT
	,MAX(amt_tax)*-1as CRDTAX
	,MAX(amt_freight)*-1 as CRDFREIGHT
	,date_applied AS X_TRXDATE
FROM	
		arinpchg_all (nolock)
WHERE trx_type = 2032 
AND (order_ctrl_num = '' or left(doc_desc,3) not in ('SO:', 'CM:') or terms_code like 'INS%')
AND doc_desc NOT LIKE '%NONSALES%'

GROUP BY 
	date_applied, doc_ctrl_num, trx_type, order_ctrl_num



GO
GRANT SELECT ON  [dbo].[CVO_REGISTER_TMP] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_REGISTER_TMP] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_REGISTER_TMP] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_REGISTER_TMP] TO [public]
GO

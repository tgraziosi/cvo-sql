SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--  EXEC SSRS_Territory_Planner_sp '1/1/2009','12/31/2009 23:59:59'

CREATE Procedure [dbo].[SSRS_Territory_Planner_sp]
@DateFrom datetime,                                    
@DateTo datetime	
AS
Begin
IF(OBJECT_ID('dbo.SSRS_Territory_Planner') is not null)
drop table dbo.SSRS_Territory_Planner
-- TERITORY PLANNER
-------- CREATED BY *Elizabeth LaBarbera*  9/24/12

--DECLARES
		--DECLARE @DateFrom datetime                                    
		--DECLARE @DateTo datetime		
		DECLARE @DateFromLY datetime                                    
		DECLARE @DateToLY datetime

		DECLARE @JDateFrom int                                    
		DECLARE @JDateTo int		
		DECLARE @JDateFromLY int                                    
		DECLARE @JDateToLY int

--DECLARE @TStartDate DATETIME

--    Select @DateFrom = CAST(@Year AS VARCHAR(4)) +
--                       CASE WHEN @Quarter = 1 THEN '/04/01'
--                            WHEN @Quarter = 2 THEN '/07/01'
--                            WHEN @Quarter = 3 THEN '/10/01'
--                            WHEN @Quarter = 4 THEN '/01/01'
--                       END
--IF (@Quarter <> 4 )
-- Set @DateFrom = DateAdd(yyyy,-1,@DateFrom)

----DECLARE @TEndDate DATETIME

--    Set @DateTo = CAST(@YEAR AS VARCHAR(4)) +
--                       CASE WHEN @Quarter = 1 THEN '/03/31'
--                            WHEN @Quarter = 2 THEN '/06/30'
--                            WHEN @Quarter = 3 THEN '/09/30'
--                            WHEN @Quarter = 4 THEN '/12/31'
--                       END
--SETS
			--SET @DateFrom = '1/1/2013'
			--SET @DateTo = '12/31/2013'
				SET @dateTo=dateadd(second,-1,@dateTo)
				SET @dateTo=dateadd(day,1,@dateTo)
			SET @DateFromLY = dateadd(year,-1,@dateFrom)
			SET @DateToLY = dateadd(Year,-1,@dateTo)

/* DEFAULTS FOR SSRS
			SET @DateFrom = First of this Month
			SET @DateTo = Getdate()
			SET @DateFromLY = @DateFrom - 1Yr
			SET @DateToLY = = @DateTo - 1Yr
*/

-- Convert Dates to JULIAN
		set @JDATEFROM = datediff(day,'1/1/1950',convert(datetime,
		  convert(varchar( 8), (year(@datefrom) * 10000) + (month(@datefrom) * 100) + day(@datefrom)))  ) + 711858

-- PULL JDateTo from dateto
		select @JDATETO = datediff(day,'1/1/1950',convert(datetime,
		  convert(varchar( 8), (year(@dateto) * 10000) + (month(@dateto) * 100) + day(@dateto)))  ) + 711858

-- Convert Dates to JULIAN  LY
		set @JDATEFROMLY = datediff(day,'1/1/1950',convert(datetime,
		  convert(varchar( 8), (year(@datefromLY) * 10000) + (month(@datefromLY) * 100) + day(@datefrom)))  ) + 711858

-- PULL JDateTo from dateto  LY
		select @JDATETOLY = datediff(day,'1/1/1950',convert(datetime,
		  convert(varchar( 8), (year(@datetoLY) * 10000) + (month(@datetoLY) * 100) + day(@dateto)))  ) + 711858

-- SETUP LY FROM & TO DATES
		--set @JDATEFROMLY=@JDATEFROM-366
		--set @JDATETOLY=@JDATETO-366

-- Lookup 0 & 9 affiliated Accounts
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff') is not null)  
drop table #Rank_Aff  
select a.customer_code as from_cust, a.ship_to_code as shipto, a.affiliated_cust_code as to_cust
into #Rank_Aff
from armaster a (nolock) inner join
armaster b (nolock) on a.affiliated_cust_code = b.customer_code and a.ship_to_code = b.ship_to_code
where a.status_type <> 1 and a.address_type <> 9 
and a.affiliated_cust_code<> '' and a.affiliated_cust_code is not null
and b.status_type = 1 and b.address_type <> 9
--select @@rowcount
--select * from #Rank_Aff

-- Pull Customer#, Shipto#, Name, Addr, City, State, Zip, Phone, Fax, Contact
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S1') is not null)
drop table dbo.#RankCusts_S1
SELECT door, t1.customer_code, ship_to_code, territory_code, Address_name, addr2, City, State, Postal_code, contact_phone, tlx_twx, contact_email, contact_name  
INTO #RankCusts_S1
FROM armaster t1 (nolock)
join cvo_armaster_all T2 (nolock) on t1.customer_code=t2.customer_code and t1.ship_to_code=t2.ship_to
WHERE t1.ADDRESS_TYPE <>9
--select * from #RankCusts_S1

--Add ReClassify for Affiliation 
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff_All') is not null)
drop table dbo.#Rank_Aff_All
select X.* INTO #Rank_Aff_All FROM
( select from_cust AS CUST,'I' as Code from #Rank_Aff     UNION
select to_cust AS CUST,'A' Code from #Rank_Aff ) X
--SELECT * FROM #Rank_Aff_All 

-- Add 0/9 Statu to Customer Data
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3a') is not null)
drop table dbo.#RankCusts_S3a
Select ISNULL(t2.code,'A') Status, Right(customer_code, 5) as MergeCust, T1.*
INTO #RankCusts_S3a
from #RankCusts_S1 t1
full outer join #Rank_Aff_All t2 on t1.customer_code=t2.cust

-- add in Parent &/or BG
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3') is not null)
drop table dbo.#RankCusts_S3
select t1.*, 
case when t1.customer_code=t2.parent then '' else t2.parent end as Parent 
INTO #RankCusts_S3
from #RankCusts_S3a t1
right outer join artierrl (nolock) t2 on t1.customer_code=t2.rel_cust
where t1.customer_code is not null

-- Select Net Sales

--LIVE 
-- AR POSTED
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S4') is not null)
drop table dbo.#RankCusts_S4

create table #rankCusts_s4
(
cust_code varchar(10),
ship_to varchar(10),
order_no varchar(10),
ext int,
doc_ctrl_num varchar(16),
invoice_no varchar(10),
invoicedate datetime,
dateshipped datetime,
ordertype varchar(10),
type varchar(3),
item_code varchar(30),
retcode varchar(10),
collection varchar(10),
demographic varchar(10),
itemtype varchar(10),
parttype varchar(15),
qty decimal(20,0),
extprice decimal(20,8),
loc varchar(10),
netqtyty decimal(20,0),
netqtyly decimal(20,0),
netsty float(20),
netsly decimal(20,8),
stqtyty decimal(20,0),
stqtyly decimal(20,0),
ststy decimal(20,8),
stsly decimal(20,8),
rxqtyty decimal(20,0),
rxqtyly decimal(20,0),
rxsty decimal(20,8),
rxsly decimal(20,8),
retty decimal(20,8),
retly decimal(20,8),
stretty decimal(20,8),
stretly decimal(20,8),
rxretty decimal(20,8),
rxretly decimal(20,8)
)




--POSTED AR TY  -non Split Billing
INSERT INTO #RankCusts_S4 
SELECT AH.customer_code as Cust_code, 
AH.ship_to_code as Ship_to, 
OH.order_no as Order_no,
OH.ext as Ext,
AH.doc_ctrl_num,
SubString(AH.doc_ctrl_num,4,10) as Invoice_no,
convert(DATETIME,dateadd(d,date_doc-711858,'1/1/1950'),101) AS InvoiceDate,
convert(DATETIME,dateadd(d,AH.DATE_APPLIED-711858,'1/1/1950'),101) AS DateShipped,
CASE WHEN OH.user_category IS NULL THEN 'ST'
		WHEN OH.user_category ='' THEN 'ST'
		ELSE OH.user_category END AS OrderType,
CASE WHEN AH.trx_type = '2031' THEN 'Inv' ELSE 'Crd' END as type,
ad.Item_code,
ISNULL((select TOP 1 OD.Return_code FROM Ord_list OD (NOLOCK) 
	WHERE OH.order_no=OD.Order_no and OH.ext=OD.order_ext and AD.item_code=OD.Part_no),'') as RetCode,
im.category as Collection,
CASE WHEN ima.category_2 like '%child%' then 'Kids' else 'Adult' END as Demographic,
im.type_code as ItemType,
ima.category_3 as PartType,
AD.QTY_Shipped-ad.qty_returned as QTY,
(ad.qty_shipped-ad.qty_returned)*ad.unit_price as extprice,
'PostedTY' as Loc,
(AD.QTY_Shipped-AD.QTY_returned) AS NetQtyTY,
0 AS NetQtyLY,
case when ah.trx_type = 2031 then ad.extended_price else -ad.extended_price end AS NetSTY,
0 AS NetSLY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	THEN (AD.QTY_Shipped-AD.QTY_returned) ELSE 0 END AS STQtyTY,0 AS STQtyLY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	then case when ah.trx_type = 2031 then ad.extended_price else -ad.extended_price end ELSE 0 END AS STSTY,0 AS STSLY,
CASE WHEN oh.user_category LIKE 'RX%'
	THEN (AD.QTY_Shipped-AD.QTY_returned) ELSE 0 END AS RXQtyTY,0  AS RXQtyLY,
CASE WHEN oh.user_category LIKE 'RX%'
	then case when ah.trx_type = 2031 then ad.extended_price else -ad.extended_price end ELSE 0 END AS RXSTY,0  AS RXSLY,
case when ah.trx_type = 2032 then -ad.extended_price else 0 end AS RetTY,0  AS RetLY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	THEN case when ah.trx_type = 2032 then -ad.extended_price else 0 end ELSE 0 END AS STRetTY,  -- edited for negatives
0  AS STRetLY,
CASE WHEN oh.user_category LIKE 'RX%'
THEN case when ah.trx_type = 2032 then -ad.extended_price else 0 end ELSE 0 END AS RXRetTY,  -- edited for negatives
0  AS RXRetLY
FROM artrxcdt AD (nolock)
INNER JOIN artrx AH (nolock) on AD.trx_ctrl_num = AH.trx_ctrl_num 
--and ad.doc_ctrl_num = ah.doc_ctrl_num
FULL outer join orders_all OH (nolock) on (AH.order_ctrl_num = rtrim(ltrim(convert(varchar,OH.order_no) + '-' + convert(varchar,OH.ext))) ) 
--left outer join orders_invoice oi (nolock) on ad.trx_ctrl_num = oi.trx_ctrl_num 
--left outer join orders_all oh (nolock) on oi.order_no = oh.order_no and oi.order_ext = oh.ext
left outer join inv_master IM (NOLOCK) on ad.item_code=IM.Part_no
left outer join inv_master_add IMA  (nolock) on  ad.item_code=IMa.Part_no
WHERE AH.trx_type in (2031,2032)
and (AH.date_applied between @JDateFrom and @JDateTo)
AND AH.DOC_DESC NOT LIKE 'CONVERTED%' AND AH.doc_desc NOT LIKE '%NONSALES%'
AND AH.doc_ctrl_num NOT LIKE 'CB%' AND AH.doc_ctrl_num NOT LIKE 'FIN%'
and AH.void_flag = '0' and AH.posted_flag = '1'
and (AH.doc_ctrl_num not like '%-%' OR AH.doc_ctrl_num is null)



--POSTED AR TY - Split Billed Invoices
insert into #rankcusts_s4
SELECT AH.customer_code as Cust_code, 
AH.ship_to_code as Ship_to, 
OH.order_no as Order_no,
OH.ext as Ext,
AH.doc_ctrl_num,
SubString(AH.doc_ctrl_num,4,10) as Invoice_no,
convert(DATETIME,dateadd(d,date_doc-711858,'1/1/1950'),101) AS InvoiceDate,
convert(DATETIME,dateadd(d,AH.DATE_APPLIED-711858,'1/1/1950'),101) AS DateShipped,
CASE WHEN OH.user_category IS NULL THEN 'ST'
		WHEN OH.user_category ='' THEN 'ST'
		ELSE OH.user_category END AS OrderType,
CASE WHEN AH.trx_type = 2031 THEN 'Inv' ELSE 'Crd' END as type,
OD.part_no AS item_code,
ISNULL((select TOP 1 OD1.Return_code FROM Ord_list OD1 (NOLOCK) WHERE OH.order_no=OD1.Order_no and OH.ext=OD1.order_ext and OD.part_no=OD1.Part_no),'') as RetCode,
im.category as Collection,
CASE WHEN ima.category_2 like '%child%' then 'Kids' else 'Adult' END as Demographic,
im.type_code as ItemType,
ima.category_3 as PartType,
OD.shipped as QTY,
-- below new to adjust for amt_disc from cvo_ord_list not discount in ord_list
--CASE OD.DISCOUNT WHEN 0 THEN OD.SHIPPED*CURR_PRICE ELSE OD.SHIPPED*round((CURR_PRICE*odl.amt_disc),2,1) end AS extprice,
--CASE WHEN od.discount=0 then OD.shipped*Curr_Price WHEN od.discount=100 then 0 ELSE OD.shipped*(Curr_Price-(Curr_Price*(od.discount/100))) END AS extprice,
CASE OH.type WHEN 'I' THEN 
		CASE isnull(ODL.is_amt_disc,'N')   
			WHEN 'Y' THEN round((OD.curr_price - isnull(ODL.amt_disc,0)), 2)		
			ELSE round(OD.curr_price - (OD.curr_price * (OD.discount / 100.00)),2) END	
    ELSE round(OD.curr_price -  (OD.curr_price *  (OD.discount / 100.00)),2)		
END as extprice,
'PostedTYs' as Loc,
OD.shipped  AS NetQtytY,
0  AS NetQtylY,
-- below new to adjust for amt_disc from cvo_ord_list not discount in ord_list
--CASE OD.DISCOUNT WHEN 0 THEN OD.SHIPPED*CURR_PRICE ELSE OD.SHIPPED*round((CURR_PRICE-odl.amt_disc),2,1) end AS NetSTY,
--CASE OH.STATUS WHEN 'i' THEN
--			CASE is_amt_disc WHEN 'Y'  THEN round(shipped-amt_disc,2)
--							ELSE round(( (shipped*curr_price) * (OD.discount/100.00)),2) END
--	ELSE round(((CR_shipped*curr_price) * (OD.discount/100.00)),2) END AS netsty,
--case when od.discount=0 then (OD.SHIPPED*Curr_Price) WHEN od.discount=100 then 0  else (OD.SHIPPED*(Curr_Price-(Curr_Price*(od.discount/100)))) end AS NetSTY,
CASE OH.type
    WHEN 'I' THEN 
			CASE isnull(ODL.is_amt_disc,'N')   
			WHEN 'Y' THEN	round(OD.shipped * OD.curr_price,2) -  
						round((OD.shipped * isnull(ODL.amt_disc,0)),2)		
			ELSE	round(OD.shipped * OD.curr_price,2) -   
					round(( (OD.shipped * OD.curr_price) * (OD.discount / 100.00)),2) END			
    ELSE round(-OD.cr_shipped * OD.curr_price,2) -  
      round(( (-OD.cr_shipped * OD.curr_price) * (OD.discount / 100.00)),2) 		
END as NetSTY,
0  AS NetSlY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')	THEN OD.shipped ELSE 0 END AS STQtyTY,
0 AS STQtylY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')	then case when od.discount=0 then (OD.SHIPPED*Curr_Price) WHEN od.discount=100 then 0 else (OD.SHIPPED*(Curr_Price-(Curr_Price*(od.discount/100)))) end ELSE 0 end AS STSTY,
--case when ah.trx_type = 2031 then (OD.SHIPPED*(Curr_Price-(Curr_Price*(od.discount/100)))) else -(OD.CR_SHIPPED*(Curr_Price-(Curr_Price*(od.discount/100)))) end ELSE 0 END AS STSTY,
0 AS STSlY,
CASE WHEN OH.user_category LIKE 'RX%' THEN OD.shipped ELSE 0 END AS RXQtyTY,
0 AS RXQtyLY,
CASE WHEN OH.user_category LIKE 'RX%' then case when od.discount=0 then (OD.SHIPPED*Curr_Price) WHEN od.discount=100 then 0 else (OD.SHIPPED*(Curr_Price-(Curr_Price*(od.discount/100)))) end ELSE 0 END AS RXStY,
0 AS RXSLY,
0 AS RetTY,
0 AS RetLY,
0 AS STRetTY,
0 AS STRetLY,
0 AS RXRetTY,
0 AS RXRetLY
 FROM ORDERS_ALL OH (nolock) 
JOIN ord_list OD (nolock) ON OH.ORDER_NO=OD.ORDER_NO AND OH.EXT=OD.ORDER_EXT
join cvo_ord_list ODL (nolock) on OD.order_no=ODL.order_no and OD.order_ext=ODL.order_ext and OD.line_no=ODL.line_no
JOIN artrx AH(nolock) on  (AH.order_ctrl_num = rtrim(ltrim(convert(varchar,OH.order_no) + '-' + convert(varchar,OH.ext))) ) 
left outer join inv_master IM (NOLOCK) on OD.PART_NO=IM.Part_no
left outer join inv_master_add IMA  (nolock) on  OD.PART_NO=IMa.Part_no
WHERE AH.trx_type in (2031,2032) 
and (AH.date_applied between @JDateFrom and @JDateTo)
AND AH.DOC_DESC NOT LIKE 'CONVERTED%' AND AH.doc_desc NOT LIKE '%NONSALES%'
AND AH.doc_ctrl_num NOT LIKE 'CB%' AND AH.doc_ctrl_num NOT LIKE 'FIN%'
and AH.void_flag = '0' and AH.posted_flag = '1'
and AH.doc_ctrl_num like '%-1'

--POSTED AR LY  -non Split Billing
INSERT INTO #RankCusts_S4 
SELECT AH.customer_code as Cust_code, 
AH.ship_to_code as Ship_to, 
OH.order_no as Order_no,
OH.ext as Ext,
AH.doc_ctrl_num,
SubString(AH.doc_ctrl_num,4,10) as Invoice_no,
convert(DATETIME,dateadd(d,date_doc-711858,'1/1/1950'),101) AS InvoiceDate,
convert(DATETIME,dateadd(d,AH.DATE_APPLIED-711858,'1/1/1950'),101) AS DateShipped,
CASE WHEN OH.user_category IS NULL THEN 'ST'
		WHEN OH.user_category ='' THEN 'ST'
		ELSE OH.user_category END AS OrderType,
CASE WHEN AH.trx_type = '2031' THEN 'Inv' ELSE 'Crd' END as type,
ad.Item_code,
ISNULL((select TOP 1 OD.Return_code FROM Ord_list OD (NOLOCK) 
	WHERE OH.order_no=OD.Order_no and OH.ext=OD.order_ext and AD.item_code=OD.Part_no),'') as RetCode,
im.category as Collection,
CASE WHEN ima.category_2 like '%child%' then 'Kids' else 'Adult' END as Demographic,
im.type_code as ItemType,
ima.category_3 as PartType,
AD.QTY_Shipped-ad.qty_returned as QTY,
(ad.qty_shipped-ad.qty_returned)*ad.unit_price as extprice,
'PostedLY' as Loc,
0 AS NetQtyTY,
(AD.QTY_Shipped-AD.QTY_returned) AS NetQtyLY,
0 AS NetSTY,
case when ah.trx_type = 2031 then ad.extended_price else -ad.extended_price end AS NetSLY,
0 AS STQtyTY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	THEN (AD.QTY_Shipped-AD.QTY_returned) ELSE 0 END AS STQtyLY,
0 AS STSTY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	then case when ah.trx_type = 2031 then ad.extended_price else -ad.extended_price end ELSE 0 END AS STSLY,
0  AS RXQtyTY,
CASE WHEN oh.user_category LIKE 'RX%'
	THEN (AD.QTY_Shipped-AD.QTY_returned) ELSE 0 END AS RXQtyLY,
0  AS RXSTY,
CASE WHEN oh.user_category LIKE 'RX%'
	then case when ah.trx_type = 2031 then ad.extended_price else -ad.extended_price end ELSE 0 END AS RXSLY,
0  AS RetTY,
case when ah.trx_type = 2032 then -ad.extended_price else 0 end AS RetLY,
0  AS STRetTY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	THEN case when ah.trx_type = 2032 then -ad.extended_price else 0 end ELSE 0 END AS STRetLY,  -- edited for negatives
0  AS RXRetTY,
CASE WHEN oh.user_category LIKE 'RX%'
THEN case when ah.trx_type = 2032 then -ad.extended_price else 0 end ELSE 0 END AS RXRetLY  -- edited for negatives

FROM artrxcdt AD (nolock)
INNER JOIN artrx AH (nolock) on AD.trx_ctrl_num = AH.trx_ctrl_num 
--and ad.doc_ctrl_num = ah.doc_ctrl_num
FULL outer join orders_all OH (nolock) on (AH.order_ctrl_num = rtrim(ltrim(convert(varchar,OH.order_no) + '-' + convert(varchar,OH.ext))) ) 
--left outer join orders_invoice oi (nolock) on ad.trx_ctrl_num = oi.trx_ctrl_num 
--left outer join orders_all oh (nolock) on oi.order_no = oh.order_no and oi.order_ext = oh.ext
left outer join inv_master IM (NOLOCK) on ad.item_code=IM.Part_no
left outer join inv_master_add IMA  (nolock) on  ad.item_code=IMa.Part_no
WHERE AH.trx_type in (2031,2032)
and (AH.date_applied between @JDateFromLY and @JDateToLY)
AND AH.DOC_DESC NOT LIKE 'CONVERTED%' AND AH.doc_desc NOT LIKE '%NONSALES%'
AND AH.doc_ctrl_num NOT LIKE 'CB%' AND AH.doc_ctrl_num NOT LIKE 'FIN%'
and AH.void_flag = '0' and AH.posted_flag = '1'
and AH.doc_ctrl_num not like '%-%'

--POSTED AR LY - Split Billed Invoices
insert into #rankcusts_s4
SELECT AH.customer_code as Cust_code, 
AH.ship_to_code as Ship_to, 
OH.order_no as Order_no,
OH.ext as Ext,
AH.doc_ctrl_num,
SubString(AH.doc_ctrl_num,4,10) as Invoice_no,
convert(DATETIME,dateadd(d,date_doc-711858,'1/1/1950'),101) AS InvoiceDate,
convert(DATETIME,dateadd(d,AH.DATE_APPLIED-711858,'1/1/1950'),101) AS DateShipped,
CASE WHEN OH.user_category IS NULL THEN 'ST'
		WHEN OH.user_category ='' THEN 'ST'
		ELSE OH.user_category END AS OrderType,
CASE WHEN AH.trx_type = 2031 THEN 'Inv' ELSE 'Crd' END as type,
OD.part_no as item_code,
ISNULL((select TOP 1 OD1.Return_code FROM Ord_list OD1 (NOLOCK) WHERE OH.order_no=OD1.Order_no and OH.ext=OD1.order_ext and OD.part_no=OD1.Part_no),'') as RetCode,
im.category as Collection,
CASE WHEN ima.category_2 like '%child%' then 'Kids' else 'Adult' END as Demographic,
im.type_code as ItemType,
ima.category_3 as PartType,
OD.shipped-OD.cr_shipped as QTY,
--(OD.shipped-OD.cr_shipped)*(Curr_Price-(Curr_Price*(od.discount/100))) as extprice,
CASE OH.type WHEN 'I' THEN 
		CASE isnull(ODL.is_amt_disc,'N')   
			WHEN 'Y' THEN round((OD.curr_price - isnull(ODL.amt_disc,0)), 2)		
			ELSE round(OD.curr_price - (OD.curr_price * (OD.discount / 100.00)),2) END	
    ELSE round(OD.curr_price -  (OD.curr_price *  (OD.discount / 100.00)),2)		
END as extprice,
'PostedLYs' as Loc,
0  AS NetQtyTY,(OD.shipped-OD.cr_shipped)  AS NetQtyLY,0  AS NetSTY,
--case when ah.trx_type = 2031 then (OD.SHIPPED*(Curr_Price-(Curr_Price*(od.discount/100)))) else -(OD.CR_SHIPPED*(Curr_Price-(Curr_Price*(od.discount/100)))) end AS NetSLY,
-- --
CASE OH.type
    WHEN 'I' THEN 
			CASE isnull(ODL.is_amt_disc,'N')   
			WHEN 'Y' THEN	round(OD.shipped * OD.curr_price,2) -  
						round((OD.shipped * isnull(ODL.amt_disc,0)),2)		
			ELSE	round(OD.shipped * OD.curr_price,2) -   
					round(( (OD.shipped * OD.curr_price) * (OD.discount / 100.00)),2) END			
    ELSE round(-OD.cr_shipped * OD.curr_price,2) -  
      round(( (-OD.cr_shipped * OD.curr_price) * (OD.discount / 100.00)),2) 		
END as NetSLY,
-- --
0 AS STQtyTY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	THEN (OD.shipped-OD.cr_shipped) ELSE 0 END AS STQtyLY,
0 AS STSTY,CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	then case when ah.trx_type = 2031 then (OD.SHIPPED*(Curr_Price-(Curr_Price*(od.discount/100)))) else -(OD.CR_SHIPPED*(Curr_Price-(Curr_Price*(od.discount/100)))) end ELSE 0 END AS STSLY,
0 AS RXQtyTY,CASE WHEN OH.user_category LIKE 'RX%'
	THEN (OD.shipped-OD.cr_shipped) ELSE 0 END AS RXQtyLY,
0 AS RXSTY,CASE WHEN OH.user_category LIKE 'RX%'
	then case when ah.trx_type = 2031 then (OD.SHIPPED*(Curr_Price-(Curr_Price*(od.discount/100)))) else -(OD.CR_SHIPPED*(Curr_Price-(Curr_Price*(od.discount/100)))) end ELSE 0 END AS RXSLY,
0 AS RetTY,
0 AS RetLY,
0 AS STRetTY,
0 AS STRetLY,
0 AS RXRetTY,
0 AS RXRetLY
 FROM ORDERS_ALL OH (nolock) 
JOIN ord_list OD (nolock) ON OH.ORDER_NO=OD.ORDER_NO AND OH.EXT=OD.ORDER_EXT
join cvo_ord_list ODL (nolock) on OD.order_no=ODL.order_no and OD.order_ext=ODL.order_ext and OD.line_no=ODL.line_no
JOIN artrx AH(nolock) on  (AH.order_ctrl_num = rtrim(ltrim(convert(varchar,OH.order_no) + '-' + convert(varchar,OH.ext))) ) 
left outer join inv_master IM (NOLOCK) on OD.PART_NO=IM.Part_no
left outer join inv_master_add IMA  (nolock) on  OD.PART_NO=IMa.Part_no
WHERE AH.trx_type in (2031,2032) 
and (AH.date_applied between @JDateFromLY and @JDateToLY)
AND AH.DOC_DESC NOT LIKE 'CONVERTED%' AND AH.doc_desc NOT LIKE '%NONSALES%'
AND AH.doc_ctrl_num NOT LIKE 'CB%' AND AH.doc_ctrl_num NOT LIKE 'FIN%'
and AH.void_flag = '0' and AH.posted_flag = '1'
and AH.doc_ctrl_num like '%-1%'

-- UNPOSTED AR both years  -non Split Billing
insert into #rankcusts_s4
SELECT AH.customer_code as Cust_code, 
AH.ship_to_code as Ship_to, 
OH.order_no as Order_no,
OH.ext as Ext,
AH.doc_ctrl_num,
SubString(AH.doc_ctrl_num,4,10) as Invoice_no,
convert(DATETIME,dateadd(d,date_doc-711858,'1/1/1950'),101) AS InvoiceDate,
convert(DATETIME,dateadd(d,AH.DATE_APPLIED-711858,'1/1/1950'),101) AS DateShipped,
CASE WHEN OH.user_category IS NULL THEN 'ST'
		WHEN OH.user_category ='' THEN 'ST'
		ELSE OH.user_category END AS OrderType,
CASE WHEN AH.trx_type = '2031' THEN 'Inv' ELSE 'Crd' END as type,
ad.Item_code,
ISNULL((select TOP 1 OD.Return_code FROM Ord_list OD (NOLOCK) WHERE OH.order_no=OD.Order_no and OH.ext=OD.order_ext and AD.item_code=OD.Part_no),'') as RetCode,
im.category as Collection,
CASE WHEN ima.category_2 like '%child%' then 'Kids' else 'Adult' END as Demographic,
im.type_code as ItemType,
ima.category_3 as PartType,
AD.QTY_Shipped-ad.qty_returned as QTY,
(ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt) as extprice,
'UnPosted' as Loc,
CASE WHEN AH.date_applied between @JDateFrom and @JDateTo THEN (AD.QTY_Shipped-AD.QTY_returned) ELSE 0 END AS NetQtyTY,
CASE WHEN AH.date_applied between @JDateFromLY and @JDateToLY THEN (AD.QTY_Shipped-AD.QTY_returned) ELSE 0 END AS NetQtyLY,

CASE WHEN AH.date_applied between @JDateFrom and @JDateTo then (ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt) ELSE 0 END AS NetSTY,
CASE WHEN AH.date_applied between @JDateFromLY and @JDateToLY then (ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt) ELSE 0 END AS NetSLY,

CASE WHEN AH.date_applied between @JDateFrom and @JDateTo AND (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	THEN (AD.QTY_Shipped-AD.QTY_returned) ELSE 0 END AS STQtyTY,
CASE WHEN AH.date_applied between @JDateFromLY and @JDateToLY AND (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	THEN (AD.QTY_Shipped-AD.QTY_returned) ELSE 0 END AS STQtyLY,

CASE WHEN AH.date_applied between @JDateFrom and @JDateTo AND (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	then (ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt)	ELSE 0 END AS STSTY,
CASE WHEN AH.date_applied between @JDateFromLY and @JDateToLY AND (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	then (ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt)	ELSE 0 END AS STSLY,

CASE WHEN AH.date_applied between @JDateFrom and @JDateTo AND OH.user_category LIKE 'RX%'
	THEN (AD.QTY_Shipped-AD.QTY_returned) ELSE 0 END AS RXQtyTY,
CASE WHEN AH.date_applied between @JDateFromLY and @JDateToLY AND OH.user_category LIKE 'RX%'
	THEN (AD.QTY_Shipped-AD.QTY_returned) ELSE 0 END AS RXQtyLY,

CASE WHEN AH.date_applied between @JDateFrom and @JDateTo AND OH.user_category LIKE 'RX%'
	then (ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt) ELSE 0 END AS RXSTY,
CASE WHEN AH.date_applied between @JDateFromLY and @JDateToLY AND OH.user_category LIKE 'RX%'
	then(ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt) ELSE 0 END AS RXSLY,

CASE WHEN AH.date_applied between @JDateFrom and @JDateTo
	then (ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt) ELSE 0 END AS RetTY,
CASE WHEN AH.date_applied between @JDateFromLY and @JDateToLY 
	then (ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt) ELSE 0 END AS RetLY,

CASE WHEN AH.date_applied between @JDateFrom and @JDateTo  AND (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	THEN (ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt) ELSE 0 END AS STRetTY,
CASE WHEN AH.date_applied between @JDateFromLY and @JDateToLY AND (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')
	THEN (ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt) ELSE 0 END AS STRetLY,

CASE WHEN AH.date_applied between @JDateFrom and @JDateTo AND OH.user_category LIKE 'RX%'
THEN (ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt) ELSE 0 END AS RXRetTY,
CASE WHEN AH.date_applied between @JDateFromLY and @JDateToLY AND OH.user_category LIKE 'RX%'
THEN (ad.qty_shipped-ad.qty_returned)*(ad.unit_price-ad.discount_amt) ELSE 0 END AS RXRetLY

FROM arINPCDT AD (nolock)
INNER JOIN ARINPCHG AH (nolock) on AD.trx_ctrl_num = AH.trx_ctrl_num
FULL outer join orders_all OH (nolock) on (AH.order_ctrl_num = rtrim(ltrim(convert(varchar,OH.order_no) + '-' + convert(varchar,OH.ext))) ) 
--left outer join orders_invoice oi (nolock) on ah.trx_ctrl_num = oi.trx_ctrl_num 
--left outer join orders_all oh (nolock) on oi.order_no = oh.order_no and oi.order_ext = oh.ext
left outer join inv_master IM (NOLOCK) on ad.item_code=IM.Part_no
left outer join inv_master_add IMA  (nolock) on  ad.item_code=IMa.Part_no

WHERE AH.trx_type in (2031,2032)
and (AH.date_applied between @JDateFromLY and @JDateTo)
AND AH.DOC_DESC NOT LIKE 'CONVERTED%' AND AH.doc_desc NOT LIKE '%NONSALES%'
AND AH.doc_ctrl_num NOT LIKE 'CB%' AND AH.doc_ctrl_num NOT LIKE 'FIN%'
and AH.doc_ctrl_num not like '%-%'

--HISTORY LY
insert into #rankcusts_s4
SELECT OH.cust_code as Cust_code, 
OH.ship_to as Ship_to, 
OH.order_no as Order_no,
OH.ext as Ext,
'' as doc_ctrl_num,
OH.Invoice_no,
OH.invoice_date AS InvoiceDate,
OH.date_shipped AS DateShipped,
OH.user_category as OrderType,
CASE WHEN OH.type = 'I' THEN 'Inv' ELSE 'Crd' END as type,
OD.Part_no,
ISNULL(OD.Return_code,'') as RetCode,
im.category as Collection,
CASE WHEN ima.category_2 like '%child%' then 'Kids' else 'Adult' END as Demographic,
im.type_code as ItemType,
ima.category_3 as PartType,
OD.Shipped - OD.CR_SHIPPED as QTY,
CASE WHEN OH.TYPE = 'I' THEN OD.Shipped*OD.Price ELSE (OD.CR_SHIPPED*OD.Price)*-1 end as ExtPrice,
'HISTLY' as Loc,
0 AS NetQtyTY,
(OD.Shipped-OD.CR_shipped) AS NetQtyLY,
0 AS NetSTY,
(OD.Shipped-od.cr_shipped)*OD.Price AS NetSLY,
0 AS STQtyTY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%') THEN (OD.Shipped-OD.CR_shipped) ELSE 0 END AS STQtyLY,
0 AS STSTY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%') THEN (OD.Shipped-od.cr_shipped)*OD.Price ELSE 0 END AS STSLY,
0 AS RXQtyTY,
CASE WHEN oh.user_category LIKE 'RX%' THEN (OD.Shipped-OD.CR_shipped) ELSE 0 END AS RXQtyLY,
0 AS RXSTY,
CASE when oh.user_category LIKE 'RX%' THEN (OD.Shipped-od.cr_shipped)*OD.Price ELSE 0 END AS RXSLY,
0 AS RetTY,
(OD.CR_Shipped*OD.Price)*-1 AS RetLY,
0 AS STRetTY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%') THEN (OD.CR_Shipped*OD.Price)*-1 ELSE 0 END AS STRetLY,
0 AS RXRetTY,
CASE WHEN oh.user_category LIKE 'RX%' THEN (OD.CR_Shipped*OD.Price)*-1 ELSE 0 END AS RXRetLY

FROM cvo_ord_list_hist OD (nolock)
JOIN cvo_orders_all_hist OH (nolock) on OD.order_no= OH.order_no and OD.order_ext=OH.ext
left outer join inv_master IM (NOLOCK) on od.part_no=IM.Part_no
left outer join inv_master_add IMA  (nolock) on  od.part_no=IMa.Part_no
Where(OH.date_shipped between @DateFromLY and @DateToLY)

-- History TY
insert into #rankcusts_s4
SELECT OH.cust_code as Cust_code, 
OH.ship_to as Ship_to, 
OH.order_no as Order_no,
OH.ext as Ext,
'' as doc_ctrl_num,
OH.Invoice_no,
OH.invoice_date AS InvoiceDate,
OH.date_shipped AS DateShipped,
OH.user_category as OrderType,
CASE WHEN OH.type = 'I' THEN 'Inv' ELSE 'Crd' END as type,
OD.Part_no,
ISNULL(OD.Return_code,'') as RetCode,
im.category as Collection,
CASE WHEN ima.category_2 like '%child%' then 'Kids' else 'Adult' END as Demographic,
im.type_code as ItemType,
ima.category_3 as PartType,
OD.Shipped - OD.CR_SHIPPED as QTY,
CASE WHEN OH.TYPE = 'I' THEN OD.Shipped*OD.Price ELSE (OD.CR_SHIPPED*OD.Price)*-1 end as ExtPrice,
'HISTTY' as Loc,
(OD.Shipped-OD.CR_shipped) AS NetQtyTY,
0 AS NetQtyLY,
(OD.Shipped-od.cr_shipped)*OD.Price AS NetSTY,
0 AS NetSLY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')	THEN (OD.Shipped-OD.CR_shipped) ELSE 0 END AS STQtyTY,
0 AS STQtyLY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%') 	THEN (OD.Shipped-od.cr_shipped)*OD.Price ELSE 0 END AS STSTY,
0 AS STSLY,
CASE WHEN oh.user_category LIKE 'RX%'	THEN (OD.Shipped-OD.CR_shipped) ELSE 0 END AS RXQtyTY,
0 AS RXQtyLY,
CASE WHEN oh.user_category LIKE 'RX%' 	THEN (OD.Shipped-od.cr_shipped)*OD.Price ELSE 0 END AS RXSTY,
0 AS RXSLY,
(OD.CR_Shipped*OD.Price)*-1 AS RetTY,
0 AS RetLY,
CASE WHEN (OH.user_category IS NULL OR OH.user_category ='' OR oh.user_category NOT LIKE 'RX%')	THEN (OD.CR_Shipped*OD.Price)*-1 ELSE 0 END AS STRetTY,
0 AS STRetLY,

CASE WHEN oh.user_category LIKE 'RX%'	THEN (OD.CR_Shipped*OD.Price)*-1 ELSE 0 END AS RXRetTY,
0 AS RXRetLY

FROM cvo_ord_list_hist OD (nolock)
JOIN cvo_orders_all_hist OH (nolock) on OD.order_no= OH.order_no and OD.order_ext=OH.ext
left outer join inv_master IM (NOLOCK) on od.part_no=IM.Part_no
left outer join inv_master_add IMA  (nolock) on  od.part_no=IMa.Part_no

Where(OH.date_shipped between @DateFrom and @DateTo)


create index[#rank_idx1] on #rankcusts_s4 (retcode asc)

update #rankcusts_s4 set retty = 0, retly = 0, stretty=0, stretly = 0, rxretty = 0, rxretly = 0 
wHERE retcode IN ('01-04','05-01','05-24','05-35','06-22') OR retcode like '04-%'

create index[#rank_idx2] on #rankcusts_s4 (item_code asc)

-- -- --
-- FIND OLDEST ST ORDER IN LAST 365 DAYS
IF(OBJECT_ID('tempdb.dbo.#OldestOrderDate') is not null)
drop table dbo.#OldestOrderDate
SELECT CUSTOMER_CODE, SHIP_TO_CODE, 
	(SELECT TOP 1 t1.DATE_ENTERED
	FROM ORDERS_ALL (NOLOCK) T1
	JOIN ORD_LIST (NOLOCK) T2 ON T1.ORDER_NO = T2.ORDER_NO AND T1.EXT=T2.ORDER_EXT
	join inv_master (NOLOCK) t3 ON t2.part_no=t3.part_no
	where t1.cust_code=ar.customer_code and t1.ship_to=ar.ship_to_code 
	and t1.status='t'
	and t1.type='i'
	AND T1.EXT='0'
	AND t3.type_code in ('frame','sun')
	and t1.DATE_ENTERED between dateadd(day,1,dateadd(year,-1,@DateTo)) and @DateTo
	AND t1.user_category not like '%rx%'
	GROUP BY t1.cust_code, t1.ship_to, DATE_ENTERED
	HAVING COUNT(t2.ordered) >=5
	ORDER BY CUST_CODE, t1.SHIP_TO, DATE_ENTERED desc) as OldestSTOrdDate
INTO #OldestOrderDate
from armaster AR (nolock)
order by customer_code, ship_to_code


--select * from #rankcusts_s4 where cust_code='045217' and item_code in ('!','!LENS','M') order by item_code
IF(OBJECT_ID('tempdb.dbo.#SSRS_Territory_Planner') is not null)
drop table dbo.#SSRS_Territory_Planner

-- Customer /Ship To ONly Sales
select Status, RANK() OVER (Partition by territory_code order by sum(NetSTY) desc) as Rank, t2.territory_code, t2.door, t2.Customer_code, t2.ship_to_code,
 t2.address_name, t2.addr2,t2.city, t2.state, t2.postal_code, t2.contact_phone,t2.tlx_twx, t2.contact_email, t2.contact_name,
ISNULL(sum(NetSTY),0)NetSTY,
ISNULL(sum(NetSLY),0)NetSLY,
CASE WHEN SUM(NETSTY)is null THEN 1 WHEN SUM(RETTY)=0 THEN 0 WHEN (sum(NetSTY)-sum(RETTY))=0 THEN 1 ELSE ISNULL(-(sum(RETTY)/(sum(NetSTY)-sum(RETTY))),0) END as 'TY Ret%',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.collection='BCBG' and itemtype<>'SUN' and t11.demographic='Adult' and dateshipped between @DateFrom and @DateTo),0) 'BCBG',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.collection='ET' and itemtype<>'SUN' and t11.demographic='Adult' and dateshipped between @DateFrom and @DateTo),0) 'ET',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.collection='CH' and itemtype<>'SUN' and t11.demographic='Adult' and dateshipped between @DateFrom and @DateTo),0) 'CH',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.collection='ME' and itemtype<>'SUN' and t11.demographic='Adult' and dateshipped between @DateFrom and @DateTo),0) 'ME',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.collection='IZX' and itemtype<>'SUN' and t11.demographic='Adult' and dateshipped between @DateFrom and @DateTo),0) 'PFX',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.collection='IZOD' and itemtype<>'SUN' and t11.demographic='Adult' and dateshipped between @DateFrom and @DateTo),0) 'IZOD',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.collection='OP' and itemtype<>'SUN' and t11.demographic='Adult' and dateshipped between @DateFrom and @DateTo),0) 'OP',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.collection='JMC' and itemtype<>'SUN' and t11.demographic='Adult' and dateshipped between @DateFrom and @DateTo),0) 'JMC',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.collection='CVO' and itemtype<>'SUN' and t11.demographic='Adult' and item_code not like 'CVD0%' and dateshipped between @DateFrom and @DateTo),0) 'CVO',
-- 12/31/2014 - support for new DH collection
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and ((t11.collection = 'CVO' and item_code like 'CVD0%') OR t11.collection = 'DH') and itemtype<>'SUN' and t11.demographic='Adult' and dateshipped between @DateFrom and @DateTo),0) 'DH',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.collection='JC' and itemtype<>'SUN' and t11.demographic='Adult' and dateshipped between @DateFrom and @DateTo),0) 'JC',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.collection='PT' and itemtype<>'SUN' and t11.demographic='Adult' and dateshipped between @DateFrom and @DateTo),0) 'PT',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and t11.collection<>'FP' and t11.collection<>'DD' and dateshipped between @DateFrom and @DateTo),0) 'Kids',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and (t11.collection='FP' OR t11.collection='DD') and dateshipped between @DateFrom and @DateTo),0) 'Pediatric',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and itemtype='SUN' and dateshipped between @DateFrom and @DateTo),0) 'Suns',
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and (collection IS NULL OR (t11.demographic<>'Kids' and collection = 'CORP')) and dateshipped between @DateFrom and @DateTo),0) 'NonBrandSales',
CASE WHEN SUM(NETSTY)is null THEN 0 WHEN SUM(NETSTY)=0 THEN 0 
	WHEN (select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and ordertype like 'RX%' and dateshipped between @DateFrom and @DateTo) is null THEN 0 
	ELSE (ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.customer_code=t11.cust_code and t2.ship_to_code=t11.ship_to and ordertype like 'RX%' and dateshipped between @DateFrom and @DateTo),0)
			/ISNULL(sum(NetSTY),0)) END as 'TY RX Perc',
sum(RetTY) 'X_RetTY',
sum(RXSTY) 'X_RXSTY',
OldestSTOrdDate
into #SSRS_Territory_Planner
 from #RankCusts_S4 t1
full outer join #RankCusts_S3 t2 on t1.Cust_code=t2.Customer_code and t1.ship_to=t2.ship_to_code
left outer join #OldestOrderDate t3 on t1.Cust_code=t3.Customer_code and t1.ship_to=t3.ship_to_code
group by Status, t2.territory_code, t2.door, t2.Customer_code, t2.ship_to_code, t2.address_name, t2.addr2,t2.city, t2.state, t2.postal_code, t2.contact_phone,t2.tlx_twx, t2.contact_email, t2.contact_name,OldestSTOrdDate
order by territory_code, sum(NetSTY) desc

;With C AS
(
Select customer_code,address_name,addr2,city,state,postal_code,contact_phone,tlx_twx,contact_email,contact_name,OldestSTOrdDate,door From #SSRS_Territory_Planner
where ship_to_code = ''
)

Select a.*,C.address_name AS m_address,C.addr2 AS m_addr2,C.city AS m_city,C.state AS m_state,C.postal_code AS m_postal_code
,C.contact_phone AS m_contact_phone,C.tlx_twx AS m_tlx_twx,C.contact_email AS m_contact_email,C.contact_name AS m_contact_name,C.OldestSTOrdDate AS m_OldestSTOrdDate,C.door as m_door
-- into SSRS_TERRITORY_PLANNER_EL
From
#SSRS_Territory_Planner a inner Join C
On a.Customer_code = C.Customer_code


End


GO

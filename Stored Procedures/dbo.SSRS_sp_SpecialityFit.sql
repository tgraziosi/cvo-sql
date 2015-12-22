SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- exec SSRS_sp_SpecialityFit '1/1/2012', '12/31/2012', '2'

-- CUSTOMER RANKING

CREATE Procedure [dbo].[SSRS_sp_SpecialityFit] 
(
@DateFrom datetime,
@DateTo datetime,
@Version int
)
AS
Begin
Set Nocount ON
--DECLARES
		--DECLARE @Version int	--1-Customer/ShipTo & Customer Sales, 2-Customer/ShipTo & Customer Units

		--DECLARE @DateFrom datetime                                    
		--DECLARE @DateTo datetime		
		DECLARE @DateFromLY datetime                                    
		DECLARE @DateToLY datetime

		DECLARE @JDateFrom int                                    
		DECLARE @JDateTo int		
		DECLARE @JDateFromLY int                                    
		DECLARE @JDateToLY int

--SETS
			--SET @VERSION = 1

			--SET @DateFrom = '12/1/2012'
			--SET @DateTo = '12/31/2012'
				SET @dateTo=dateadd(second,-1,@dateTo)
				SET @dateTo=dateadd(day,1,@dateTo)
			SET @DateFromLY = dateadd(year,-1,@dateFrom)
			SET @DateToLY = dateadd(Year,-1,@dateTo)


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

-- Pull Customer#, Shipto#, Name, City, State, Zip 
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S1') is not null)
drop table dbo.#RankCusts_S1
--SELECT customer_code, ship_to_code, territory_code, Address_name, City, State, Postal_code  
SELECT CASE WHEN T2.DOOR = 1 THEN 'Y' else '' end as Door,
t1.customer_code, ship_to_code, territory_code, Address_name, addr2, addr3, addr4, City, State, Postal_code, contact_phone, tlx_twx, contact_email  
INTO #RankCusts_S1
FROM armaster t1 (nolock)
-- ADDED BELOW 11/20
LEFT OUTER JOIN CVO_ARMASTER_ALL T2 ON T1.CUSTOMER_CODE = T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO
WHERE t1.ADDRESS_TYPE <>9
-- select * from #RankCusts_S1

-- Get Designation Codes, into one field
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2A') is not null)
drop table dbo.#RankCusts_S2A
	;WITH C AS 
		( SELECT customer_code, code FROM cvo_cust_designation_codes (nolock) )
		select Distinct customer_code,
					STUFF ( ( SELECT '; ' + code 
					FROM cvo_cust_designation_codes (nolock)
					WHERE customer_code = C.customer_code
					FOR XML PATH ('') ), 1, 1, ''  ) AS NEW
	INTO #RankCusts_s2A
	FROM C
--select * from #RankCusts_S2A where customer_code='044423'

-- Add Designation to Customer Data
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2B') is not null)
drop table dbo.#RankCusts_S2B
Select T1.*, ISNULL(T2.NEW, '' ) as Designations
INTO #RankCusts_S2B
from #RankCusts_S1 t1
left outer join #RankCusts_S2A t2 on t1.customer_code=t2.customer_code
--select * from #RankCusts_S2B

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
from #RankCusts_S2B t1
full outer join #Rank_Aff_All t2 on t1.customer_code=t2.cust
-- select * from #RankCusts_S2b where mergecust='10197'
-- select * from #RankCusts_S3a

-- add in Parent &/or BG
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3c') is not null)
drop table dbo.#RankCusts_S3c
select t1.*, 
case when t1.customer_code=t2.parent then '' else t2.parent end as Parent 
INTO #RankCusts_S3c
from #RankCusts_S3a t1
right outer join artierrl (nolock) t2 on t1.customer_code=t2.rel_cust
where t1.customer_code is not null
-- select * from #RankCusts_S3c where status='a'
-- select distinct MergeCust, Ship_to_code from #RankCusts_S3c order by MergeCust, ship_to_code

-- CLEAN OUT EXTRA DUPLICATE 0 & 9
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3') is not null)
drop table dbo.#RankCusts_S3
select Max(ISNULL(Status,''))Status,			MergeCust, 
MAX(isnull(Door,''))Door,						MAX(isnull(customer_code,''))customer_code,		ship_to_code, 
MAX(isnull(territory_code,''))territory_code,	MAX(isnull(Address_name,''))Address_name,		MAX(isnull(addr2,''))addr2,
MAX(isnull(addr3,''))addr3,						MAX(isnull(addr4,''))addr4,	
MAX(isnull(City,''))City,						MAX(isnull(State,''))State,						MAX(isnull(Postal_code,''))Postal_code,
MAX(isnull(contact_phone,''))contact_phone,		MAX(isnull(tlx_twx,''))tlx_twx,					MAX(isnull(contact_email,''))contact_email,
MAX(isnull(Designations,''))Designations,		MAX(isnull(Parent,''))Parent
INTO #RankCusts_S3
FROM #RankCusts_S3c
group by MergeCust, Ship_to_code
order by MergeCust
-- select * from #RankCusts_S3
-- select * from #Rank_Aff where from_cust='010197'


-- Select Net Sales

--LIVE 
-- AR POSTED
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S4') is not null)
drop table dbo.#RankCusts_S4

create table #rankCusts_s4
(
MergeCust varchar(10),
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
specialfit varchar (20),
qty decimal(20,0),
extprice decimal(20,8),
loc varchar(10),
netqtyty decimal(20,0),
netqtyly decimal(20,0),
netsty decimal(20,8),
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
SELECT Right(AH.customer_code,5) as MergeCust, 
AH.customer_code as Cust_code, 
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
ISNULL(ima.field_32,'') as SpecialFit,
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
SELECT Right(AH.customer_code,5) as MergeCust,
AH.customer_code as Cust_code, 
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
ISNULL(ima.field_32,'') as SpecialFit,
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
SELECT Right(AH.customer_code,5) as MergeCust,
 AH.customer_code as Cust_code, 
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
ISNULL(ima.field_32,'') as SpecialFit,
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
SELECT Right(AH.customer_code,5) as MergeCust, 
AH.customer_code as Cust_code, 
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
ISNULL(ima.field_32,'') as SpecialFit,
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
SELECT Right(AH.customer_code,5) as MergeCust, 
AH.customer_code as Cust_code, 
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
ISNULL(ima.field_32,'') as SpecialFit,
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
SELECT Right(OH.cust_code,5) as MergeCust, 
OH.cust_code as Cust_code,
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
ISNULL(ima.field_32,'') as SpecialFit,
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
SELECT Right(OH.cust_code,5) as MergeCust, 
OH.cust_code as Cust_code, 
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
ISNULL(ima.field_32,'') as SpecialFit,
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

--select * from #rankcusts_s4

-- Remove NON Customer Credits
update #rankcusts_s4 set retty = 0, retly = 0, stretty=0, stretly = 0, rxretty = 0, rxretly = 0 
wHERE retcode IN ('01-04','05-01','05-24','05-35','06-22') OR retcode like '04-%'

create index[#rank_idx2] on #rankcusts_s3 (DOOR, MergeCust, ship_to_code asc)
create index[#rank_idx3] on #rankcusts_s4 (MergeCust, ship_to asc)

-- Add Door Info to Sales Sub Table
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S4d') is not null)
drop table dbo.#RankCusts_S4d
SELECT Door, t1.* INTO #RankCusts_S4d FROM #RankCusts_S4 t1
full outer join #RankCusts_S3 t2 on t1.MergeCust=t2.MergeCust and t1.ship_to=t2.ship_to_code


create index[#rank_idx4] on #RankCusts_S4d (Door, MergeCust, ship_to asc)


-- -- --  
-- select * from #RankCusts_S4d where netsty<0

-- select * from #RankCusts_S4

IF @Version = 1 
BEGIN
--Customer / Ship To Sales

IF(OBJECT_ID('dbo.SSRS_SpecialityFit_Temp_Sales') is not null)
drop table dbo.SSRS_SpecialityFit_Temp_Sales

select RANK() OVER (Partition by territory_code order by sum(NetSTY) desc) as Rank, status, t2.MergeCust, Door,dbo.calculate_region_fn(t2.territory_code) AS Region, t2.territory_code, t2.Customer_code, Ship_to_code, t2.address_name, t2.addr2, t2.addr3, t2.addr4, t2.city, t2.state, t2.postal_code, t2.contact_phone, t2.tlx_twx, t2.contact_email, t2.designations, t2.Parent,
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit = 'Global Fit'),0) AS S_GlobalFit,
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit = 'Style N'),0) AS S_StyleN,
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit = 'Petite'),0) AS S_Petite,
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit = 'XL'),0) AS S_XL,
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit = 'Pediatric'),0) AS S_Pediatric,
ISNULL((select sum(NetSTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit <>''),0) AS S_AllSpecialFit,

CASE WHEN SUM(NETSTY) = 0 THEN 1
	WHEN SUM(NETSTY) is null THEN 1 
	WHEN (select sum(NetSTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit <>'') IS NULL THEN 0
	WHEN (select sum(NetSTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit <>'')=0 THEN 0
	ELSE (select sum(NetSTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit <>'')/(SUM(NETSTY) ) END as S_PercAllSpecialFit,

ISNULL(sum(NetSTY),0)S_NetSTY, ISNULL(sum(NetSLY),0)S_NetSLY,

CASE WHEN SUM(RETTY) IS NULL THEN 0 
	WHEN SUM(RETTY)=0 THEN 0
	WHEN (SUM(NETSTY)-SUM(RETTY)) =0 THEN 1
	WHEN SUM(NETSTY) IS NULL THEN 1 
	WHEN SUM(NETSTY)=0 THEN 1
	ELSE ((-1*SUM(RETTY))/(SUM(NETSTY)-SUM(RETTY))) END as S_TYRetPerc,
	
	NULL AS U_GlobalFit,NULL AS U_StyleN,NULL AS U_Petite, NULL AS U_XL,NULL AS U_Pediatric,NULL AS U_AllSpecialFit,NULL AS U_PercAllSpecialFit,NULL AS U_NetQtyTY,NULL AS U_NetQtyLY,NULL AS U_TYRetPerc

--into SSRS_SpecialityFit_Temp_Sales
 from #RankCusts_S4 t1
full outer join #RankCusts_S3 t2 on t1.MergeCust=t2.MergeCust and t1.ship_to=t2.ship_to_code
group by status, t2.MergeCust, Door,dbo.calculate_region_fn(t2.territory_code), t2.territory_code, t2.Customer_code, t2.Ship_to_code, t2.address_name,t2.addr2, t2.addr3, t2.addr4, t2.city, t2.state, t2.postal_code, t2.contact_phone, t2.tlx_twx, t2.contact_email, t2.designations, t2.Parent
order by territory_code,sum(NetSTY) desc

END


IF @Version = 2 
BEGIN
--UNITS

IF(OBJECT_ID('dbo.SSRS_SpecialityFit_Temp_Units') is not null)
drop table dbo.SSRS_SpecialityFit_Temp_Units

IF(OBJECT_ID('dbo.Cust_Rank_Sales_Units') is not null)
drop table dbo.Cust_Rank_Sales_Units

select  RANK() OVER (Partition by territory_code order by sum(NetQtyTY) desc) as Rank, status, t2.MergeCust, Door,dbo.calculate_region_fn(t2.territory_code) AS Region, t2.territory_code, t2.Customer_code, Ship_to_code, t2.address_name, t2.addr2, t2.addr3, t2.addr4, t2.city, t2.state, t2.postal_code, t2.contact_phone, t2.tlx_twx, t2.contact_email, t2.designations, t2.Parent,
ISNULL((select sum(NetQtyTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and itemtype in ('sun','frame') and SpecialFit = 'Global Fit'),0) AS U_GlobalFit,
ISNULL((select sum(NetQtyTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and itemtype in ('sun','frame')and SpecialFit = 'Style N'),0) AS U_StyleN,
ISNULL((select sum(NetQtyTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and itemtype in ('sun','frame')and SpecialFit = 'Petite'),0) AS U_Petite,
ISNULL((select sum(NetQtyTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and itemtype in ('sun','frame')and SpecialFit = 'XL'),0) AS U_XL,
ISNULL((select sum(NetQtyTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and itemtype in ('sun','frame')and SpecialFit = 'Pediatric'),0) AS U_Pediatric,
ISNULL((select sum(NetQtyTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and itemtype in ('sun','frame')and SpecialFit <>''),0) AS U_AllSpecialFit,

CASE WHEN sum(NetQtyTY) = 0 then 1
	WHEN  sum(NetQtyTY) is null then 1
	WHEN (select sum(NetQtyTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit <>'')= 0 THEN 0
	WHEN (select sum(NetQtyTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit <>'') IS NULL THEN 0
ELSE ( ISNULL((select sum(NetQtyTY) from #RankCusts_S4 t11 where t2.MergeCust=t11.MergeCust and t2.ship_to_code=t11.ship_to and dateshipped between @DateFrom and @DateTo and SpecialFit <>''),0)  / ISNULL(sum(NetQtyTY),0) ) END AS U_PercAllSpecialFit,

ISNULL(sum(NetQtyTY),0) AS U_NetQtyTY, ISNULL(sum(NetQtyLY),0) AS U_NetQtyLY,
CASE	WHEN (select -1*sum(NetQtyTY) from #rankCusts_s4 t11 where t2.MergeCust=t11.MergeCust and dateshipped between @DateFrom and @DateTo and NetQtyTY <0) = 0 THEN 0  --RET
		WHEN (select -1*sum(NetQtyTY) from #rankCusts_s4 t11 where t2.MergeCust=t11.MergeCust and dateshipped between @DateFrom and @DateTo and NetQtyTY <0) IS NULL THEN 0   --RET
		WHEN (select sum(NetQtyTY) from #rankCusts_s4 t11 where t2.MergeCust=t11.MergeCust and dateshipped between @DateFrom and @DateTo and NetQtyTY>0) = 0 THEN 1   --GROSS
		WHEN (select sum(NetQtyTY) from #rankCusts_s4 t11 where t2.MergeCust=t11.MergeCust and dateshipped between @DateFrom and @DateTo and NetQtyTY>0) IS NULL THEN 1     --GROSS
		ELSE ( (select -1*sum(NetQtyTY) from #rankCusts_s4 t11 where t2.MergeCust=t11.MergeCust and dateshipped between @DateFrom and @DateTo and NetQtyTY <0) / (select sum(NetQtyTY) from #rankCusts_s4 t11 where t2.MergeCust=t11.MergeCust and dateshipped between @DateFrom and @DateTo and NetQtyTY>0) ) END AS U_TYRetPerc
,NULL AS S_GlobalFit,NULL AS S_StyleN,NULL AS S_Petite, NULL AS S_XL,NULL AS S_Pediatric,NULL AS S_AllSpecialFit,NULL AS S_PercAllSpecialFit,NULL AS S_NetSTY,NULL AS S_NetSLY,NULL AS S_TYRetPerc
--into SSRS_SpecialityFit_Temp_Units
from #RankCusts_S4 t1
full outer join #RankCusts_S3 t2 on t1.MergeCust=t2.MergeCust and t1.ship_to=t2.ship_to_code
where itemtype in ('sun','frame')
group by status, t2.MergeCust, Door,dbo.calculate_region_fn(t2.territory_code), t2.territory_code, t2.Customer_code, t2.Ship_to_code, t2.address_name,t2.addr2, t2.addr3, t2.addr4, t2.city, t2.state, t2.postal_code, t2.contact_phone, t2.tlx_twx, t2.contact_email, t2.designations, t2.Parent
order by territory_code,sum(NetQtyTY) desc
END


End



GO

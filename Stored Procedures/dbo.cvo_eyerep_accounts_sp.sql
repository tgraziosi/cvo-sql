SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		TG
-- Create date: 2/22/2016
-- Description:	EyeRep Main Customer Data
-- EXEC [cvo_eyerep_accounts_sp]
-- SELECT * From cvo_eyerep_acthis_tbl
-- SELECT * From cvo_eyerep_repEXT_tbl
-- SELECT * From cvo_eyerep_actsls_tbl
-- tag - 071213 - create a regular table instead of temp table
-- tag - 8/21/2015 - add sales rep customer accounts
-- tag - 6/30/2016 - add ordtyp.txt table for promotions
-- tag - 7/28/2016 - add actext.txt, actsls.txt, repext.txt
-- =============================================

CREATE PROCEDURE [dbo].[cvo_eyerep_accounts_sp] 
AS
BEGIN

	SET NOCOUNT ON;
	
	IF(OBJECT_ID('tempdb.dbo.#AllTerr') is not null) DROP table dbo.#AllTerr
      ;WITH C AS 
			( SELECT DISTINCT ar.territory_code, ar.customer_code 
			from
            ( SELECT DISTINCT territory_code FROM arterr (NOLOCK) 
			   WHERE dbo.calculate_region_fn(territory_code) < '800'
			   AND territory_code IN ('20206','70778', '50503', '40440','40456') -- phil, Elyse, dave s, kerry c, bob s
			) Terr
			   -- for testing 03/2016

			   join
			( SELECT distinct customer_code, territory_code FROM armaster (nolock) ) ar
			  ON terr.territory_code = ar.territory_code
			)	
            select Distinct customer_code,
                              STUFF ( ( SELECT distinct ',' + territory_code
                              FROM armaster (nolock)
                              WHERE customer_code = C.customer_code
                             FOR XML PATH ('') ), 1, 1, ''  ) AS AllTerr
      INTO #AllTerr
      FROM C

	  -- add sales rep customers too - 8/19/2015
	  INSERT INTO #allterr  (customer_code, AllTerr)
	  SELECT DISTINCT ISNULL(employee_code,'') customer_code, territory_code
	  FROM arsalesp (NOLOCK) 
	  WHERE ISNULL(employee_code,'') > ''
	  AND status_type = 1
	  AND territory_code IN ('20206','70778', '50503', '40440','40456') -- phil, Elyse, dave s, kerry c
	  AND NOT EXISTS(SELECT 1 FROM #allterr WHERE #allterr.customer_code = ISNULL(employee_code,'') )
	  

	  -- SELECT * FROM #allterr

-- PULL LIST FOR CUSTOMERS
IF(OBJECT_ID('dbo.cvo_eyerep_acts_tbl') is null)
	begin
	CREATE TABLE [dbo].[cvo_eyerep_acts_Tbl](
		[acct_id] [varchar](20) NOT NULL,
		[billing_name] [varchar](50) NULL,
		[billing_addr1] [varchar](50) NULL,
		[billing_addr2] [varchar](50) NULL,
		[billing_city] [varchar](30) NULL,
		[billing_state] [varchar](30) NULL,
		[billing_postal_code] [varchar](15) NULL,
		[billing_phone] [varchar](15) NULL,
		[billing_email] [varchar](100) NULL,
		[current_balance] [decimal](9, 2) NULL,
		[detail_note] [varchar](250) NULL,
		[account_status] [varchar](50) NULL,
		[account_sort] [varchar](50) NULL,
		[prospect] [char](1) NULL,
		[billing_fax] [varchar](15) NULL
	) ON [PRIMARY]

	GRANT ALL ON dbo.cvo_eyerep_acts_tbl TO PUBLIC
	end


truncate table cvo_eyerep_acts_tbl

INSERT INTO dbo.cvo_eyerep_acts_Tbl
        ( acct_id ,
          billing_name ,
          billing_addr1 ,
          billing_addr2 ,
          billing_city ,
          billing_state ,
          billing_postal_code ,
          billing_phone ,
          billing_email ,
          current_balance ,
          detail_note ,
          account_status ,
          account_sort ,
          prospect ,
          billing_fax
        )

SELECT ar.customer_code , 
LEFT(addr1,50) as bill_name,
LEFT(addr2,50) as bill_street,
LEFT(CASE WHEN addr3 LIKE '%, __ %' THEN '' ELSE ADDR3 END,50) AS bill_street2,
LEFT(city,30) as bill_city,
LEFT(state,30) as bill_state,
LEFT(postal_code,15) as bill_postcode,
LEFT(contact_phone,15) as bill_phone,
LEFT(CASE WHEN (contact_email LIKE '%cvoptical.com'
				OR contact_email LIKE '%refused%')
			THEN ''
			ELSE REPLACE(LOWER(ISNULL(contact_email,'')),';',',')
			END, 100),
0 AS current_balance,
'' AS detail_note,
LEFT(ar.status_type,50),
LEFT(ar.short_name,50),
'N' AS prospect,
LEFT(tlx_twx,15) as bill_fax

-- INTO cvo_eyerep_acts_tbl
FROM armaster ar (nolock)
INNER JOIN #allterr (nolock) on ar.customer_code = #allterr.customer_code
WHERE 1=1
AND STATUS_TYPE=1
AND ADDRESS_TYPE=0


-- Process Ship-to Customers

IF(OBJECT_ID('dbo.cvo_eyerep_actshp_tbl') is null)
	begin
	CREATE TABLE [dbo].[cvo_eyerep_actshp_tbl](
	[ship_id] [varchar](20) NOT NULL,
	[acct_id] [varchar](20) NOT NULL,
	[ship_name] [varchar](50) NULL,
	[ship_addr1] [varchar](50) NULL,
	[ship_addr2] [varchar](50) NULL,
	[ship_city] [varchar](30) NULL,
	[ship_state] [varchar](30) NULL,
	[ship_postal] [varchar](15) NULL,
	[default_shpmth] [varchar](20) NULL
	) ON [PRIMARY]
	GRANT ALL ON dbo.cvo_eyerep_actshp_tbl TO PUBLIC
	end


truncate table cvo_eyerep_actshp_tbl

INSERT INTO dbo.cvo_eyerep_actshp_tbl
        ( ship_id ,
          acct_id ,
          ship_name ,
          ship_addr1 ,
          ship_addr2 ,
          ship_city ,
          ship_state ,
          ship_postal ,
          default_shpmth
        )
SELECT ar.customer_code+'-'+ar.ship_to_code,
 ar.customer_code , 
LEFT(addr1,50) as ship_name,
LEFT(addr2,50) as ship_street,
LEFT(CASE WHEN addr3 LIKE '%, __ %' THEN '' ELSE ADDR3 END,50) AS ship_street2,
LEFT(city,30) as ship_city,
LEFT(state,30) as ship_state,
LEFT(postal_code,15) as ship_postcode,
LEFT(ar.ship_via_code,15)

-- INTO cvo_eyerep_acts_tbl
FROM armaster ar (nolock)
INNER JOIN #allterr (nolock) on ar.customer_code = #allterr.customer_code
WHERE 1=1
AND STATUS_TYPE=1
AND ADDRESS_TYPE=1

-- account extension data
-- 7/26/2016

IF(OBJECT_ID('dbo.cvo_eyerep_actext_tbl') is null)
	begin
	CREATE TABLE [dbo].[cvo_eyerep_actext_tbl](
	[acct_id] [varchar](20) NOT NULL,
	[field_name] [varchar](50) NULL,
	[field_value] [varchar](200) NULL,
	[display_order] INT NULL,
	[rep_id] [varchar](20) NULL,
	) ON [PRIMARY]
	GRANT ALL ON dbo.cvo_eyerep_actext_tbl TO PUBLIC
	end


truncate table cvo_eyerep_actext_tbl

INSERT INTO dbo.cvo_eyerep_actext_tbl
        ( acct_id ,
		  field_name,
		  field_value,
		  display_order,
		  rep_id
        )
SELECT  ar.customer_code , 
	'DISCOUNT CODE' field_name,
	ISNULL(AR.PRICE_CODE,'Unknown') field_value,
	1 display_order,
	'' rep_id
	FROM armaster ar (nolock)
	INNER JOIN #allterr (nolock) on ar.customer_code = #allterr.customer_code
	WHERE ar.address_type = 0
UNION ALL
SELECT  ar.customer_code , 
	'PRIMARY DESIGNATION' field_name,
	dc.description field_value,
	2 display_order,
	'' rep_id
	FROM armaster ar (nolock)
	INNER JOIN #allterr (nolock) on ar.customer_code = #allterr.customer_code
	INNER JOIN dbo.cvo_cust_designation_codes AS cdc ON cdc.customer_code = ar.customer_code AND CDC.primary_flag = 1
	INNER JOIN dbo.cvo_designation_codes AS dc ON dc.code = cdc.code
	WHERE ar.address_type = 0
UNION ALL
SELECT  ar.customer_code , 
	'BUYING GROUP' field_name,
	bg.address_name field_value,
	3 display_order,
	'' rep_id
	FROM armaster ar (nolock)
	INNER JOIN #allterr (nolock) on ar.customer_code = #allterr.customer_code
	INNER JOIN ARNAREL AS NA ON NA.CHILD = ar.customer_code AND NA.CHILD <> NA.parent
	INNER JOIN armaster bg ON bg.customer_code = na.parent
	WHERE ar.address_type = 0
UNION ALL
SELECT  ar.customer_code , 
	'STATUS' field_name,
	CASE WHEN AR.status_type = 1 THEN 'Active'
		 WHEN ar.status_type = 2 THEN 'Inactive'
		 WHEN ar.status_type = 3 THEN 'No New Business'
		 ELSE 'Unknown' END
		 AS  field_value,
	4 display_order,
	'' rep_id
	FROM armaster ar (nolock)
	INNER JOIN #allterr (nolock) on ar.customer_code = #allterr.customer_code
	WHERE ar.address_type = 0
UNION ALL
SELECT  ar.customer_code , 
	'OPEN DATE' field_name,
	CONVERT(VARCHAR(10), DBO.adm_format_pltdate_f(AR.date_opened), 101)  field_value,
	5 display_order,
	'' rep_id
	FROM armaster ar (nolock)
	INNER JOIN #allterr (nolock) on ar.customer_code = #allterr.customer_code
	WHERE ar.address_type = 0

-- rx % and st %

IF(OBJECT_ID('dbo.cvo_eyerep_actsls_tbl') is null)
	begin
	CREATE TABLE [dbo].[cvo_eyerep_actsls_tbl](
	[acct_id] [varchar](20) NOT NULL,
	[TY_ytd_sales] NUMERIC NULL,
	LY_ytd_sales numeric NULL,
	ty_r12_sales NUMERIC NULL,
	LY_r12_sales numeric NULL,
	aging30 NUMERIC NULL,
	aging60 NUMERIC NULL,
	aging90 NUMERIC NULL
	) ON [PRIMARY]
	GRANT ALL ON dbo.cvo_eyerep_actsls_tbl TO PUBLIC
	end

TRUNCATE table cvo_eyerep_actsls_tbl

DECLARE @tystart DATETIME, @tyend DATETIME, 
		@lystart DATETIME, @lyend DATETIME,
		@tyr12start DATETIME, 
		@lyr12start DATETIME
		
SELECT @tystart = drv.BeginDate , @tyend = drv.enddate FROM dbo.cvo_date_range_vw AS drv WHERE period = 'Year to Date'
SELECT @lystart = drv.BeginDate , @lyend = drv.enddate FROM dbo.cvo_date_range_vw AS drv WHERE period = 'Last Year to Date'
SELECT @tyr12start = drv.BeginDate FROM dbo.cvo_date_range_vw AS drv WHERE period = 'Rolling 12 TY'
SELECT @lyr12start = drv.BeginDate from dbo.cvo_date_range_vw AS drv WHERE period = 'Rolling 12 LY'


INSERT INTO dbo.cvo_eyerep_actsls_tbl
        ( acct_id ,
		TY_ytd_sales,
		LY_ytd_sales,
		ty_r12_sales,
		LY_r12_sales,
		aging30,
		aging60,
		aging90
        )
SELECT  eat.acct_id , 
	SUM(ISNULL(CASE WHEN yyyymmdd BETWEEN @tystart AND @tyend THEN anet ELSE 0 END,0)) ty_ytd_sales,
	SUM(ISNULL(CASE WHEN yyyymmdd BETWEEN @lystart AND @lyend THEN anet ELSE 0 END,0)) ly_ytd_sales,
	SUM(ISNULL(CASE WHEN yyyymmdd BETWEEN @tyr12start AND @tyend THEN anet ELSE 0 END,0)) ty_r12_sales,
	SUM(ISNULL(CASE WHEN yyyymmdd BETWEEN @lyr12start AND @lyend THEN anet ELSE 0 END,0)) ly_r12_sales,
	0 aging30,
	0 aging60,
	0 aging90
	FROM dbo.cvo_eyerep_acts_Tbl AS eat
	JOIN cvo_sbm_details sbm ON sbm.customer = eat.acct_id
	WHERE sbm.yyyymmdd BETWEEN @lyr12start AND @tyend
	GROUP BY eat.acct_id


-- get LIST FOR invoice terms

IF(OBJECT_ID('dbo.cvo_eyerep_biltrm_tbl') is null)
	begin
	CREATE TABLE [dbo].[cvo_eyerep_biltrm_tbl](
	biltrm_id VARCHAR(20) NOT NULL,
	biltrm_description VARCHAR(30) null
	) ON [PRIMARY]
	GRANT ALL ON dbo.cvo_eyerep_biltrm_tbl TO PUBLIC
	end

truncate table cvo_eyerep_biltrm_tbl

INSERT INTO dbo.cvo_eyerep_biltrm_tbl
        ( biltrm_id,
		  biltrm_description
        )
SELECT a.terms_code, a.terms_desc
FROM dbo.arterms AS a (nolock)
WHERE 1=1

-- Get Inventory master info

IF(OBJECT_ID('dbo.cvo_eyerep_inv_tbl') is null)
	begin
	CREATE TABLE [dbo].[cvo_eyerep_inv_tbl](
		[sku] [varchar](50) NOT NULL,
		[upc] [varchar](50) NULL,
		[collection_id] [varchar](50) NULL,
		[style] [varchar](20) NULL,
		[color] [varchar](20) NULL,
		[eye_size] [varchar](3) NULL,
		[temple] [varchar](3) NULL,
		[bridge] [varchar](3) NULL,
		[product_rank] [int] NULL,
		[collection_rank] [int] NULL,
		[product_type] [varchar](20) NULL,
		[avail_status] [varchar](30) NULL,
		[avail_date] [varchar](8) NULL,
		[base_price] [decimal](9, 2) NULL,
		[new_release] [char](1) NULL
	) ON [PRIMARY]
	GRANT ALL ON dbo.cvo_eyerep_inv_tbl TO PUBLIC
	end

	TRUNCATE TABLE dbo.cvo_eyerep_inv_tbl

	INSERT INTO dbo.cvo_eyerep_inv_tbl
	        ( sku ,
	          upc ,
	          collection_id ,
	          style ,
	          color ,
	          eye_size ,
			  temple ,
	          bridge ,
	          product_rank ,
	          collection_rank ,
	          product_type ,
	          avail_status ,
	          avail_date ,
	          base_price ,
	          new_release
	        )
SELECT part_no,
upc_code,
[Collection],
LEFT(model,20),
LEFT(ColorName,20),
CAST (cast(eye_size as int) AS varchar(3)),
CAST (temple_size AS VARCHAR(3)),
CAST (dbl_size AS VARCHAR(3)),
0,
0,
LEFT(RES_type,20),
'avail',
CONVERT(VARCHAR(8),GETDATE(),112),
Wholesale_price,
'N'

FROM cvo_inv_master_r2_vw 
WHERE 1=1

-- Collections

IF(OBJECT_ID('dbo.cvo_eyerep_invcol_tbl') is null)
	begin
CREATE TABLE [dbo].[cvo_eyerep_invcol_tbl](
	[collection_id] [varchar](50) NOT NULL,
	[collection_name] [varchar](30) NULL
) ON [PRIMARY]
END

TRUNCATE TABLE dbo.cvo_eyerep_invcol_tbl

INSERT dbo.cvo_eyerep_invcol_tbl
        ( collection_id, collection_name )
SELECT DISTINCT kys, description  
FROM dbo.category AS c 
WHERE ISNULL(c.void,'N') = 'N'

-- Order types

IF(OBJECT_ID('dbo.cvo_eyerep_ordtyp_tbl') is null)
	begin
CREATE TABLE [dbo].[cvo_eyerep_ordtyp_tbl](
	[ordtyp_id] [varchar](20) NOT NULL,
	[ordtyp_description] [varchar](30) NULL
) ON [PRIMARY]
END

TRUNCATE TABLE dbo.cvo_eyerep_ordtyp_tbl

INSERT dbo.cvo_eyerep_ordtyp_tbl
        ( ordtyp_id, ordtyp_description )
SELECT DISTINCT promo_id+','+promo_level, c.promo_name  
FROM cvo_promotions AS c 
WHERE ISNULL(c.void,'N') = 'N'
AND c.promo_start_date <= GETDATE() AND c.promo_end_date >= GETDATE()


-- Sales Reps


IF(OBJECT_ID('dbo.cvo_eyerep_rp_tbl') is null)
	begin
CREATE TABLE [dbo].[cvo_eyerep_rp_tbl](
	[rep_id] [VARCHAR](20) NOT NULL,
	[rep_type] [VARCHAR](10) NULL,
	[user_name] [VARCHAR](100) NULL,
	[user_password] [VARCHAR](20) NULL,
	[first_name] [VARCHAR](20) NULL,
	[last_name] [VARCHAR](20) NULL,
	[email_address] [VARCHAR](100) NULL
) ON [PRIMARY]
END

TRUNCATE TABLE dbo.cvo_eyerep_rp_tbl

INSERT dbo.cvo_eyerep_rp_tbl
        ( rep_id ,
          rep_type ,
          user_name ,
          user_password ,
          first_name ,
          last_name ,
          email_address
        )
SELECT DISTINCT a.territory_code,
a.territory_code,
a.salesperson_code,
'eyerepcvo',
LEFT(LEFT(salesperson_name, CHARINDEX(' ', salesperson_name)-1),20),
LEFT(SUBSTRING(salesperson_name, CHARINDEX(' ',salesperson_name) + 1, LEN(salesperson_name)),20),
LEFT(a.slp_email,100)
FROM dbo.cvo_sc_addr_vw AS a 
-- testing
WHERE a.territory_code IN  ('20206','70778', '50503', '40440','40456')

END

-- rep accounts

IF(OBJECT_ID('dbo.cvo_eyerep_rpact_tbl') is null)
	begin
CREATE TABLE [dbo].[cvo_eyerep_rpact_tbl](
	[rep_id] [varchar](20) NULL,
	[acct_id] [varchar](20) NULL
) ON [PRIMARY]
END

TRUNCATE TABLE dbo.cvo_eyerep_rpact_tbl

INSERT dbo.cvo_eyerep_rpact_tbl
        ( rep_id, acct_id )
SELECT DISTINCT ar.territory_code, ar.customer_code 
FROM armaster ar (nolock)
INNER JOIN #allterr (nolock) on ar.customer_code = #allterr.customer_code
WHERE 1=1
AND STATUS_TYPE=1
AND ADDRESS_TYPE=0
AND EXISTS ( SELECT 1 FROM dbo.cvo_eyerep_rp_tbl AS cert WHERE cert.rep_id = ar.territory_code)

-- rep account ship addresses

IF(OBJECT_ID('dbo.cvo_eyerep_rpashp_tbl') is null)
	begin
CREATE TABLE [dbo].[cvo_eyerep_rpashp_tbl](
	[rep_id] [varchar](20) NOT NULL,
	[ship_id] [varchar](20) NOT NULL,
	[acct_id] [varchar](20) NOT NULL
) ON [PRIMARY]
END

TRUNCATE TABLE dbo.cvo_eyerep_rpashp_tbl

INSERT dbo.cvo_eyerep_rpashp_tbl
        ( rep_id, ship_id, acct_id )
SELECT DISTINCT ar.territory_code, ar.customer_code+'-'+ar.ship_to_code, ar.customer_code
FROM armaster ar (nolock)
INNER JOIN #allterr (nolock) on ar.customer_code = #allterr.customer_code
WHERE 1=1
AND STATUS_TYPE=1
AND ADDRESS_TYPE=1


IF(OBJECT_ID('dbo.cvo_eyerep_repext_tbl') is null)
	begin
	CREATE TABLE [dbo].[cvo_eyerep_repext_tbl](
	[rep_id] [varchar](20) NOT NULL,
	[field_name] [varchar](50) NULL,
	[field_value] [varchar](200) NULL,
	[display_order] INT NULL,
	) ON [PRIMARY]
	GRANT ALL ON dbo.cvo_eyerep_repext_tbl TO PUBLIC
	end


truncate table cvo_eyerep_repext_tbl
DECLARE @stat_year VARCHAR(5)
SELECT @stat_year = CAST(YEAR(GETDATE()) AS VARCHAR(4))+'A'

INSERT INTO dbo.cvo_eyerep_repext_tbl
        ( rep_id ,
		  field_name,
		  field_value,
		  display_order
        )
SELECT  ts.territory_code,
	'% over/under LY' field_name,
	ISNULL(CAST(ts.ly_ty_sales_incr_pct*100 AS VARCHAR(20)),'Unknown') field_value,
	1 display_order
	FROM dbo.cvo_terr_scorecard AS ts (nolock) 
	WHERE EXISTS (SELECT 1 FROM #allterr WHERE ts.Territory_Code = #AllTerr.AllTerr)
	AND ts.Stat_Year = @stat_year
UNION ALL
SELECT  ts.territory_code,
	'RX %' field_name,
	ISNULL(CAST(ts.ty_rx_pct*100 AS VARCHAR(20)),'Unknown') field_value,
	2 display_order
	FROM dbo.cvo_terr_scorecard AS ts (nolock) 
	WHERE EXISTS (SELECT 1 FROM #allterr WHERE ts.Territory_Code = #AllTerr.AllTerr)
	AND ts.Stat_Year = @stat_year
UNION ALL
SELECT  ts.territory_code,
	'Doors >500' field_name,
	ISNULL(CAST(ts.doors_500 AS VARCHAR(20)),'Unknown') field_value,
	3 display_order
	FROM dbo.cvo_terr_scorecard AS ts (nolock) 
	WHERE EXISTS (SELECT 1 FROM #allterr WHERE ts.Territory_Code = #AllTerr.AllTerr)
	AND ts.Stat_Year = @stat_year
UNION ALL
SELECT  ts.territory_code,
	'Doors >2400' field_name,
	ISNULL(CAST(ts.activedoors_2400 AS VARCHAR(20)),'Unknown') field_value,
	4 display_order
	FROM dbo.cvo_terr_scorecard AS ts (nolock) 
	WHERE EXISTS (SELECT 1 FROM #allterr WHERE ts.Territory_Code = #AllTerr.AllTerr)
	AND ts.Stat_Year = @stat_year


-- ship methods

IF(OBJECT_ID('dbo.cvo_eyerep_shpmth_tbl') is null)
	begin

CREATE TABLE [dbo].[cvo_eyerep_shpmth_tbl](
	[shpmth_id] [varchar](20) NOT NULL,
	[shpmth_name] [varchar](30) NOT NULL
) ON [PRIMARY]
END

TRUNCATE TABLE dbo.cvo_eyerep_shpmth_tbl

INSERT dbo.cvo_eyerep_shpmth_tbl
        ( shpmth_id, shpmth_name )
SELECT DISTINCT ar.ship_via_code, ar.ship_via_code
FROM dbo.armaster AS ar
WHERE ISNULL(ar.ship_via_code,'') > ''
AND ar.address_type <> 9


IF(OBJECT_ID('dbo.cvo_eyerep_promocodes_tbl') is null)
	begin
CREATE TABLE [dbo].[cvo_eyerep_promocodes_tbl](
	[promo_id] [varchar](20) NOT NULL,
	[promo_description] [varchar](50) NULL
) ON [PRIMARY]
END

TRUNCATE TABLE dbo.cvo_eyerep_promocodes_tbl

INSERT dbo.cvo_eyerep_promocodes_tbl
        ( promo_id, promo_description )
SELECT promo_id+','+promo_level, promo_name
FROM cvo_promotions WHERE GETDATE() BETWEEN ISNULL(promo_start_date,GETDATE()) AND ISNULL(promo_end_date,GETDATE())

IF(OBJECT_ID('dbo.cvo_eyerep_acthis_tbl') is null)
	begin
CREATE TABLE [dbo].[cvo_eyerep_acthis_tbl](
	[account_id] [varchar](20) NOT NULL,
	ship_id [varchar](20) NULL,
	ORDER_no VARCHAR(20) NOT NULL,
	tax_amt DECIMAL(9,2) NOT NULL,
	ship_amt DECIMAL(9,2) NOT NULL,
	WebOrderNumber VARCHAR(13) NULL,
	Invoice_no VARCHAR(30) NULL,
	upc VARCHAR(50) NULL,
	quantity DECIMAL(9,2) NOT NULL,
	price DECIMAL(9,2) NOT NULL, -- extended price
	ship_date VARCHAR(8) NULL,
	ORDER_status VARCHAR(30) NULL,
	order_date VARCHAR(8)  NULL,
	tracking_no VARCHAR(50) NULL,
	tracking_type VARCHAR(50) NULL,
	order_type VARCHAR(20) NULL,
	line_no VARCHAR(30) NULL
	) ON [PRIMARY]
END


TRUNCATE TABLE cvo_eyerep_acthis_tbl

DECLARE @date INTEGER
SELECT  @date = dbo.adm_get_pltdate_f(DATEADD(year,-1,GETDATE()))
-- SELECT @date

-- regular invoices

INSERT INTO cvo_eyerep_acthis_tbl
select
customer = isnull(xx.customer_code,''),
ship_to = CASE WHEN xx.ship_to_code <> '' THEN xx.customer_code+'-'+xx.ship_to_code ELSE '' end, 
xx.order_ctrl_num,
xx.amt_tax, xx.amt_net, 
'' AS WebOrderNumber,
xx.doc_ctrl_num,
isnull(i.upc_code,'0000000000000') AS upc_code,
ol.shipped - ol.cr_shipped,
case o.type when 'i' then 
	case isnull(cl.is_amt_disc,'n')
		when 'y' then round (ol.shipped * (ol.curr_price - ROUND(ISNULL(cl.amt_disc,0),2)),2,1)
		ELSE ROUND( ol.shipped * (ol.curr_price - ROUND(ol.curr_price*(ol.discount/100.00),2)) ,2) 
	end
else 0
end as asales,
CONVERT(VARCHAR(8), dbo.adm_format_pltdate_f(xx.date_applied), 112), -- yyyymmdd
'Shipped/Transferred' AS order_status, 
CONVERT(VARCHAR(8), oo.date_entered, 112),
ISNULL(ctn.tracking,'') tracking, 
ISNULL(ctn.tracking_type,'') tracking_type, 
o.user_category, 
ol.display_line

from #allterr
	JOIN orders o (nolock) ON o.cust_code = #allterr.customer_code
	inner join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext
	inner join ord_list ol (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
	left outer join cvo_ord_list cl (nolock) on cl.order_no = ol.order_no and cl.order_ext = ol.order_ext
		and cl.line_no = ol.line_no
left outer join orders_invoice oi (nolock) on oi.order_no = o.order_no and oi.order_ext = o.ext
left outer join artrx xx (nolock) on xx.trx_ctrl_num = oi.trx_ctrl_num

left outer join 
(select order_no, min(ooo.date_entered) from orders ooo(nolock) where ooo.status <> 'v' group by ooo.order_no)
as oo (order_no, date_entered) on oo.order_no = o.order_no
-- tag 013114
left outer join inv_master i on i.part_no = ol.part_no

LEFT OUTER JOIN
( SELECT order_no, order_ext, MIN(ISNULL(c.cs_tracking_no,c.carton_no)) tracking, MIN(c.carrier_code) tracking_type
FROM tdc_carton_tx c  
GROUP BY c.order_no, c.order_ext 
) ctn ON ctn.order_ext = o.ext AND ctn.order_no = o.order_no


where 1=1
AND EXISTS ( SELECT 1 FROM cvo_eyerep_acts_tbl a WHERE a.acct_id = #AllTerr.customer_code )
and xx.date_applied > @date
and xx.trx_type in (2031,2032) 
and xx.doc_desc not like 'converted%' and xx.doc_desc not like '%nonsales%' 
and xx.doc_ctrl_num not like 'cb%' and xx.doc_ctrl_num not like 'fin%'
and xx.void_flag = 0 and xx.posted_flag = 1
AND o.user_category NOT LIKE ('%-RB')
AND i.type_code IN ('frame','sun')
AND 0 <> (ol.shipped - ol.cr_shipped) 


-- backorders
-- backord.txt

IF(OBJECT_ID('dbo.cvo_eyerep_backord_tbl') is null)
	begin
CREATE TABLE [dbo].[cvo_eyerep_backord_tbl](
	[account_id] [varchar](20) NOT NULL,
	ship_id [varchar](20) NULL,
	ORDER_no VARCHAR(20) NOT NULL,
	tax_amt DECIMAL(9,2) NOT NULL,
	ship_amt DECIMAL(9,2) NOT NULL,
	WebOrderNumber VARCHAR(13) NULL,
	Invoice_no VARCHAR(30) NULL,
	upc VARCHAR(50) NULL,
	quantity DECIMAL(9,2) NOT NULL,
	price DECIMAL(9,2) NOT NULL, -- extended price
	ship_date VARCHAR(8) NULL,
	ORDER_status VARCHAR(30) NULL,
	order_date VARCHAR(8)  NULL,
	tracking_no VARCHAR(50) NULL,
	tracking_type VARCHAR(50) NULL,
	order_type VARCHAR(20) NULL,
	line_no VARCHAR(30) NULL
	) ON [PRIMARY]
END


TRUNCATE TABLE dbo.cvo_eyerep_backord_tbl
INSERT INTO dbo.cvo_eyerep_backord_tbl
        ( account_id ,
          ship_id ,
          ORDER_no ,
          tax_amt ,
          ship_amt ,
          WebOrderNumber ,
          Invoice_no ,
          upc ,
          quantity ,
          price ,
          ship_date ,
          ORDER_status ,
          order_date ,
          tracking_no ,
          tracking_type ,
          order_type ,
          line_no
        )
select 
o.cust_code account_id,
CASE WHEN o.ship_to > '' THEN o.cust_code+'-'+o.ship_to ELSE '' END ship_address_id,
o.order_no,
0 AS tax_amount,
0 AS ship_amount,
o.user_def_fld4 webordernumber,
'' AS invoicenumber,
inv.upc_code upc,
ol.ordered - ol.shipped quantity,
ol.curr_price,
CONVERT(VARCHAR(8), o.sch_ship_date, 112) shipdate,
'BACKORDERED' orderstatus,
CONVERT(VARCHAR(8), o.date_entered, 112) orderdate,
'' trackingnumber,
'' trackingtype,
o.user_category ordertype,
ol.line_no lineuniqueid

From inv_master inv  (nolock)
inner join ord_list ol (nolock) on inv.part_no = ol.part_no
inner join orders o (nolock) on o.order_no = ol.order_no and o.ext = ol.order_ext
left outer join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext 
left outer join cvo_promotions p (nolock) on p.promo_id = co.promo_id and p.promo_level = co.promo_level
-- 3/4/15
left outer join cvo_hard_allocated_vw e (nolock) on
	e.order_no = o.order_no 
	and e.order_ext = o.ext 
	and e.line_no = ol.line_no
	and e.order_type = 's'
where 1=1 
AND o.cust_code IN (SELECT DISTINCT customer_code FROM #allterr)
AND o.type = 'i'
AND inv.type_code IN ('frame','sun')
and ol.status < 'P' 
AND o.status < 'p'
and ol.ordered > (ol.shipped + isnull(e.qty,0))
-- and o.sch_ship_date < @today
and ol.part_type = 'p'
AND o.who_entered = 'backordr'


GO

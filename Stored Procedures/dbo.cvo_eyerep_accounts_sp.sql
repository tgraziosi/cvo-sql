SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		TG
-- Create date: 2/22/2016
-- Description:	EyeRep Main Customer Data
-- EXEC [cvo_eyerep_accounts_sp]
-- SELECT * From cvo_eyerep_actshp_tbl
-- 
-- tag - 071213 - create a regular table instead of temp table
-- tag - 8/21/2015 - add sales rep customer accounts
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
			   AND territory_code IN ('20206','40456', '50503', '40440') -- phil, bob s, dave s, kerry c
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


-- PULL LIST FOR CUSTOMERS
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
WHERE a.territory_code IN  ('20206','40456', '50503', '40440')

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

GO

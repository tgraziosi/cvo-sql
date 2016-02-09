
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- TAG - write to work table for commission statement Automation
-- exec   cvo_commission_bldr_sp '12/1/2015', '12/31/2015'
-- select * From cvo_commission_bldr_work_tbl

CREATE PROCEDURE [dbo].[cvo_commission_bldr_sp]
  @df DATETIME 
, @dt DATETIME 
, @t VARCHAR(1024) = null

 AS
 BEGIN

SET NOCOUNT ON
   
DECLARE @jdatefrom INT, @jdateto INT
SELECT @jdatefrom = dbo.adm_get_pltdate_f(@df)
SELECT @jdateto = dbo.adm_get_pltdate_f(@dt)

CREATE TABLE #territory ([territory] VARCHAR(10))

if @t is null
begin
	insert #territory
	select distinct territory_code from armaster where territory_code is not null
end
else
begin
	INSERT INTO #territory ([territory])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@t)
end


-- DROP TABLE dbo.cvo_commission_bldr_work_tbl

IF(OBJECT_ID('cvo.dbo.cvo_commission_bldr_work_tbl') is null)
BEGIN
	CREATE TABLE [dbo].[cvo_commission_bldr_work_tbl]
	(
	[Salesperson] [varchar] (10) NOT NULL,
	[Territory] [varchar] (10) NOT NULL,
	[Cust_code] [varchar] (8) NOT NULL,
	[Ship_to] [varchar] (8) NOT NULL,
	[Name] [varchar] (40) NULL,
	[Order_no] [int] NULL,
	[Ext] [int] NULL,
	[Invoice_no] [varchar] (10)  NULL,
	[InvoiceDate] [int] NOT NULL,
	[DateShipped] [int] NOT NULL,
	[OrderType] [varchar] (10) NULL,
	[Promo_id] [varchar] (20) NOT NULL,
	[Level] [varchar] (30)  NOT NULL,
	[type] [varchar] (3) NOT NULL,
	[Net_Sales] [FLOAT] NULL,
	[Amount] [float] NULL,
	[Comm_pct] [decimal] (5, 2) NULL,
	[Comm_amt] [float] NULL,
	[Loc] [varchar] (8) NOT NULL,
	[salesperson_name] [varchar] (40) NULL,
	[HireDate] [varchar] (30) NOT NULL,
	[draw_amount] [decimal] (14, 2) NULL,
	[invoicedate_dt] [datetime] NOT NULL,
	[dateshipped_dt] [datetime] NOT NULL,
	[fiscal_period] VARCHAR(10) NOT NULL,
	[added_date] [datetime] NOT NULL,
	[added_by] [nvarchar] (128)  NULL,
	[id] [bigint] NOT NULL PRIMARY KEY
	) ON [PRIMARY]
END

TRUNCATE TABLE dbo.cvo_commission_bldr_work_tbl

DECLARE @tbl_rows int
SELECT @tbl_rows = ISNULL(MAX(id),0) FROM cvo_commission_bldr_work_tbl

INSERT INTO cvo_commission_bldr_work_tbl (
Salesperson ,
       Territory ,
       Cust_code ,
       Ship_to ,
       Name ,
       Order_no ,
       Ext ,
       Invoice_no ,
       InvoiceDate ,
       DateShipped ,
       OrderType ,
       Promo_id ,
       Level ,
       type ,
	   Net_Sales,
       Amount ,
       comm_pct,
       comm_amt,
       Loc ,
       salesperson_name ,
       HireDate ,
       draw_amount
, InvoiceDate_dt 
, DateShipped_dt 
, fiscal_period
, added_date 
, added_by 
, id )
SELECT Salesperson ,
       t.Territory ,
       Cust_code ,
       Ship_to ,
       Name ,
       Order_no ,
       Ext ,
       Invoice_no ,
       InvoiceDate ,
       DateShipped ,
       OrderType ,
       Promo_id ,
       Level ,
       type ,
	   c.Net_Sales,
       Amount ,
       [Comm%] comm_pct,
       [Comm$] comm_amt,
       Loc ,
       salesperson_name ,
       HireDate ,
       draw_amount
, InvoiceDate_dt = dbo.adm_format_pltdate_f(invoicedate)
, DateShipped_dt = dbo.adm_format_pltdate_f(dateshipped)
, fiscal_period = CAST(MONTH(dbo.adm_format_pltdate_F(invoicedate)) AS varchar(2))+'/'+
				  CAST(YEAR(dbo.adm_format_pltdate_f(invoicedate)) AS varchar(4))
, added_date = GETDATE()
, added_by = SYSTEM_USER
, id = ROW_NUMBER() OVER (ORDER BY Invoice_no) + @tbl_rows
FROM #territory t
INNER JOIN cvo_commission_bldr_vw c ON c.Territory = t.territory
WHERE invoicedate BETWEEN @jdatefrom AND @jdateto

END
GO

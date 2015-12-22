SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- TAG - write to work table for commission statement Automation
-- exec   cvo_commission_bldr_sp '6/1/2015', '6/12/2015', '20202'

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

DECLARE @tbl_rows int
SELECT @tbl_rows = MAX(id) FROM cvo_commission_bldr_work_tbl

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
       Amount ,
       comm_pct,
       comm_amt,
       Loc ,
       salesperson_name ,
       HireDate ,
       draw_amount
, InvoiceDate_dt 
, DateShipped_dt 
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
       Amount ,
       [Comm%] comm_pct,
       [Comm$] comm_amt,
       Loc ,
       salesperson_name ,
       HireDate ,
       draw_amount
, InvoiceDate_dt = dbo.adm_format_pltdate_f(invoicedate)
, DateShipped_dt = dbo.adm_format_pltdate_f(dateshipped)
, added_date = GETDATE()
, added_by = SYSTEM_USER
, id = ROW_NUMBER() OVER (ORDER BY Invoice_no) + @tbl_rows
FROM #territory t
INNER JOIN cvo_commission_bldr_vw c ON c.Territory = t.territory
WHERE invoicedate BETWEEN @jdatefrom AND @jdateto

END
GO

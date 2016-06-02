SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_magento_get_price_sp] @customer VARCHAR(10) = null, @ship_to VARCHAR(10) = '', 
										 @part_no VARCHAR(30) = null, @location VARCHAR(10) = '001'
AS 
/*
usage:
	exec cvo_magento_Get_price_sp '033228', '', 'asexpcoc5416'
*/

BEGIN
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

IF @location IS NULL SELECT @location = '001'
IF @ship_to IS NULL SELECT @ship_to = ''

if not exists (select 1 from armaster where customer_code = @customer and ship_to_code = @ship_to)
begin
	select -1 price , 'Invalid Customer' errmsg
	RETURN(1)
end

if not exists (select 1 from inv_master where part_no = @part_no)
begin
	select -1 price , 'Invalid Part' errmsg
	RETURN(2)
end

-- SELECT @customer = '033228', @ship_to = '', @part_no = 'cvmerilil5116', @location = '001'

IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t

CREATE TABLE #t (plevel VARCHAR(1),
 price FLOAT, 
 nextqty FLOAT, 
 nextprice FLOAT, 
 promo FLOAT, 
 sales_comm FLOAT, 
 qloop INT, 
 qlevel INT, 
 curr_key VARCHAR(3))

INSERT INTO #t 
EXEC dbo.fs_get_price @cust = @customer, @shipto = @ship_to, @clevel = '1', 
	 @pn = @part_no, @loc = @location, @plevel = '1',
	 @qty = 1, @pct = 0, @curr_key = 'USD', @curr_factor = 1, @svc_agr = 'N'  

if @@rowcount = 0
begin
	select -1 price, 'Price NOT FOUND' errmsg
	RETURN(3)
end

SELECT TOP 1 ISNULL(price,-1) price , 'OK' errmsg FROM #t
IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t

RETURN (0)

END

GO
GRANT EXECUTE ON  [dbo].[cvo_magento_get_price_sp] TO [public]
GO

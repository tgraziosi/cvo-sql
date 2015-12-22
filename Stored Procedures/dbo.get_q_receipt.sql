SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_receipt] 	@strsort varchar(50), @sort char(1), @last_key varchar(50)
AS

declare @start_int int, @strsort_int int, @sql varchar(4000)
set @start_int = 0
set @strsort_int = 0

set @strsort = isnull(@strsort,'')

if patindex('%[^0-9]%',@last_key) = 0
	set @start_int = isnull(convert(int, @last_key),0)
if patindex('%[^0-9]%',@strsort) = 0
	set @strsort_int = isnull(convert(int, @strsort),0)

if @sort='B'
begin
set @sql = 'select 	distinct (receipt_batch_no), NULL, vendor, vendor_name
	from receipts (NOLOCK), adm_vend_all (NOLOCK)
	where vendor = vendor_code 
    and isnull(receipt_batch_no,0) >= ' + convert(varchar(10), @strsort_int) + '
    and isnull(receipt_batch_no,0) > ' + convert(varchar(10), @start_int) + '
	order by receipt_batch_no'
end

if @sort='R'
begin
set @sql = 'select 	receipt_batch_no, receipt_no, vendor, vendor_name
	from 	receipts (NOLOCK), adm_vend_all (NOLOCK)
	where 	vendor = vendor_code  
    and receipt_no >= ' + convert(varchar(10), @strsort_int) + '
    and receipt_no > ' + convert(varchar(10), @start_int) + '
	order by receipt_no'
end

if @sort='V'
begin
set @sql = 'select 	distinct (receipt_batch_no), NULL, vendor, vendor_name
	from 	receipts (NOLOCK), adm_vend_all (NOLOCK)
	where 	vendor = vendor_code and vendor >= ''' + @strsort + '''
	and	isnull(receipt_batch_no,0) > ' + convert(varchar(10), @start_int) + '
	order by vendor'
end

set rowcount 100
exec (@sql)
set rowcount 0
GO
GRANT EXECUTE ON  [dbo].[get_q_receipt] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_po_auto_order_wrap] @row_id int
as

declare @rc int, @lrow int, @err int, @ord int, @ext int 
declare @msg varchar(255)

begin tran
EXEC @err = adm_po_auto_order @row_id, @ord out , @ext out , @msg OUT

if @err <> 1
  rollback tran
else
begin
  commit tran

  if @ext > 0 
    select @msg = 'Created blanket sales order ' + convert(varchar,@ord) + ' with ' + convert(varchar,@ext) + ' releases'
  else
    select @msg = 'Created sales order ' + convert(varchar,@ord) + '- ' + convert(varchar,@ext)
end

select @ord, @ext, @err, @msg
return 1
GO
GRANT EXECUTE ON  [dbo].[adm_po_auto_order_wrap] TO [public]
GO

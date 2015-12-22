SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_post_ar_cancel_tax] @err_msg varchar(255) OUT,
  @trx_ctrl_num varchar(16) = '', @trx_type int = 0
AS 
set nocount on
----------------------------------------------------------------------------------------------------------------------------------------------
declare @rc int,  @msg varchar(255)

----------------------------------------------------------------------------------------------------------------------------------------------
select @rc = 1, @err_msg = ''

if @trx_ctrl_num = ''
begin
  DECLARE orders_cursor CURSOR LOCAL STATIC FOR
  SELECT o.trx_ctrl_num, o.trx_type
  from #orders o

  OPEN orders_cursor

  FETCH NEXT FROM orders_cursor into @trx_ctrl_num, @trx_type

  While @@FETCH_STATUS = 0
  begin
    exec @rc = TXavataxlink_upd_sp @trx_ctrl_num, @trx_type, 'DELETE', @msg out
    if @rc < 1 
      select @err_msg = @msg
    FETCH NEXT FROM orders_cursor into @trx_ctrl_num, @trx_type
  end

  close orders_cursor
  deallocate orders_cursor
end
else
begin
    exec @rc = TXavataxlink_upd_sp @trx_ctrl_num, @trx_type, 'DELETE', @msg out
    if @rc < 1 
      select @err_msg = @msg

    delete from #orders where trx_ctrl_num = @trx_ctrl_num
      and trx_type = @trx_type
end

return @rc
GO
GRANT EXECUTE ON  [dbo].[adm_post_ar_cancel_tax] TO [public]
GO

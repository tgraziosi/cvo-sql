SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_apaprmk_sp] @po_no varchar(16), @online_call int = 1 as
begin
  declare @system_date int

  set @system_date = dbo.adm_get_pltdate_f(getdate())

  delete from apaprtrx where trx_ctrl_num = @po_no and trx_type = 4090

  if exists (select 1 from purchase_all (nolock) where po_no = @po_no and status = 'O')
  begin
    exec apaprmk_sp 4090, @po_no, @system_date
  end
  else
  begin
    update purchase_all
    set approval_flag = 0
    where po_no = @po_no and isnull(approval_flag,1) = 1
  end 

  if @online_call = 1
    select 0
  else
    return 0
end
GO
GRANT EXECUTE ON  [dbo].[adm_apaprmk_sp] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create function [dbo].[adm_inv_org_id_f] ()
  returns varchar(30)
begin
declare @org_id varchar(30)

if exists (select 1 from glco (nolock) where ib_flag = 1)
  set @org_id = isnull((select value_str from config (nolock) where flag = 'INV_ORG_ID'),'')
else
  set @org_id = isnull((select dbo.sm_get_current_org_fn()),'')

return @org_id
end
GO
GRANT REFERENCES ON  [dbo].[adm_inv_org_id_f] TO [public]
GO
GRANT EXECUTE ON  [dbo].[adm_inv_org_id_f] TO [public]
GO

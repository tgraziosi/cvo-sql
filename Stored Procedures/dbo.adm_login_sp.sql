SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_login_sp]
		@user_name varchar(255)='',
		@data_base varchar(30)=''
AS	
  declare @org_id varchar(30), @sm_org_id varchar(30), @org_name varchar(60)
  exec sm_login_sp @user_name, @data_base

  select @sm_org_id = dbo.sm_get_current_org_fn()

--  if not exists (select 1 from glco (nolock) where ib_flag = 1)
--  begin
--    select '', 1, ''
--    return
--  end

  if isnull(@sm_org_id,'') = ''
    select isnull(@sm_org_id,''), -3, '' 	-- default organization needs to be defined

  select @org_id = @sm_org_id

  set @org_name = ''
  if @org_id <> ''
    select @org_name = isnull((select organization_name from Organization_all where organization_id = @org_id),'')

  select @org_id, 1, @org_name  -- connection is OK

GO
GRANT EXECUTE ON  [dbo].[adm_login_sp] TO [public]
GO

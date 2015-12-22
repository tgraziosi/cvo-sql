SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[fvi_new_explview_sp] (@viewname varchar(30), @viewdesc varchar(30))
as
begin
declare @app_id int
declare @form_id int
declare @company_id int

set @app_id = 15000

select @form_id = max(form_id) + 1 from smmenus_vw
where app_id = @app_id

select @company_id = company_id from glco

select 'insert into explview_vw ( AppId, ViewName, ViewNumber ) values ( ' + cast(@app_id as varchar(30)) + ' , ''' + @viewname + ''' , ' + cast(@form_id as varchar(30)) + ' )'
union all
select 'insert into smmenus_vw (app_id, form_id, object_type, form_subid, form_desc) values(' + cast(@app_id as varchar(30)) + ', ' + cast(@form_id as varchar(30)) + ', 1, 0, ''' + @viewdesc + ''')'
union all
select 'insert fvi_smuserperm_vw (user_id, company_id, app_id, form_id, object_type, read_perm, write, user_copy) values( 1, ' + cast(@company_id as varchar(30)) + ', ' + cast(@app_id as varchar(30)) + ', ' + cast(@form_id as varchar(30)) + ', 1, 0, 1, 0)'


insert into explview_vw ( AppId, ViewName, ViewNumber ) values ( @app_id, @viewname, @form_id)
insert into smmenus_vw (app_id, form_id, object_type, form_subid, form_desc) values(@app_id, @form_id, 1, 0, @viewdesc )
insert fvi_smuserperm_vw (user_id, company_id, app_id, form_id, object_type, read_perm, write, user_copy) values( 1, @company_id, @app_id, @form_id, 1, 0, 1, 0)

end
GO

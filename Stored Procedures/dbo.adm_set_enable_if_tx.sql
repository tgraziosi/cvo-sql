SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[adm_set_enable_if_tx] @obj_type varchar(255),@attrib_grp varchar(255), 
@attrib_nm varchar(255), @enable_if_tx varchar(1000) = ''
as

update adm_custom_obj_info
set enable_if_tx = @enable_if_tx
where obj_type = @obj_type and attrib_grp = @attrib_grp and attrib_nm = @attrib_nm
GO
GRANT EXECUTE ON  [dbo].[adm_set_enable_if_tx] TO [public]
GO

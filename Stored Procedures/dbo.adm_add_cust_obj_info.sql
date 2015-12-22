SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adm_add_cust_obj_info] 
@obj_type varchar(255),@attrib_grp varchar(255), 
@attrib_nm varchar(255)  ,@attrib_descr varchar(30)  ,@attrib_typ varchar(10) = '', @attrib_dflt varchar(255) = '',
@attrib_values varchar(255) = '' ,@computable int = 1, @attrib_sub_type varchar(255) = '' ,@attrib_dddw_info varchar(4000) = '' ,
@style_attrib int = -1, @enable_if_tx varchar(1000) = '', @obj_grp varchar(255) = ''
as
if @attrib_sub_type in ('edit','checkbox','checkbox_3','dddw','ddlb','editmask','inkedit','radiobutton')
and @style_attrib = -1
  set @style_attrib = 1

if @style_attrib = -1
  set @style_attrib = 0

if @attrib_typ != 'dddw'
begin
  set @enable_if_tx = @attrib_dddw_info
  set @attrib_dddw_info = ''
end 

insert adm_custom_obj_info (obj_grp, obj_type ,attrib_grp , attrib_sub_type  ,
attrib_nm   ,attrib_descr   ,attrib_typ , attrib_dflt ,attrib_values  ,attrib_dddw_info ,computable , style_attrib,
enable_if_tx)
select @obj_grp, @obj_type ,@attrib_grp , @attrib_sub_type  ,@attrib_nm   ,@attrib_descr   ,@attrib_typ , @attrib_dflt ,
@attrib_values  ,@attrib_dddw_info ,@computable  , @style_attrib, @enable_if_tx
GO
GRANT EXECUTE ON  [dbo].[adm_add_cust_obj_info] TO [public]
GO

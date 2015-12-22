SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_porpt] @range varchar(8000) = '0=0', 
  @grouping varchar(255) = 'NULL,NULL,NULL,NULL', 
  @order varchar(1000) = 'releases.po_no', @r_status varchar(255) = 'and 0=0'
as
begin
  select @range = replace(@range,'"','''')
  select @order = replace(@order,'"','''')
  select @grouping = replace(@grouping,'"','''')
  select @r_status = replace(@r_status,'"','''')


CREATE table  #rpt_porpt (
vendor_code varchar(12) NOT NULL, 
vendor_name varchar(40) NULL, 
account_no varchar(40) NULL, 
conv_factor decimal(20,8) NULL, 
date_of_order datetime NULL, 
description varchar(255) NULL, 
ext_cost decimal(20,8) NULL, 
location varchar(40) NULL, 
part_no varchar(40) NULL, 
po_no varchar(16) NOT NULL, 
po_key INT NOT NULL, 
project1 varchar(40) NULL, 
project2 varchar(40) NULL, 
project3 varchar(40) NULL, 
qty_ordered  decimal(20,8) NULL, 
qty_received  decimal(20,8) NULL, 
reference_code varchar(40) NULL, 
rel_date datetime NULL, 
line_status varchar(12) NULL, 
item_type varchar(40) NULL, 
unit_cost  decimal(20,8) NULL, 
unit_measure varchar (12) NULL, 
vend_sku varchar(40) NULL, 
who_entered varchar(40) NULL, 
po_type varchar(40) NULL, 
prod_no varchar(40) NULL, 
po_status varchar(12) NULL, 
confirm_date datetime NULL, 
rel_quantity  decimal(20,8) NULL, 
rel_received decimal(20,8) NULL, 
release_date datetime NULL, 
rel_status varchar(12) NULL, 
group_1 varchar(40) NULL, 
group_2 varchar(40) NULL, 
group_3 varchar(40) NULL, 
group_4 varchar(40) NULL )

  
declare @sql varchar(8000)

select @sql = 'SELECT distinct
adm_vend_all.vendor_code, 
adm_vend_all.vendor_name, 
pur_list.account_no, 
pur_list.conv_factor, 
purchase.date_of_order, 
pur_list.description, 
pur_list.ext_cost, 
releases.location, 
releases.part_no, 
releases.po_no, 
releases.po_key, 
pur_list.project1, 
pur_list.project2, 
pur_list.project3, 
pur_list.qty_ordered, 
pur_list.qty_received, 
pur_list.reference_code, 
pur_list.rel_date, 
pur_list.status, 
pur_list.type, 
pur_list.unit_cost, 
pur_list.unit_measure, 
pur_list.vend_sku, 
pur_list.who_entered, 
purchase.po_type, 
purchase.prod_no, 
purchase.status, 
releases.confirm_date, 
releases.quantity, 
releases.received, 
releases.release_date, 
releases.status, ' + @grouping + '
FROM adm_vend_all (nolock),  pur_list (nolock),  purchase (nolock),  
releases (nolock) , locations l (nolock), region_vw r (nolock)
WHERE ' + @range + '
 and ( purchase.po_no = releases.po_no ) and 
   l.location = releases.location and 
   l.organization_id = r.org_id and
( releases.po_no = pur_list.po_no ) and  
( releases.part_no = pur_list.part_no ) and  
( pur_list.line = case when isnull(releases.po_line,0)=0 then pur_list.line else releases.po_line end ) and 
( purchase.po_no = pur_list.po_no ) and  
( adm_vend_all.vendor_code = purchase.vendor_no ) ' +  @r_status + '
 order by ' + @order

print @sql
exec(@sql)

end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_porpt] TO [public]
GO

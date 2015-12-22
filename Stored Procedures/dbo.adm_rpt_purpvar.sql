SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_purpvar] @range varchar(8000) = '0=0' , @order varchar(1000) = 'receipts.receipt_no'
as
begin
  select @range = replace(@range,'"','''')
  select @order = replace(@order,'"','''')

  CREATE TABLE  #rpt_purpvar ( 
  item_no varchar(30),  
  quantity float,  
  r_unit_cost float NULL,  
  location varchar(10),  
  vendor varchar(12),  
  vendor_name varchar(40),  
  account_no varchar(32) NULL,  
  p_unit_cost float,  
  status char(1),  
  description varchar(255) NULL,  
  receipt_no int,  
  po_no varchar(16), 
  std_cost float NULL,  
  std_direct_dolrs float NULL,  
  std_ovhd_dolrs float NULL,  
  std_util_dolrs float NULL,  
  conv_factor float, 
  unit_measure char(2) NULL )

declare @sql varchar(8000)
select @sql = 'SELECT distinct
  receipts.part_no,  
  receipts.quantity,   
  receipts.unit_cost,  
  receipts.location,  
  receipts.vendor,  
  adm_vend_all.vendor_name,  
  receipts.account_no,  
  pur_list.unit_cost,  
  receipts.status,  
  pur_list.description,  
  receipts.receipt_no,  
  receipts.po_no,  
  receipts.std_cost, 
  receipts.std_direct_dolrs,  
  receipts.std_ovhd_dolrs,  
  receipts.std_util_dolrs,  
  receipts.conv_factor,  
  receipts.unit_measure 
   FROM receipts (nolock), adm_vend_all (nolock), pur_list (nolock) , locations l (nolock), region_vw r (nolock)
   WHERE receipts.vendor = adm_vend_all.vendor_code  and  
   l.location = receipts.location and 
   l.organization_id = r.org_id and
   receipts.part_no = pur_list.part_no  and  
   receipts.po_no = pur_list.po_no 
	 and pur_list.line = case when isnull(receipts.po_line,0)=0 then pur_list.line else receipts.po_line end 
   and ' + @range + '
  order by ' + @order

print @sql
exec(@sql)

end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_purpvar] TO [public]
GO

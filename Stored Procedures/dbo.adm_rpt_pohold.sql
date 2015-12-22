SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_pohold] @range varchar(8000) = '0=0', @order varchar(1000) = 'purchase.po_no'
as
begin
  select @range = replace(@range,'"','''')
  select @order = replace(@order,'"','''')

  CREATE table  #rpt_pohold (
  po_no varchar(40) NOT NULL, 
  po_key int NOT NULL, 
  po_type varchar(40) NULL, 
  date_of_order datetime NULL, 
  date_order_due datetime NULL, 
  ship_to_no varchar(40) NULL, 
  who_entered varchar(40) NULL, 
  total_amt_order decimal(20,8) NULL, 
  status varchar(16) NOT NULL, 
  vendor_code varchar(12) NOT NULL, 
  vendor_name varchar(40) NULL, 
  hold_reason varchar(40) NULL, 
  location varchar(40) NULL)


declare @sql varchar(8000)
select @sql = 'SELECT distinct
  purchase.po_no, 
  purchase.po_key, 
  purchase.po_type,  
  purchase.date_of_order, 
  purchase.date_order_due, 
  purchase.ship_to_no,  
  purchase.who_entered, 
  purchase.total_amt_order, 
  purchase.status,   
  adm_vend_all.vendor_code, 
  adm_vend_all.vendor_name,   
  purchase.hold_reason,  
  purchase.location 
  FROM purchase (nolock)
  join adm_vend_all (nolock) on ( purchase.vendor_no = adm_vend_all.vendor_code ) 
  join adm_pohold (nolock) on ( purchase.hold_reason = adm_pohold.hold_code ) 
  join locations l (nolock) on l.location = purchase.location
  join region_vw r (nolock) on l.organization_id = r.org_id
  WHERE ' + @range + '
   and ( purchase.status = ''H'' )
  order by ' + @order

exec(@sql)

end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_pohold] TO [public]
GO

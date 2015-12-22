SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_exrcpt] @range varchar(8000) = '0=0', 
@grouping varchar(255) = 'NULL', @order varchar(1000) = 'releases.po_no'
as
begin
  select @range = replace(@range,'"','''')
  select @grouping = replace(@grouping,'"','''')
  select @order = replace(@order,'"','''')

  CREATE TABLE #rpt_exrcpt ( 
description varchar(254) NULL,    
uom varchar(20) NULL, 
po_no varchar(16) NOT NULL, 
part_no varchar(40) NOT NULL, 
location varchar(40) NULL, 
release_date datetime NULL, 
quantity decimal(20,8) NULL, 
received decimal(20,8) NULL, 
conv_factor decimal(20,8) NULL, 
unit_measure varchar(20) NULL, 
type varchar(20) NULL, 
vendor_code varchar(40) NOT NULL, 
vendor_name varchar(40) NULL, 
line_status varchar(12) NULL, 
rel_status varchar(12) NULL, 
unit_cost decimal(20,8) NULL, 
inv_qty decimal(20,8) NULL, 
group_1 varchar(40) NULL )

declare @sql varchar(8000)

select @sql = 'SELECT   distinct
 substring(inv_master.description,1,254), 
 inv_master.uom, 
 purchase.po_no, 
 pur_list.part_no, 
 pur_list.location, 
 releases.release_date, 
 releases.quantity, 
 releases.received, 
 releases.conv_factor, 
 pur_list.unit_measure, 
 pur_list.type, 
 purchase.vendor_no, 
 adm_vend_all.vendor_name, 
 pur_list.status, 
 releases.status, 
 pur_list.unit_cost, 
 (pur_list.conv_factor * releases.received) as inv_qty, ' +  @grouping + '
FROM pur_list (nolock) 
 left outer join inv_master (nolock) on ( inv_master.part_no = pur_list.part_no)  
 join releases (nolock) on ( pur_list.po_no = releases.po_no ) and   
    ( pur_list.part_no = releases.part_no ) and ( releases.status = ''O'' ) and
    ( pur_list.line = case when isnull(releases.po_line,0)=0 then pur_list.line else releases.po_line end)
 join purchase (nolock) on ( pur_list.po_no = purchase.po_no) 
 join adm_vend_all (nolock) on ( purchase.vendor_no = adm_vend_all.vendor_code ) 
 join locations l (nolock) on l.location = releases.location 
 join region_vw r (nolock) on l.organization_id = r.org_id
WHERE ' + @range + ' 
 ORDER BY ' + @order


--print @sql
exec(@sql)

end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_exrcpt] TO [public]
GO

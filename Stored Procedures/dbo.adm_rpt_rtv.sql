SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_rtv] @range varchar(8000) = '0=0', @sortord varchar(255) = ' ASC', 
  @order varchar(1000) = 'rtv.rtv_no'
as
begin
  select @range = replace(@range,'"','''')
  select @sortord = replace(@sortord,'"','''')
  select @order = replace(@order,'"','''')

   CREATE TABLE  #rpt_rtv (  
   match_ctrl_int int,    	
   vendor_code varchar(12),   	
   vendor_remit_to char(8) NULL,   	
   printed_flag smallint,   	
   amt_net float,   	
   amt_discount float,   	
   amt_tax float,   	
   amt_freight float,   	
   amt_misc float,   	
   amt_due float,   	
   match_posted_flag smallint,   	
   nat_cur_code varchar(8) NULL,   	
   amt_tax_included float,   	
   apply_date datetime,   	
   aging_date datetime,   	
   due_date datetime,   	
   discount_date datetime,   	
   invoice_receive_date datetime,   	
   vendor_invoice_date datetime,   	
   vendor_invoice_no varchar(20),   	
   date_match datetime,   	
   vendor_name varchar(40),   	
   pay_to_name varchar(40),   	
   match_line_num int,   	
   po_ctrl_num varchar(16),   	
   part_no varchar(30) NULL,   	
   item_desc varchar(60),   	
   qty_ordered float,   	
   unit_price float,   	
   qty_invoiced float,   	
   vend_addr1 varchar (40),   	
   vend_addr2 varchar (40),   	
   vend_addr3 varchar (40),   	
   vend_addr4 varchar (40),   	
   vend_addr5 varchar (40),   	
   vend_addr6 varchar (40),   	
   pay_addr1 varchar (40),   	
   pay_addr2 varchar (40),   	
   pay_addr3 varchar (40),   	
   pay_addr4 varchar (40),   	
   pay_addr5 varchar (40),   	
   pay_addr6 varchar (40),   	
   match_unit_price float,   	
   process_group_num varchar(16) NULL, 
   rtv_no int )

declare @sql varchar(8000)
select @sql = 'SELECT distinct
   adm_pomchchg.match_ctrl_int,   	
   adm_pomchchg.vendor_code,   	
   adm_pomchchg.vendor_remit_to,   	
   adm_pomchchg.printed_flag,   	
   adm_pomchchg.amt_net,   	
   adm_pomchchg.amt_discount,   	
   adm_pomchchg.amt_tax,   	
   adm_pomchchg.amt_freight,   	
   adm_pomchchg.amt_misc,   	
   adm_pomchchg.amt_due,   	
   adm_pomchchg.match_posted_flag,   	
   adm_pomchchg.nat_cur_code,   	
   adm_pomchchg.amt_tax_included,   	
   adm_pomchchg.apply_date,   	
   adm_pomchchg.aging_date,   	
   adm_pomchchg.due_date,   	
   adm_pomchchg.discount_date,   	
   adm_pomchchg.invoice_receive_date,   	
   adm_pomchchg.vendor_invoice_date,   	
   adm_pomchchg.vendor_invoice_no,   	
   adm_pomchchg.date_match,   	
   adm_vend_all.vendor_name,   	
   appayto.pay_to_name,   	
   adm_pomchcdt.match_line_num,   	
   adm_pomchcdt.po_ctrl_num,   	
   adm_pomchcdt.part_no,   	
   adm_pomchcdt.item_desc,   	
   adm_pomchcdt.qty_ordered,   	
   adm_pomchcdt.unit_price,   	
   adm_pomchcdt.qty_invoiced,   	
   adm_vend_all.addr1,   	
   adm_vend_all.addr2,   	
   adm_vend_all.addr3,   	
   adm_vend_all.addr4,   	
   adm_vend_all.addr5,   	
   adm_vend_all.addr6,   	
   appayto.addr1,   	
   appayto.addr2,   	
   appayto.addr3,   	
   appayto.addr4,   	
   appayto.addr5,   	
   appayto.addr6,   	
   adm_pomchcdt.match_unit_price,   	
   adm_pomchchg.process_group_num,  
   rtv.rtv_no 	
    FROM rtv (nolock)
join adm_pomchchg (nolock) on ( adm_pomchchg.match_ctrl_int = rtv.match_ctrl_int )
join adm_vend_all (nolock) on ( adm_pomchchg.vendor_code = adm_vend_all.vendor_code ) 
left outer join appayto (nolock) on ( adm_pomchchg.vendor_code = appayto.vendor_code) and
  ( adm_pomchchg.vendor_remit_to = appayto.pay_to_code) 
left outer join adm_pomchcdt (nolock) on ( adm_pomchchg.match_ctrl_int = adm_pomchcdt.match_ctrl_int) 
join locations l (nolock) on l.location = rtv.location 
join region_vw r (nolock) on l.organization_id = r.org_id
    WHERE ' + @range + '
   order by ' + @order + @sortord + ', adm_pomchchg.match_ctrl_int' 

print @sql
exec(@sql)

end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_rtv] TO [public]
GO

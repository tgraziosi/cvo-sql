SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_ep_get_po] @change_ind int
as
declare @rc int, @last_sent_date datetime
select @rc = 1, @last_sent_date = getdate()

begin tran
if @change_ind = 1 -- send the changed Purchase Orders
begin
  update purchase_all
  set approval_status = case isnull(approval_status,'') when 'N' then 'P' else approval_status end,
    etransmit_status = case isnull(etransmit_status,'') when 'N' then 'P' else etransmit_status end,
    eprocurement_last_sent_date = @last_sent_date
  where (isnull(approval_status,'') = 'N' or isnull(etransmit_status,'') = 'N' )
    and eprocurement_last_recv_date is not NULL
end
else
begin
  update purchase_all
  set approval_status = case isnull(approval_status,'') when 'N' then 'P' else approval_status end,
    etransmit_status = case isnull(etransmit_status,'') when 'N' then 'P' else etransmit_status end,
    eprocurement_last_sent_date = @last_sent_date
  where (isnull(approval_status,'') = 'N' or isnull(etransmit_status,'') = 'N' )
    and eprocurement_last_recv_date is NULL
end


select 
case when eprocurement_last_recv_date is NULL then 0 else 1 end as change_order_ind,
case when isnull(approval_status,'') = 'P' then 1 else 0 end as approval_ind,
case when isnull(etransmit_status,'') = 'P' then 1 else 0 end as transmit_ind,
case when isnull(p.void,'V') = 'V' then 1 else 0 end as	 void_ind,
p.po_no as ppo_no, 
p.date_of_order as pdate_of_order, 
p.who_entered as pwho_entered, 
p.vendor_no as pvendor_no, 
v.vendor_name as vvendor_name,v.addr2 as vaddr2,v.addr3 as vaddr3,v.addr4 as vaddr4,v.addr5 as vaddr5,v.addr6 as vaddr6,
v.city as vcity, v.state as vstate, v.postal_code as vpostal_code, v.country as vcountry,
p.note as pnote , 
p.curr_key as pcurr_key,
l.part_no as lpart_no, 
l.description as ldescription, 
r.quantity as rquantity, 
l.curr_cost as lcurr_cost, 
l.unit_measure as lunit_measure, 
l.shipto_name as lshipto_name, l.addr1 as laddr1, l.addr2 as laddr2, l.addr3 as laddr3,l.addr4 as laddr4, l.addr5 as laddr5,
l.note as lnote,
r.release_date as rrelease_date,
r.due_date as rdue_date,
i.category as icategory,
g.company_id as gcompany_id,
l.account_no as laccount_no,
isnull(l.reference_code,'') as lreference_code ,
p.ship_to_no  as pship_to_no
from purchase_all p
join pur_list l on l.po_no = p.po_no
join releases r on r.po_no = l.po_no and r.po_line = l.line
join adm_vend_all v on v.vendor_code = p.vendor_no
join glco g on 1 = 1
left outer join inv_master i on i.part_no = l.part_no and l.type != 'M'
where p.eprocurement_last_sent_date = @last_sent_date

commit tran
return @rc

GO
GRANT EXECUTE ON  [dbo].[adm_ep_get_po] TO [public]
GO

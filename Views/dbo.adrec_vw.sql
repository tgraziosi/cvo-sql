SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


-- select * from adrec_vw

CREATE view [dbo].[adrec_vw] as

select 
	r.receipt_no ,
	r.po_key , 
	p.line,
	r.vendor , 
	r.location ,
	r.part_no , 
	p.description , 
	r.unit_measure ,
	p.qty_ordered , 
 	qty_received = r.quantity , 
	date_received = r.recv_date , 
	qc_desc=
		CASE r.qc_flag
			WHEN 'N' THEN 'No'
			WHEN 'Y' THEN 'Yes'
			WHEN 'F' THEN 'No'					-- mls 02/21/03 SCR 29078
			ELSE ''
		END, 	
	r.status,
	
	status_desc = 
		CASE r.status
			WHEN 'R' THEN 'Received'
			WHEN 'S' THEN 'Matched'
			ELSE ''
		END, 
	r.unit_cost , 
 r.part_type ,
 r.sku_no , 
 r.who_entered,
 r.voucher_no ,
 i.tolerance_cd,
 
 	-- EL - 051214 -- Air or Ocean Delivery Method
	Case when p.ship_via_method IS NULL and pa.ship_via_method IS NULL THEN 'NA'
		WHEN p.ship_via_method = 0 THEN 'None'
			WHEN p.ship_via_method = 1 THEN 'Air'
				WHEN p.ship_via_method = 2 THEN 'Ocean'
		WHEN p.ship_via_method IS NULL and pa.ship_via_method = 0 THEN 'None'
			WHEN p.ship_via_method IS NULL and pa.ship_via_method = 1 THEN 'Air'
				WHEN p.ship_via_method IS NULL and pa.ship_via_method = 2 THEN 'Ocean'
					ELSE 'XXXXXXXX' END AS x_method,

i.type_code , -- 12/8/2014 - tag -- acctg request to add

x_receipt_no=r.receipt_no ,
x_po_key=r.po_key , 
x_line=p.line,
x_qty_ordered=p.qty_ordered , 
x_qty_received = r.quantity , 
x_date_received = ((datediff(day, '01/01/1900', r.recv_date) + 693596)) + (datepart(hh,r.recv_date)*.01 + datepart(mi,r.recv_date)*.0001 + datepart(ss,r.recv_date)*.000001),
x_unit_cost=r.unit_cost 


from receipts_all r 
join pur_list p (nolock) on r.po_key = p.po_key and r.part_no = p.part_no
  and p.line = case when isnull(r.po_line,0)=0 then p.line else r.po_line end	-- mls 5/9/01  SCR 6603 
left outer join inv_master i (nolock) on i.part_no = r.part_no							-- mls 2/14/01 SCR 25365
  and r.part_type = 'P' 
inner join purchase_all pa (nolock) on pa.po_key = p.po_key -- EL - 051214 -- Air or Ocean Delivery Method

  
 


GO
GRANT REFERENCES ON  [dbo].[adrec_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adrec_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adrec_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adrec_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adrec_vw] TO [public]
GO

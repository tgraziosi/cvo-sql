SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE view [dbo].[cvo_out_of_stock_vw] as
-- tag - 2/3/2012 - changed available calculation to match tdc_get_alloc_qntd_sp logic
-- tag - 4/3/2012 - corrected so that items with no purchase orders display
--					display the first open purchase order number correctly
--					include in_stock and avail inventory in output
-- tag - 3/13 - update for SA
-- tag - 06/12/13 - fix when there are po's but none open
--
-- select * From cvo_out_of_stock_vw where location = '001' and type = 'frame'

SELECT  
 isnull(t1.category,'') as 'Brand',
 isnull(t8.field_2,'') as 'Style',
 isnull(t8.field_3,'') as 'Color',
 isnull(CONVERT(INT,t8.field_17),'') as 'Eye Size',
 isnull(t8.field_6,'') as 'Bridge Size',                            
 t1.part_no,                 
 t1.description,    
 t1.type_code as 'Type',           
 cia.location,
 (select top 1 r.confirm_date from releases r (nolock) 
 where r.confirm_date = min(t6.confirm_date) and
	r.part_no = t1.part_no and r.status='O' order by r.po_no ) as 'Next PO Confirm Date',
 (select top 1 r.inhouse_date from releases r (nolock) 
 where r.inhouse_date = min(t6.inhouse_date) and
	r.part_no = t1.part_no and r.status='O' order by r.po_no ) as 'Next PO Inhouse Date',
 -- min(isnull(t6.inhouse_date,t6.confirm_date)) 'Next PO Inhouse Date',
 (select top 1 r.po_no from releases r (nolock) 
 where isnull(r.inhouse_date,r.confirm_date) = min(isnull(t6.inhouse_date,t6.confirm_date)) and
	r.part_no = t1.part_no and r.status = 'o' order by r.po_no ) as 'Next PO',
 isnull((select sum(quantity-received) from releases r (nolock)
   where r.part_no = t1.part_no and r.location = cia.location and status='O'),0)
 AS 'Open PO Qty', 
  isnull((select sum(ol.ordered-ol.shipped) from ord_list (nolock) ol 
			where status <= 'R' and ol.location=cia.location and ol.part_no=t1.part_no) , 0)
			+
  isnull(( select sum(x.ordered-x.shipped) from xfer_list (nolock) X
			where x.status in ('N','P','Q') and x.from_loc=cia.location and x.part_no = t1.part_no), 0)
 as 'Open Order Qty',
 cia.in_stock,
 cia.qty_avl Avail
 
FROM inv_master t1 (nolock)
join cvo_item_avail_vw cia (nolock)  on t1.part_no = cia.part_no and cia.location = '001'
join inv_master_add t8 (nolock) on t8.part_no=t1.part_no 
-- include status in the join - 061213    
left join releases t6 (nolock) on (cia.location = t6.location and t1.part_no = t6.part_no and t6.status = 'O')                    
left join purchase_all t5 (nolock) on t5.po_no=t6.po_no 
              
where 1=1
and cia.location = '001' and cia.qty_avl <= 15 -- added reserve level of 15 instead of zero - 2/16/2012 - tag
and (t8.field_28>=getdate() or t8.field_28 is null)     -- POM date future   
and (t8.field_26<getdate() or t8.field_26 is null)  -- release date must have passed - 2/16/2012
and exists (select 1 from ord_list ol (nolock) 
	where ol.part_no = t1.part_no and (ol.ordered-ol.shipped)<>0 and ol.status<'P' and ol.location = cia.location) -- only include on report if there are open so's
and isnull(t6.quantity,1)>isnull(t6.received,0) -- for when there are no open po's
and isnull(t6.status,'O')='O' 

group by
t1.category,
t8.field_2,
t8.field_3,
t8.field_17,
t8.field_6,                            
t1.part_no,                 
t1.description,    
t1.type_code,
cia.location,
cia.in_stock,
cia.qty_avl
  
--and t1.part_no like ('bccam%')
--and t2.location = '001'





GO
GRANT REFERENCES ON  [dbo].[cvo_out_of_stock_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_out_of_stock_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_out_of_stock_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_out_of_stock_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_out_of_stock_vw] TO [public]
GO

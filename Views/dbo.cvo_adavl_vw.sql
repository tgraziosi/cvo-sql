SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
        
CREATE view [dbo].[cvo_adavl_vw] as          
SELECT distinct              
 t1.part_no,                 
 t1.description,                
 t1.location,                 
 --t1.in_stock -t1.sch_alloc - t1.commit_ed + t1.hold_qty+t1.hold_mfg+t1.hold_ord+t1.hold_rcv+t1.hold_xfr, -- -t1.sch_alloc                
 t1.min_stock AS 'Reserve Level',               
 t5.date_order_due AS 'Next PO Date'  ,              
 t5.po_no AS 'Next PO'    ,          
 t6.qty_ordered AS 'QTY on Order',          
-- CASE WHEN t7.order_ext<>0 THEN t7.ordered         
-- ELSE 0        
-- END        
ISNULL((select SUM(ordered) from ord_list z2(nolock) inner join orders_all z1 on z1.order_no=z2.order_no and  
z1.ext=z2.order_ext and z1.location=z2.location
where z2.part_no=t1.part_no and z1.status='N' and z1.location=t1.location and z1.ext>0),0)   
   AS 'Backordered',
CASE WHEN t1.type_code='FRAME' THEN 'FRAME/SUN'
	WHEN t1.type_code='SUN' THEN 'FRAME/SUN'
	ELSE t1.type_code
END AS 'Type'            
FROM inventory t1              
left join pur_list t4 on t4.part_no=t1.part_no              
left join purchase_all t5 on t4.po_no=t5.po_no and t1.location=t5.ship_to_no              
left join pur_list t6 on t6.part_no=t1.part_no and t6.po_no=t5.po_no              
left join inv_master_add t8 on t8.part_no=t1.part_no          
where --t1.type_code in ('FRAME','SUN') and         
t1.in_stock<=0  and (t8.field_28>=getdate() or t8.field_28 is null)        
--and (t3.ext<>0 OR RIGHT (t3.user_def_fld4,1)<>0)      
--and t3.status<>'T' 
and t5.po_no=(select min(po_no) from purchase_all where po_no in (select po_no from pur_list    
where part_no=t1.part_no) and status='O')  
--and t1.part_no='CVOLIBRO5217'
GO
GRANT REFERENCES ON  [dbo].[cvo_adavl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_adavl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_adavl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_adavl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_adavl_vw] TO [public]
GO

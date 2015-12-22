SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_custom_frames_vw] as
select t1.order_no, t1.order_ext, t1.Line_no, t4.part_no as frame_part, t4.ordered-t4.shipped as open_order_qty, t1.part_no as substitute_part,
-- this is the section for calcing avail = in_stock - allocated - quarantine
t2.in_stock,   
isnull((select sum(qty)
	from tdc_soft_alloc_tbl (nolock)
	where location = t2.location
	and part_no = t2.part_no
	and order_no <> 0),0) as allocated_qty,
ISNULL((SELECT sum(qty) -- quarantine 
	    FROM lot_bin_stock (nolock)
	   WHERE location = t2.location
	     AND part_no = t2.part_no
	     AND bin_no in (SELECT bin_no 
    	      FROM tdc_bin_master (nolock)
    	     WHERE usage_type_code = 'QUARANTINE' 
		AND location = t2.location)), 0) as quarantine_qty,
-- end of avail pieces
t3.cust_code, 
t3.ship_to_name, 
convert(varchar(12),t3.date_entered,101) as entered_date, 
t3.user_category,t3.status, t3.who_entered

From cvo_ord_list_kit t1 (nolock), 
	inventory t2 (nolock),
	orders_all t3 (nolock),
	ord_list t4 (nolock)
where replaced <> 'N'
and t1.location = t2.location
and t1.part_no = t2.part_no
and t1.order_no = t3.order_no and t1.order_ext = t3.ext
and t1.order_no = t4.order_no and t1.order_ext = t4.order_ext and t1.line_no = t4.line_no
and t3.status < 'R' and t3.status <>'V'
--order by t1.order_no, t1.order_ext, t1.line_no
GO
GRANT REFERENCES ON  [dbo].[cvo_custom_frames_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_custom_frames_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_custom_frames_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_custom_frames_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_custom_frames_vw] TO [public]
GO

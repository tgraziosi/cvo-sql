SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Summary of open orders and inventory availability
-- CVO - Tine Graziosi - May 2012

--if (object_id('tempdb.dbo.#inv_by_type') is not null)
--	drop table #inv_by_type
--
--select 
--st.part_no, st.location, usage_type_code, sum(qty) qoh 
--into #inv_by_type
--From lot_bin_stock st, tdc_bin_master t
--where st.bin_no = t.bin_no
--group by st.part_no, st.location, t.usage_type_code
--
---- select distinct usage_type_code from #inv_by_type

CREATE view [dbo].[cvo_open_order_summary_vw]
as 
select 
cia.brand, 
cia.restype, 
cia.style, 
cia.part_no, 
-- cia.description,
CONVERT(VARCHAR(10),Cia.POM_date,101) POM_date,
cia.location, 
convert(varchar(10),cia.nextpoduedate,101) NextPODueDate,
cia.NextPOOnOrder,
cia.in_stock,
cia.qty_avl, 
-- cia.qty_commit, 
cia.allocated, 
Quar_qty = 
	isnull( (select sum(qty) from lot_bin_stock st (nolock), 
		tdc_bin_master t (nolock)
		where st.bin_no = t.bin_no and st.location = t.location
		and st.part_no = cia.part_no and st.location = cia.location
		and t.usage_type_code = 'QUARANTINE'), 0),
Rct_qty =
	isnull( (select sum(qty) from lot_bin_stock st (nolock), 
		tdc_bin_master t (nolock)
		where st.bin_no = t.bin_no and st.location = t.location
		and st.part_no = cia.part_no and st.location = cia.location
		and t.usage_type_code = 'RECEIPT'), 0),
Key_Accts_in_stock = 
	isnull( (select sum(in_stock) from inventory 
		where part_no = cia.part_no and location <> cia.location
		and location in ('008','012-MIDO','013-SECO','Kaiser','Centennial',
		'Costco','Insight','Kaiser','Liberty','Luxottica')
	), 0),
--ol.order_no, order_ext, ship_to_name, line_no, ordered, ol.status, o.user_category
Key_Accts_avl = 
	isnull ( (select sum(qty_avl) from cvo_item_avail_vw 
		where part_no = cia.part_no and location <> cia.location
		and location in ('008','012-MIDO','013-SECO','Kaiser','Centennial',
		'Costco','Insight','Kaiser','Liberty','Luxottica')
	), 0),
F01Key_in_stock = isnull(cia.qty_key, 0)

From cvo_item_avail_vw cia (nolock) WHERE exists (select 1 from ord_list ol (nolock) where ol.ordered>ol.shipped
and ol.part_no = cia.part_no and ol.location = cia.location and ol.status <='r') 

 --Qty_on_so = isnull( (SELECT SUM(ordered-shipped) from ord_list ol (nolock)
	--inner join orders o (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
	--where ol.part_no = t3.part_no and ol.status < 'R' and o.type='I'), 0),
 --qty_commit = t3.commit_ed ,    

-- (cia.qty_commit >0)

---- FOR TESTING
--
--WHERE cia.qty_avl<=0 and (cia.qty_commit >0) -- must have open sales orders and no avail inventory
--and cia.brand = 'bcbg' AND cia.LOCATION = '001' and cia.restype = 'frame'
GO
GRANT REFERENCES ON  [dbo].[cvo_open_order_summary_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_open_order_summary_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_open_order_summary_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_open_order_summary_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_open_order_summary_vw] TO [public]
GO

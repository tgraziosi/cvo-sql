SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[CVO_items_discontinue_vw]
AS
-- 5/12 - TAG - add gender and material
-- 3/13 - tag - add soft allocated qty
-- 10/13 - tag - don't care about vendor_sku table
SELECT
	i.vendor,
	i.category as brand,
	i.type_code as type,
	ia.category_3 as part_type,
	ia.field_2 as style,
	i.part_no,
	i.description,
	i.obsolete,
	ia.field_28 as POM_Date,
	ia.datetime_2 as Backorder_Date,
	inv.location,
	--inv.cvo_in_stock,
	inv.in_stock,
	inv.qty_avl Avail,
	inv.ReserveQty,
	--Avail = inv.cvo_in_stock 
	-- -
	-- isnull((select sum(quantity) from cvo_soft_alloc_det (nolock) 
	--		where location=inv.location and part_no=i.part_no and 
	--		status in (0,1) ), 0)
	-- -
	-- isnull((select sum(qty)
	--	from tdc_soft_alloc_tbl (nolock)
	--	where location = inv.location
	--	and part_no = i.part_no
	--	and (order_no <> 0 or (order_no = 0 and dest_bin = 'CUSTOM'))),0) --allocated to orders/transfers
	-- -
	-- ISNULL((SELECT sum(qty) -- quarantine 
	--		FROM lot_bin_stock (nolock)
	--	   WHERE location = inv.location
	--		 AND part_no = i.part_no
	--		 AND bin_no in (SELECT bin_no 
 --   			  FROM tdc_bin_master (nolock)
 --   			  WHERE usage_type_code = 'QUARANTINE' 
	--			  AND location = inv.location)), 0)
	-- -
	-- inv.replen_qty 
	-- -
	-- isnull(z1.qty, 0),

-- 5/12 - TAG
	isnull(ia.field_10,'') Material,
	isnull(ia.category_2,'') Gender
 
FROM
	inv_master i
	left outer join cvo_item_avail_vw inv (nolock) on i.part_no = inv.part_no and inv.location = '001'
	--left outer join inventory inv (nolock) on i.part_no = inv.part_no and inv.location = '001'
	LEFT OUTER JOIN inv_master_add ia (nolock) ON i.part_no = ia.part_no
	LEFT OUTER JOIN uom_id_code u (nolock) ON i.part_no = u.part_no
	LEFT OUTER JOIN part_price p (nolock) ON i.part_no = p.part_no
	-- LEFT OUTER JOIN vendor_sku v (nolock) ON i.part_no = v.sku_no AND i.vendor = v.vendor_no
	-- left join dbo.f_get_excluded_bins(1) z1 on i.part_no = z1.part_no and inv.location = z1.location
	left join f_get_excluded_bins_1_vw z1 on i.part_no = z1.part_no and inv.location = z1.location
	where i.void <> 'V'
	-- don't need 10/10/2013 -- and isnull(v.last_recv_date,dateadd(d,1,getdate())) > getdate() and isnull(v.curr_key,'USD') = 'USD'
	-- and ia.field_2 = 'portia'



GO
GRANT REFERENCES ON  [dbo].[CVO_items_discontinue_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_items_discontinue_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_items_discontinue_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_items_discontinue_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_items_discontinue_vw] TO [public]
GO

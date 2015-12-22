SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO



CREATE VIEW [dbo].[CVO_items_vw]
AS
SELECT
	isnull(i.vendor,'') vendor,
	isnull(i.category,'') as brand,
	isnull(i.type_code,'') as type,
	isnull(ia.category_3,'') as part_type,
	isnull(ia.field_2,'') as style,
	isnull(i.part_no,'') part_no,
	substring(isnull(i.description,''),1,60) description,
	IsNull(ia.category_5,'') as color_code,
	IsNull(ia.field_3,'') as color,
	CONVERT(INT,isnull(ia.field_17,0)) as eye_size,
	IsNull(ia.field_6,'') as bridge_size,
	IsNull(ia.field_8,'') as temple_size,
	isnull(i.weight_ea,0.0) as weight, -- 11/10 - TAG - add. fields for TB
	IsNull(ia.field_1,'') as case_part,
	isnull(ia.field_4,'') as pattern, -- 11/10 - TAG - add. fields for TB
	isnull(ia.field_26,'') as release_date, -- 11/10 - TAG - add. fields for TB
	ia.field_28 as pom_date, -- 4/1 - EL - add. fields 
	IsNull(p.price_a,0) as base_price,
	--IsNull(v.last_price,0) as cost,
	isnull(l.std_cost,0) as cost, -- tag - 12/9/2013
	IsNull(l.std_ovhd_dolrs,0) as xfer_cost,
	IsNull(l.std_util_dolrs,0) as freight_cost,
	isnull(l.lead_time,0) as lead_time,	-- 11/10 - TAG - add. fields for TB
	isnull(u.upc,'') as upc_code,
    void = case i.void
		when 'N' then 'No'
		when 'V' then 'Yes'	-- 11/15 - tag - added for TB
		else 'N'
	end,
	isnull(ia.category_2,'') as demographic,
	isnull(ia.category_4,'') as target_age, -- 032714
	isnull(i.cmdty_code,'') as material,
    isnull(cn.description,'') as CntryOfOrgin,  -- 041514 EL	
	ISNULL(ia.field_32,'') attribute -- 9/21/15 per TB request
FROM
	inv_master i
	LEFT OUTER JOIN inv_master_add ia ON i.part_no = ia.part_no
	LEFT OUTER JOIN uom_id_code u ON i.part_no = u.part_no
	LEFT OUTER JOIN part_price p ON i.part_no = p.part_no AND P.CURR_KEY = 'USD'
	LEFT OUTER JOIN vendor_sku v ON i.part_no = v.sku_no AND i.vendor = v.vendor_no AND V.CURR_KEY = 'USD'
	LEFT OUTER JOIN inv_list l ON i.part_no = l.part_no AND l.location = '001'
    LEFT OUTER JOIN gl_country CN (nolock) on I.country_code=CN.country_code	




GO
GRANT REFERENCES ON  [dbo].[CVO_items_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_items_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_items_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_items_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_items_vw] TO [public]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO





CREATE VIEW [dbo].[CVO_inv_update_vw]
AS

-- SELECT * FROM CVO_INV_UPDATE_VW

SELECT
	ISNULL(i.category,'') AS BRAND,
	ISNULL(ia.field_2,'') AS STYLE,
	ISNULL(ia.field_3,'') AS COLORNAME,
	CONVERT(INT,ISNULL(ia.field_17,0)) AS EYESIZE,
	ISNULL(i.type_code,'') AS RESTYPE,
	ISNULL(I.PART_NO,'') AS PART_NO,
	ISNULL(I.upc_code,'') AS SKU,
	ISNULL(ia.field_26,'') AS RELEASEDATE, -- 11/10 - TAG - add. fields for TB
	ia.field_28 AS POMDATE, -- 4/1 - EL - add. fields 
	ia.category_1 AS WATCH,
	i.web_saleable_flag WEBSALEABLE


	FROM
	inv_master i (NOLOCK)
	LEFT OUTER JOIN inv_master_add ia (NOLOCK) ON i.part_no = ia.part_no
	WHERE I.VOID = 'N'
	


GO
GRANT REFERENCES ON  [dbo].[CVO_inv_update_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_inv_update_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_inv_update_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_inv_update_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_inv_update_vw] TO [public]
GO

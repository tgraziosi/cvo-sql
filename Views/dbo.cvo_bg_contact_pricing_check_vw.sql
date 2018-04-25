SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_bg_contact_pricing_check_vw]
AS
	SELECT	inv.part_no, inv.category, q1.customer_key, q1.net_only
	FROM	inv_master inv (NOLOCK)
	LEFT JOIN c_quote q1 (NOLOCK) ON inv.part_no = q1.item
	UNION all
	SELECT	inv.part_no, inv.category, q2.customer_key, q2.net_only
	FROM	inv_master inv (NOLOCK)
	JOIN inv_master_add ia (NOLOCK) ON ia.part_no = inv.part_no
	LEFT JOIN c_quote q2 (NOLOCK) ON inv.category = q2.item 
		-- TAG - HAVE TO CHECK THE RES TYPE and style OF THE ITEM TOO IF IT'S NOT AN ACTUAL PART NUMBER
		AND ia.field_2 = CASE WHEN '' = ISNULL(q2.style,'') then ia.field_2 ELSE q2.style end
		AND inv.type_code = CASE WHEN '' = ISNULL(q2.res_type,'')  THEN INV.type_code ELSE Q2.res_type END

GO
GRANT SELECT ON  [dbo].[cvo_bg_contact_pricing_check_vw] TO [public]
GO

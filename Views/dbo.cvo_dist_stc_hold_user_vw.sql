SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_dist_stc_hold_user_vw]
AS

SELECT	DISTINCT a.who_entered,
		'' description
FROM	orders_all a (NOLOCK)
JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.ext = b.order_ext
JOIN	cvo_st_consolidate_release d (NOLOCK)
ON		b.consolidation_no = d.consolidation_no  
WHERE	a.who_entered <> 'BACKORDER'
AND		ISNULL(a.who_entered,'') > ''
AND		a.type = 'I'
AND		d.released = 0


GO
GRANT REFERENCES ON  [dbo].[cvo_dist_stc_hold_user_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_dist_stc_hold_user_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_dist_stc_hold_user_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_dist_stc_hold_user_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_dist_stc_hold_user_vw] TO [public]
GO

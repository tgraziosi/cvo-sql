SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_order_hold_user_vw]
AS

SELECT	DISTINCT who_entered,
		'' description 
FROM	orders_all (NOLOCK)
WHERE	status = 'A'
AND		who_entered <> 'BACKORDER'
AND		ISNULL(who_entered,'') > ''


GO
GRANT REFERENCES ON  [dbo].[cvo_order_hold_user_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_order_hold_user_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_order_hold_user_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_order_hold_user_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_order_hold_user_vw] TO [public]
GO

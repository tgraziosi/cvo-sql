SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_next_so_hold_vw]
AS

SELECT	DISTINCT a.order_no, a.order_ext, b.hold_reason
FROM	cvo_so_holds a (NOLOCK)
CROSS APPLY (SELECT TOP 1 order_no, order_ext, hold_reason
			 FROM	cvo_so_holds (NOLOCK)
			 WHERE	order_no = a.order_no 
			 AND	order_ext = a.order_ext
			 ORDER BY CAST(500 - hold_priority as varchar(5)) + CAST(ABS(DATEDIFF(s,GETDATE(),hold_date)) as varchar(20)) desc) as b

GO
GRANT SELECT ON  [dbo].[cvo_next_so_hold_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_next_so_hold_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_next_so_hold_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_next_so_hold_vw] TO [public]
GO

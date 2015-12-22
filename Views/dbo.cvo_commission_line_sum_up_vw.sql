SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_commission_line_sum_up_vw]
AS

SELECT	a.trx_ctrl_num, SUM(a.extended_price) extended_total 
FROM	arinpcdt a (NOLOCK)
LEFT JOIN inv_master_add b (NOLOCK)
ON a.item_code = b.part_no
WHERE ISNULL(b.field_34,'') <> 1
GROUP BY trx_ctrl_num 


GO
GRANT REFERENCES ON  [dbo].[cvo_commission_line_sum_up_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_commission_line_sum_up_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_commission_line_sum_up_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_commission_line_sum_up_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_commission_line_sum_up_vw] TO [public]
GO

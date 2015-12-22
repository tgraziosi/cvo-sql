SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[pr_accum_vw]
AS

	SELECT	[contract_ctrl_num],
					[sequence_id],
					[accumulator],
					[date_entered],
					[userid]
	FROM pr_accumulator
	WHERE	accumulator IN ( SELECT contract_ctrl_num FROM pr_contracts WHERE type = 2 )
GO
GRANT REFERENCES ON  [dbo].[pr_accum_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_accum_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_accum_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_accum_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_accum_vw] TO [public]
GO

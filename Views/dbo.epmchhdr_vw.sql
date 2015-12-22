SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[epmchhdr_vw]
AS
SELECT batch_code, 
	hold_flag = CASE tolerance_hold_flag - tolerance_approval_flag
			WHEN 1 THEN 1
			ELSE 0
		END, 
	amt_net,
	date_applied = apply_date
FROM epmchhdr
GO
GRANT REFERENCES ON  [dbo].[epmchhdr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[epmchhdr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[epmchhdr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[epmchhdr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[epmchhdr_vw] TO [public]
GO

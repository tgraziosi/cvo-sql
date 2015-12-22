SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
 CREATE VIEW [dbo].[cmtrx]
			AS
			  SELECT  timestamp, trx_ctrl_num, trx_type, batch_code, cash_acct_code, user_id, gl_trx_id, date_posted, 
				date_applied, date_entered, reference_code, org_id 
			  FROM cmtrx_all 
GO
GRANT REFERENCES ON  [dbo].[cmtrx] TO [public]
GO
GRANT SELECT ON  [dbo].[cmtrx] TO [public]
GO
GRANT INSERT ON  [dbo].[cmtrx] TO [public]
GO
GRANT DELETE ON  [dbo].[cmtrx] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmtrx] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amta_vw] 

AS 

SELECT a.timestamp,
	 a.trx_type,
	 a.account_type,
	 a.system_defined,
	 a.display_order,
	 a.import_order,
	 a.debit_positive,
	 a.credit_positive,
	 a.debit_negative,
	 a.credit_negative,
	 a.auto_balancing,
	 b.account_type_name,
	 a.updated_by
FROM amtrxact a, 
 amacctyp b
WHERE a.account_type = b.account_type 

GO
GRANT REFERENCES ON  [dbo].[amta_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amta_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amta_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amta_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amta_vw] TO [public]
GO

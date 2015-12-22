SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amca_vw] 

AS 

SELECT a.timestamp,
	 a.company_id,
	 a.classification_id,
	 a.account_type,
	 a.override_account_flag,
	 b.account_type_name,
	 b.display_order,
	 b.income_account,
	 a.updated_by
FROM amclsact a, 
 amacctyp b
WHERE a.account_type = b.account_type 

GO
GRANT REFERENCES ON  [dbo].[amca_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amca_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amca_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amca_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amca_vw] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[ampa_vw] 

AS 

SELECT a.timestamp,
	 a.company_id,
	 a.posting_code,
	 a.account_type,
	 a.account,
	 b.account_type_name,
	 b.display_order,
	 b.income_account,
	 a.updated_by
FROM ampstact a, 
 amacctyp b
WHERE a.account_type = b.account_type 

GO
GRANT REFERENCES ON  [dbo].[ampa_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ampa_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ampa_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ampa_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ampa_vw] TO [public]
GO

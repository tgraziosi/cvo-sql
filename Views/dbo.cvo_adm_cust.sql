SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_adm_cust]
AS
	SELECT	'None' customer_code,
			'No Buying Group' customer_name,
			'Buying Group' addr_sort1
	UNION
	SELECT	customer_code,
			customer_name = IsNull(address_name,''),
			addr_sort1
	FROM	armaster_all a (NOLOCK)
	WHERE	address_type = 0
	AND		addr_sort1 = 'Buying Group'
	AND		status_type = 1

GO
GRANT REFERENCES ON  [dbo].[cvo_adm_cust] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_adm_cust] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_adm_cust] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_adm_cust] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_adm_cust] TO [public]
GO

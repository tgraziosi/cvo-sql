SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_charge_sc_vw]
AS
	SELECT	a.customer_code cust_code,
			a.customer_name
	FROM	arcust a (NOLOCK)
	JOIN	arsalesp b (NOLOCK)
	ON		a.customer_code = b.employee_code
	WHERE	a.status_type = 1
	AND		b.status_type = 1
GO
GRANT SELECT ON  [dbo].[cvo_charge_sc_vw] TO [public]
GO

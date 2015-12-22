SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ar_AgingMOwed_vw]
AS

	select  top 10 aractcus.timestamp, armaster_all.customer_code,  
			customer_name = armaster_all.address_name, 
			amt_balance = (aractcus.amt_balance - aractcus.amt_on_acct) , 
			aractcus.amt_on_acct,
			currency= (select home_currency from glco) 
	FROM	armaster_all, aractcus
	WHERE	armaster_all.customer_code = aractcus.customer_code
	AND	armaster_all.address_type = 0
	order by (amt_balance - amt_on_acct ) desc
GO
GRANT SELECT ON  [dbo].[ar_AgingMOwed_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ar_AgingMOwed_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ar_AgingMOwed_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ar_AgingMOwed_vw] TO [public]
GO

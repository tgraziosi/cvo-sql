SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[CVO_cust_commission_rate_vw] 
AS


SELECT
	m.customer_code,
	m.customer_name,
	--c.commissionable,
	IsNull(c.commission,0) as commission
FROM arcust m (nolock) 
join cvo_armaster_all c (nolock) on m.customer_code = c.customer_code and c.address_type = 0
where c.commissionable = 1

GO
GRANT REFERENCES ON  [dbo].[CVO_cust_commission_rate_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_cust_commission_rate_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_cust_commission_rate_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_cust_commission_rate_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_cust_commission_rate_vw] TO [public]
GO

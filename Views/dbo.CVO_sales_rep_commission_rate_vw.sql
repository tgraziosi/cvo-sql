SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[CVO_sales_rep_commission_rate_vw] 
AS

SELECT
	s.salesperson_code,
	s.salesperson_name,
	CASE s.status_type WHEN 1 THEN 'Active'
						ELSE 'Not Used'
	END as status_type, 
	CASE IsNull(s.escalated_commissions,0) WHEN 0 THEN 'Standard'
						ELSE 'Escalated'
	END as escalated_comm, 
	IsNull(s.commission,0) as commission,                              
	s.date_of_hire,            
	s.draw_amount,
	S.territory_code -- 12/22/2016

FROM arsalesp s (nolock) 



GO
GRANT REFERENCES ON  [dbo].[CVO_sales_rep_commission_rate_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_sales_rep_commission_rate_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_sales_rep_commission_rate_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_sales_rep_commission_rate_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_sales_rep_commission_rate_vw] TO [public]
GO

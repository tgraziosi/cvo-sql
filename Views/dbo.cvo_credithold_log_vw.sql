SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_credithold_log_vw] as 

select    
c.order_no, 
c.ext, 
o.user_category,
o.cust_code,
o.ship_to,
o.ship_to_name,
c.notified,
c.hold_reason,
c.cc_status,
c.bg_code,
c.cred_limit,
c.ar_balance

from dbo.CVO_CreditHold_Sent c
join orders o on o.order_no = c.order_no and o.ext = c.ext

GO
GRANT REFERENCES ON  [dbo].[cvo_credithold_log_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_credithold_log_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_credithold_log_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_credithold_log_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_credithold_log_vw] TO [public]
GO

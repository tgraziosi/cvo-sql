SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                





CREATE VIEW [dbo].[glbg2_vw] AS
SELECT 
	budget_code,
	cast(glbuddet.account_code as varchar(36)) as account_code,
	reference_code,
	date_period_end=period_end_date,
	nat_cur_code,
	net_change,
	current_balance,
	net_change_oper,
	current_balance_oper,

	x_date_period_end=period_end_date,
	x_net_change=net_change,
	x_current_balance=current_balance,
	x_net_change_oper=net_change_oper,
	x_current_balance_oper=current_balance_oper


FROM 
	glbuddet, ib_glchart_vw
WHERE 	
	cast(glbuddet.account_code as varchar(36)) = ib_glchart_vw.account_code
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[glbg2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glbg2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glbg2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glbg2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glbg2_vw] TO [public]
GO

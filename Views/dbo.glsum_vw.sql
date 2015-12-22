SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                








CREATE VIEW [dbo].[glsum_vw] AS
 SELECT 
  	t1.journal_ctrl_num,
	t2.org_id, 
  	cast(t1.account_code as varchar(36)) as account_code,
	t2.home_cur_code,
  	balance=sum(t1.balance),
	t2.oper_cur_code,
	balance_oper=sum(t1.balance_oper),

 	x_balance=sum(t1.balance),
	x_balance_oper=sum(t1.balance_oper)

  FROM 
  	gltrxdet t1,
	gltrx t2

  WHERE t1.journal_ctrl_num = t2.journal_ctrl_num
  GROUP BY 
	t1.journal_ctrl_num, 
	t1.account_code,
	t2.home_cur_code,
	t2.oper_cur_code,
	t2.org_id

GO
GRANT REFERENCES ON  [dbo].[glsum_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glsum_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glsum_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glsum_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glsum_vw] TO [public]
GO

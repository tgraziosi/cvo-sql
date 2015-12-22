SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\VW\glbal.VWv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW	[dbo].[glbal_vw]
AS
SELECT	account_code, 
	balance_date, 
	balance_type,
	bal_fwd_flag,
	sum( home_credit )		total_home_credit,
	sum( home_debit )		total_home_debit, 
	sum( home_net_change )		total_home_net_change, 
	sum( home_current_balance )	total_home_current_balance
FROM	glbal
GROUP BY account_code,
	 balance_date,
	 balance_type,
	 bal_fwd_flag

GO
GRANT REFERENCES ON  [dbo].[glbal_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glbal_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glbal_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glbal_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glbal_vw] TO [public]
GO

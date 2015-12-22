SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

CREATE proc [dbo].[arcm1_sp] @WhereClause varchar(1024)="" as
declare
	@OrderBy	varchar(255)

create table #CreditMemos 
( 
	address_name	varchar(40),		 
	customer_code	varchar(8), 		
	doc_ctrl_num	varchar(16) NULL, 	
	org_id		varchar(30) NULL,	
	trx_ctrl_num	varchar(16) NULL, 	
	void_flag	varchar(4) NULL,		 
	posted_flag	varchar(4) NULL,		
	hold_flag	varchar(4) NULL,		
	nat_cur_code	varchar(8) NULL,	
	amt_net		float NULL, 		
	recurring_flag varchar(30)  NULL,		
	date_doc	int NULL,		
	date_applied	int NULL,	
	date_due int null, -- tag 032114	
	gl_trx_id	varchar(16),
	order_ctrl_num	varchar(16) null 		-- added 3/27/2012 - tag		
	, buying_group varchar(10) -- 12/27/2013 -tag- add buying group
)

create clustered index cm_1 on #CreditMemos (address_name,customer_code,doc_ctrl_num)

select @OrderBy = " order by address_name, doc_ctrl_num"

exec (" insert #CreditMemos select * from arcm1pst_vw " + @WhereClause + @OrderBy)
exec (" insert #CreditMemos select * from arcm1unp_vw " + @WhereClause + @OrderBy)

exec (" select *, x_amt_net=amt_net, x_date_doc=date_doc, x_date_due = date_due, x_date_applied=date_applied from #CreditMemos " + @OrderBy)

 

/**/
GO
GRANT EXECUTE ON  [dbo].[arcm1_sp] TO [public]
GO

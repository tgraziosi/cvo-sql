SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

-- v1.0	TM	Remove view arcr1un2_vw - product bug

CREATE proc [dbo].[arcr1_sp] @WhereClause varchar(1024)="" as 
declare
	@OrderBy	varchar(255)

create table #CashReceipts 
( 
	gl_trx_id	varchar(16),		
	org_id		varchar(30) NULL,	
	address_name	varchar(40),		 
	customer_code	varchar(8), 		
	doc_desc	varchar(40),		
	doc_ctrl_num	varchar(16) NULL, 	
	trx_ctrl_num	varchar(16) NULL, 	
	void_flag	varchar(4) NULL,		 
	hold_flag	varchar(4) NULL,		
	posted_flag	varchar(4) NULL,		
	payment_amt	float NULL, 		
	date_doc	int NULL,		
	date_applied	int NULL,		
	nat_cur_code	varchar(8) NULL,	
	deposit_num	varchar(16) NULL,	
	payment_code	varchar(8) NULL,	
	date_posted	int NULL		
)
create clustered index cr_1 on #CashReceipts (address_name,customer_code,doc_ctrl_num)


select @OrderBy = " order by address_name, doc_ctrl_num"

exec (" insert #CashReceipts select * from arcr1pst_vw " + @WhereClause + @OrderBy)
exec (" insert #CashReceipts select * from arcr1un1_vw " + @WhereClause + @OrderBy)
--exec (" insert #CashReceipts select * from arcr1un2_vw " + @WhereClause + @OrderBy)

exec (" select *, x_payment_amt=payment_amt, x_date_doc=date_doc, x_date_applied=date_applied, x_date_posted=date_posted from #CashReceipts " + @OrderBy)

 


/**/                                              

GO
GRANT EXECUTE ON  [dbo].[arcr1_sp] TO [public]
GO

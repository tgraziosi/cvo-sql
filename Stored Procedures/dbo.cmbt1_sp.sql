SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

/*  ------------------------------------------------------ */
/*  Platinum Explorer					   */
/*  CM Bank Transfers                                      */
/*  ------------------------------------------------------ */
CREATE PROC [dbo].[cmbt1_sp] @WhereClause varchar(1024)='' AS
DECLARE
	@OrderBy	varchar(255)

create table #BankTransfers 
( 
	trx_ctrl_num          varchar(16),
	doc_ctrl_num          varchar(16),
	description	      varchar(40),
	hold_flag	      varchar(5),
	posted_flag           varchar(5),
    	cash_acct_code_from   varchar(32),
	currency_code_from    varchar(8),
	amount_from	      float,
	bank_charge_amt_from  float,
	trx_type_cls_from     varchar(8),
    	cash_acct_code_to     varchar(32),
	currency_code_to      varchar(8),
	amount_to	      float,
	bank_charge_amt_to    float,
	trx_type_cls_to	      varchar(8),
	date_applied          int,
	date_entered          int,
	date_document         int,
	date_posted	      int,
	gl_trx_id	      varchar(16),
	user_name             varchar(30)
		
)

select @OrderBy = ' order by trx_ctrl_num '

exec (' insert #BankTransfers select * from cmbt1pst_vw ' + @WhereClause + @OrderBy)
exec (' insert #BankTransfers select * from cmbt1unp_vw ' + @WhereClause + @OrderBy)
/* ***RDS ALTERNATE SORTING COLUMNS */
exec (' select *, x_amount_from=amount_from, x_bank_charge_amt_from=bank_charge_amt_from, x_amount_to=amount_to, x_bank_charge_amt_to=bank_charge_amt_to, x_date_applied=date_applied, x_date_entered= date_entered, x_date_document=date_document, x_date_posted=date_posted from #BankTransfers ' + @OrderBy)
/* ***RDS END ALTERNATE SORTING COLUMNS */
 
	
  	  
 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[cmbt1_sp] TO [public]
GO

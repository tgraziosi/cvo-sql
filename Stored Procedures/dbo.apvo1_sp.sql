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





































CREATE proc [dbo].[apvo1_sp] @WhereClause varchar(1024)="" as   
declare
	@Sub1				varchar(1024),
	@Sub2				varchar(1024),
	@firstQuote 		smallint,
	@secondQuote		smallint,
	@doc_ctrl_no		varchar(16),
	@trx_ctrl_no		varchar(16),
	@date_applied		varchar(40),
	@local_where		varchar(255),   
	@OrderBy	varchar(255)

create table #Vouchers 
( 
	address_name	varchar(40),				 
	vendor_code	varchar(12),
	pay_to_code	varchar(8),	
	vendor_type varchar(10),				
	voucher_no	varchar(16), 	
	org_id		varchar(30) NULL,
	approval_flag	varchar(4) NULL,													
	hold_flag	varchar(4) NULL,					
	posted_flag	varchar(4) ,					
	nat_cur_code	varchar(8),				
	amt_net		float, 					
	amt_paid	float,	
	amt_open	float,
	-- 
	amt_net_usd     float,
	amt_paid_usd    float,
	amt_open_usd    float,
	-- 
	date_doc	int, 					
	date_applied	int,				
	date_due	int,					
	date_discount	int,
	--
	payment_num varchar(16),
	--				
	invoice_no	varchar(16), 	
	po_ctrl_num	varchar(16), 				
 	gl_trx_id	varchar(16) NULL,
 	batch_code  varchar(16) NULL, 
 	user_name	varchar(30) NOT NULL				
)
create clustered index vch_1 on #Vouchers (address_name,vendor_code,voucher_no)


-- tag - 041814 select @OrderBy = " order by address_name"

select @OrderBy = " order by voucher_no desc"






SELECT @local_where = NULL

if (charindex('trx_ctrl_num',@WhereClause) <> 0)
begin
	select @Sub1 = substring(@WhereClause, 
		charindex('trx_ctrl_num',@WhereClause),
		datalength(@WhereClause) - charindex('trx_ctrl_num',@WhereClause) + 1)
	select @firstQuote = charindex("'", @Sub1)
	select @Sub2 = substring (@Sub1, @firstQuote + 1, datalength(@Sub1) - @firstQuote)

	select @secondQuote = charindex("'", @Sub2)
	select @trx_ctrl_no = substring (@Sub2,1, @secondQuote -1)
	select @local_where = ' trx_ctrl_num like ' +  @trx_ctrl_no
end		

if (charindex('doc_ctrl_num',@WhereClause) <> 0)
begin
	select @Sub1 = substring(@WhereClause, 
		charindex('doc_ctrl_num',@WhereClause),
		datalength(@WhereClause) - charindex('doc_ctrl_num',@WhereClause) + 1)
	select @firstQuote = charindex("'", @Sub1)
	select @Sub2 = substring (@Sub1, @firstQuote + 1, datalength(@Sub1) - @firstQuote)

	select @secondQuote = charindex("'", @Sub2)
	select @doc_ctrl_no = substring (@Sub2,1, @secondQuote -1) 

	if @local_where is NULL 
		select @local_where = ' doc_ctrl_num like ' +  @doc_ctrl_no

	else
		select @local_where = @local_where + ' and doc_ctrl_num like ' +  @doc_ctrl_no
   	
	
end



























if @local_where is not null
	select @local_where = @local_where + " and "		









 exec (" insert	#Vouchers(
	address_name,				 
	vendor_code,	
	pay_to_code,	
	vendor_type,			
	voucher_no, 	
	org_id,
	approval_flag,													
	hold_flag,					
	posted_flag	,					
	nat_cur_code,				
	amt_net	, 					
	amt_paid,	
	amt_open, 
	amt_net_usd,
	amt_paid_usd,
	amt_open_usd,
	date_doc, 					
	date_applied,				
	date_due,					
	date_discount,
	payment_num,				
	invoice_no, 	
	po_ctrl_num, 				
 	gl_trx_id,
 	batch_code,
 	user_name) 		
 select 
	t2.address_name,				 
	t2.vendor_code,					
	t1.pay_to_code,
	-- tag - 070813
	t2.vend_class_code as Vendor_type,		
	voucher_no=t1.trx_ctrl_num, 	
	t1.org_id,
	approval_flag='No',													
	hold_flag='No',					
	posted_flag='Yes',					
	nat_cur_code=t1.currency_code,				
	t1.amt_net, 					
	amt_paid=t1.amt_paid_to_date,	
	round(T1.AMT_NET - T1.AMT_PAID_TO_DATE,2) AS AMT_OPEN

	, round(t1.rate_home*t1.amt_net,2) as Amt_Net_USD
    , round(t1.rate_home*t1.amt_paid_to_date,2) as AMt_paid_USD
    , round(t1.rate_home*(t1.amt_net - t1.amt_paid_to_date),2) as amt_open_USD,
	t1.date_doc, 					
	t1.date_applied,				
	t1.date_due,					
	t1.date_discount,				
	-- ADD CHECK NUMBER
	(SELECT TOP 1 DOC_CTRL_NUM FROM APTRXAGE 
	    WHERE APPLY_TO_NUM = T1.TRX_CTRL_NUM
	    and trx_type = 4111 and apply_trx_type = 4091) AS PAYMENT_NUM,

	invoice_no=t1.doc_ctrl_num, 	
	t1.po_ctrl_num, 				
 	gl_trx_id=t1.journal_ctrl_num,
 	t1.batch_code,  		
	ew.user_name 		
 from 
	apvohdr t1, apmaster t2, ewusers_vw ew 
 where "
  +	@local_where
  +	" t1.vendor_code = t2.vendor_code
      and t2.address_type = 0 and t1.user_id = ew.user_id"
)
 




 exec (" insert	#Vouchers(
	address_name,				 
	vendor_code,		
	pay_to_code,
	vendor_type,				
	voucher_no, 	
	org_id,
	approval_flag,													
	hold_flag,					
	posted_flag	,					
	nat_cur_code,				
	amt_net	, 					
	amt_paid,	
	amt_open,
	amt_net_usd,
	amt_paid_usd,
	amt_open_usd, 
	date_doc, 					
	date_applied,				
	date_due,					
	date_discount,
	payment_num,				
	invoice_no, 	
	po_ctrl_num, 				
 	gl_trx_id,
 	batch_code,  		
	user_name) 	
 select 
	t2.address_name,				 
	t2.vendor_code,		
	t1.pay_to_code,
		-- tag - 070813
	t2.vend_class_code as Vendor_type,					
	voucher_no=t1.trx_ctrl_num, 	
	t1.org_id,
	approval_flag = case t1.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,													
	hold_flag = case t1.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,					
	posted_flag='No',					
	t1.nat_cur_code,				
	t1.amt_net, 					
	amt_paid=t1.amt_paid,			
	round(T1.AMT_NET - T1.AMT_PAID,2) AS   AMT_OPEN

	, round(t1.rate_home*t1.amt_net,2) as Amt_Net_USD
    , round(t1.rate_home*t1.amt_paid,2) as AMt_paid_USD
    , round(t1.rate_home*(t1.amt_net - t1.amt_paid),2) as amt_open_USD,
	t1.date_doc, 					
	t1.date_applied,				
	t1.date_due,					
	t1.date_discount,				
	'' as payment_num,
	invoice_no=t1.doc_ctrl_num, 	
	t1.po_ctrl_num, 				
 	gl_trx_id='',
 	t1.batch_code,	
	ew.user_name
 from 
	apinpchg t1, apmaster t2, ewusers_vw ew
 where  "
  +	@local_where
  +	" t1.vendor_code = t2.vendor_code 
	and t2.address_type = 0
	and t1.trx_type in (4091) and t1.user_id = ew.user_id "	
)





exec (" select *, x_amt_net=amt_net, x_amt_paid=amt_paid, x_amt_open=amt_open, x_date_doc=date_doc, x_date_applied=date_applied, x_date_due=date_due, x_date_discount=date_discount from #Vouchers " + @WhereClause + @OrderBy)

 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apvo1_sp] TO [public]
GO

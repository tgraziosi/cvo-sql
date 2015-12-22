SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apdm3_unpost_vw] as
  select 
  	apinpchg.vendor_code, 
	debit_memo_no=apinpchg.trx_ctrl_num,
	apinpcdt.org_id,
	sequence_id,  
	apinpcdt.location_code, 
	item_code,     
	line_desc,     
	qty_received,   
	unit_code,     
	unit_price,    
	qty_returned,        
	apinpcdt.tax_code,       
	gl_exp_acct=ISNULL(NULLIF(new_gl_exp_acct,""),gl_exp_acct),
	apinpcdt.amt_discount,   
	amt_extended,
	apinpchg.nat_cur_code,
	apinpchg.date_applied

  from 
	apinpcdt apinpcdt, apinpchg apinpchg
  where
		apinpcdt.trx_ctrl_num = apinpchg.trx_ctrl_num
  and	apinpchg.trx_type = 4092    	
GO
GRANT SELECT ON  [dbo].[apdm3_unpost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apdm3_unpost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apdm3_unpost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdm3_unpost_vw] TO [public]
GO

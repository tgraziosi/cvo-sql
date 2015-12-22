SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[arcm3_unpost_vw] as
  select 
  	arinpchg.customer_code, 
	arinpchg.doc_ctrl_num,
	arinpchg.org_id,
	sequence_id,  
	arinpcdt.location_code, 
	item_code,     
	line_desc,     
	qty_shipped,   
	unit_code,     
	unit_price,    
	qty_returned,        
	arinpcdt.tax_code,       
	gl_rev_acct,
	discount_amt,   
	disc_prc_flag,    
	extended_price,
	arinpchg.nat_cur_code,   
	arinpchg.date_applied
  from 
	arinpcdt arinpcdt, arinpchg arinpchg
  where
		arinpcdt.trx_ctrl_num = arinpchg.trx_ctrl_num
  and	arinpchg.trx_type = 2032    	
  and	arinpchg.printed_flag = 1    	
GO
GRANT SELECT ON  [dbo].[arcm3_unpost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcm3_unpost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcm3_unpost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcm3_unpost_vw] TO [public]
GO

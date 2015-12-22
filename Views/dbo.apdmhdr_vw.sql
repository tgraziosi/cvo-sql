SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apdmhdr_vw] as
  select distinct
	vendor_code,
	debit_memo_no=trx_ctrl_num,  
	org_id,			     
	nat_cur_code=currency_code,
	date_doc, 
	apply_to_num		     
  from
	apdmhdr

GO
GRANT SELECT ON  [dbo].[apdmhdr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apdmhdr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apdmhdr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdmhdr_vw] TO [public]
GO

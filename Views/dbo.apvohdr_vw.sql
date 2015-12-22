SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apvohdr_vw] as
  select distinct
	vendor_code,
	voucher_no=trx_ctrl_num,   
	nat_cur_code=currency_code,
	posted_flag=1,
	date_doc
  from
	apvohdr

GO
GRANT SELECT ON  [dbo].[apvohdr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apvohdr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apvohdr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvohdr_vw] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[arcm2_tmp3_vw] as
  select distinct
	customer_code,
	doc_ctrl_num,  
	org_id,		
	payment_type,
	trx_ctrl_num,
	hold_flag,
	nat_cur_code,
	date_doc
  from
	arinppyt
  where
  	trx_type=2111
  and payment_type in (3,4)

GO
GRANT SELECT ON  [dbo].[arcm2_tmp3_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcm2_tmp3_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcm2_tmp3_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcm2_tmp3_vw] TO [public]
GO

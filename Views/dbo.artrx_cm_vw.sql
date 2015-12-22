SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[artrx_cm_vw] as
  select distinct
	customer_code,
	doc_ctrl_num,   
	org_id,		
	trx_ctrl_num,
	payment_type, 
	void_flag,
	nat_cur_code,
	date_doc
  from
	artrx
  where
  	trx_type=2111
  and payment_type in (3,4)

GO
GRANT SELECT ON  [dbo].[artrx_cm_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[artrx_cm_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[artrx_cm_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrx_cm_vw] TO [public]
GO

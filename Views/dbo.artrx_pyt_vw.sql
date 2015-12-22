SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[artrx_pyt_vw] as
 select distinct
	customer_code,
	doc_ctrl_num, 
	trx_ctrl_num,
	payment_type, 
	void_flag,
	nat_cur_code,
	date_doc,
	org_id
 from
	artrx
 where
 	trx_type=2111
 and payment_type in (1,2)	

GO
GRANT REFERENCES ON  [dbo].[artrx_pyt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[artrx_pyt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[artrx_pyt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[artrx_pyt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrx_pyt_vw] TO [public]
GO

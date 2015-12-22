SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[artrx_inv_vw] as
 select distinct
	customer_code,
	doc_ctrl_num, 
	nat_cur_code,
	posted_flag,
	date_doc
 from
	artrx
 where
 	trx_type in (2021, 2031) 	
					

GO
GRANT REFERENCES ON  [dbo].[artrx_inv_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[artrx_inv_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[artrx_inv_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[artrx_inv_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrx_inv_vw] TO [public]
GO

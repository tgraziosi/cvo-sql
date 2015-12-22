SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[arcr2_tmp3_vw] as
 select distinct
	customer_code,
	doc_ctrl_num, 
	trx_ctrl_num,
	payment_type,
	hold_flag,
	nat_cur_code,
	date_doc,
	org_id
 from
	arinppyt
 where
 	trx_type=2111
 and payment_type in (1,2) 

GO
GRANT REFERENCES ON  [dbo].[arcr2_tmp3_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcr2_tmp3_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcr2_tmp3_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcr2_tmp3_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcr2_tmp3_vw] TO [public]
GO

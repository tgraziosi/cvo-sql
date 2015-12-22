SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























CREATE VIEW	[dbo].[arvdinv_vw]
AS
	SELECT	arinpchg.trx_ctrl_num, 
		arinpchg.doc_ctrl_num, 
		arinpchg.customer_code,
       	arinpchg.date_doc,
		arinpchg.org_id
	FROM 	arinpchg
	WHERE	trx_type =2031   
	AND	printed_flag=1
	AND	hold_flag=0
	AND	( LTRIM(order_ctrl_num) IS NULL OR LTRIM(order_ctrl_num) = " " )
	AND 	trx_ctrl_num NOT IN ( SELECT t.trx_ctrl_num 			-- Cyanez
					FROM arinptmp t
					INNER JOIN icv_cctype c
						ON t.payment_code = c.payment_code
						AND LEN (t.prompt4_inp)>0 )

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arvdinv_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arvdinv_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arvdinv_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arvdinv_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arvdinv_vw] TO [public]
GO

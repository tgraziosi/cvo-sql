SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[glcisprt_sp] (
	@journal_ctrl_num	varchar(16) )

AS


INSERT gltrxdet( 
	journal_ctrl_num, 	sequence_id,	account_code, 
	posted_flag, 		date_posted, 	balance, 
	document_1, 		description, 	rec_company_code, 
	company_id, 		document_2, 	reference_code, 
	nat_balance, 		nat_cur_code, 	rate, 
	trx_type, 		offset_flag, 	seg1_code, 
	seg2_code, 		seg3_code, 	seg4_code,
	seq_ref_id,		balance_oper,	rate_oper,
	rate_type_home,		rate_type_oper) 
SELECT @journal_ctrl_num, 	sequence_id, 	account_code, 
	0,			0,		balance, 
	'', 			'Spot Rate Adjustment', rec_company_code, 
	company_id, 		'',		'',
	nat_balance, 		nat_cur_code, 	rate, 
	121,			0,		seg1_code, 
	seg2_code, 		seg3_code, 	seg4_code,
	0,			balance_oper,	rate_oper,
	rate_type_home,		rate_type_oper
FROM #glsprt a
WHERE	a.account_code IN ( SELECT glchart.account_code FROM glchart )


DELETE	#glsprt
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[glcisprt_sp] TO [public]
GO

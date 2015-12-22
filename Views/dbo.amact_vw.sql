SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amact_vw] 
AS 

SELECT 
	th.timestamp,
	th.company_id, 		  
	th.journal_ctrl_num,	  
	th.co_trx_id,    
	th.trx_type, 		   
	th.last_modified_date, 			  
	th.modified_by, 				  
	th.apply_date, 			  
	th.posting_flag, 		  
	th.date_posted, 
	th.hold_flag, 			  
	th.trx_description, 		  
 	th.doc_reference, 	  
	th.note_id, 		  
	th.user_field_id, 		  
	th.total_received, 			  
	th.linked_trx, 		  
	th.revaluation_rate,		  
	th.trx_source,			  
	th.co_asset_id,
	th.change_in_quantity,
	th.fixed_asset_account_id,
	fixed_asset_account_code 	= fa.account_code,
	fixed_asset_ref_code		= fa.account_reference_code,
	th.imm_exp_account_id,
	imm_exp_account_code		= ie.account_code,
	imm_exp_ref_code			= ie.account_reference_code










FROM   	amtrxhdr 	th LEFT OUTER JOIN amacct fa  ON th.fixed_asset_account_id	= fa.account_id
		LEFT OUTER JOIN	amacct		ie ON th.imm_exp_account_id	= ie.account_id
		INNER JOIN	amtrxdef    	tr ON tr.trx_type		= th.trx_type



WHERE 		tr.display_activity 		= 1

GO
GRANT REFERENCES ON  [dbo].[amact_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amact_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amact_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amact_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amact_vw] TO [public]
GO

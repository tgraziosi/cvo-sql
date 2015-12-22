SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amtrxaaa_vw] 
AS 

SELECT 
		th.timestamp,
        th.company_id, 
        th.trx_ctrl_num, 
        th.co_trx_id, 
        th.trx_type, 
        th.last_modified_date, 
        th.modified_by, 
        th.apply_date, 
        from_code = asset.from_code,
        to_code = asset.to_code,
	group_code  = gr.from_code,
    	from_org_id	= org.from_code,        
	to_org_id	= org.to_code			
FROM   	amtrxhdr th 	LEFT OUTER JOIN amdprcrt gr 	ON (th.co_trx_id = gr.co_trx_id 	AND	gr.field_type   = 19)
			LEFT OUTER JOIN amdprcrt org 	ON (th.co_trx_id = org.co_trx_id 	AND	org.field_type	= 20)
			INNER JOIN amdprcrt asset 	ON (th.co_trx_id = asset.co_trx_id 	AND	asset.field_type = 7 )
WHERE  	th.trx_type 		= 100 
AND    	th.posting_flag 	= 0 

GO
GRANT REFERENCES ON  [dbo].[amtrxaaa_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amtrxaaa_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amtrxaaa_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amtrxaaa_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtrxaaa_vw] TO [public]
GO

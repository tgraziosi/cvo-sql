SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                

                                             








                                                





CREATE VIEW [dbo].[pomchinv_vw] 
AS

SELECT 	receipt_ctrl_num,
     	po_ctrl_num , 
     	company_id, 
     	vendor_code , 
     	validated_flag ,
     	hold_flag,
     	invoiced_full_flag,
     	nat_cur_code 
FROM	epinvhdr
WHERE 	receipt_ctrl_num in 
     		(	SELECT 	rec.receipt_ctrl_num  
       			FROM 	epinvhdr hdr , epinvdtl rec  
       			WHERE 	(rec.receipt_ctrl_num = hdr.receipt_ctrl_num )
			AND	(( rec.qty_received - 	( 	SELECT 	ISNULL(sum(dtl.qty_invoiced), 0)
               								FROM  	epmchdtl dtl 
               								WHERE	(dtl.po_ctrl_num = hdr.po_ctrl_num)
	      								AND 	dtl.receipt_dtl_key = rec.receipt_detail_key
									AND	dtl.receipt_sequence_id = rec.sequence_id )) > 0.000001))
AND ( invoiced_full_flag = 0 ) AND (validated_flag=1) AND (hold_flag=0)

                                              
GO
GRANT REFERENCES ON  [dbo].[pomchinv_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[pomchinv_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[pomchinv_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[pomchinv_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[pomchinv_vw] TO [public]
GO

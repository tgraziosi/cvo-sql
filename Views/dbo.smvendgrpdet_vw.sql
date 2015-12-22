SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                

CREATE VIEW [dbo].[smvendgrpdet_vw]
AS
	SELECT
		hdr.group_name,
		det.vendor_mask,
		det.sequence_id
	FROM
		smvendorgrphdr hdr INNER JOIN smvendorgrpdet det
			ON hdr.group_id = det.group_id
GO
GRANT REFERENCES ON  [dbo].[smvendgrpdet_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smvendgrpdet_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smvendgrpdet_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smvendgrpdet_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smvendgrpdet_vw] TO [public]
GO

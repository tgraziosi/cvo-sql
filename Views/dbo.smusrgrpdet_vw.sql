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



























CREATE VIEW [dbo].[smusrgrpdet_vw]
AS
	SELECT	hdr.group_name,
		det.user_name,
		det.sequence_id
	FROM	CVO_Control..smgrphdr hdr INNER JOIN CVO_Control..smgrpdet_vw det
			ON hdr.group_id = det.group_id
GO
GRANT REFERENCES ON  [dbo].[smusrgrpdet_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smusrgrpdet_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smusrgrpdet_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smusrgrpdet_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smusrgrpdet_vw] TO [public]
GO

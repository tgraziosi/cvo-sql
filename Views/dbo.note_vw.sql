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





CREATE VIEW [dbo].[note_vw] AS
SELECT	
	key_type ,
	key_1,
 	sequence_id,
	date_updated,
	updated_by=user_name,
	link_path,
	note,

 	x_sequence_id=sequence_id,
	x_date_updated=date_updated

		
FROM 
	comments c,
	 CVO_Control..smusers  u
WHERE
	u.user_id = c.updated_by
  	  
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[note_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[note_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[note_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[note_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[note_vw] TO [public]
GO

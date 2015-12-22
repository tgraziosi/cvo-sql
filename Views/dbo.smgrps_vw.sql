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


	CREATE VIEW [dbo].[smgrps_vw] AS
		SELECT 'type'=1, CONVERT(varchar(36),id) id, group_id, group_name, group_desc, global_flag 
			FROM smaccountgrphdr
		UNION
		SELECT 'type'=2, CONVERT(varchar(36),id) id,group_id, group_name, group_desc, global_flag 
			FROM smvendorgrphdr
		UNION
		SELECT 'type'=3, CONVERT(varchar(36),id) id, group_id, group_name, group_desc, global_flag 
		FROM smcustomergrphdr
		UNION
		SELECT 'type'=4, CONVERT(varchar(36),id) id,group_id, group_name, group_desc, global_flag 
		FROM CVO_Control..smgrphdr
	
GO
GRANT REFERENCES ON  [dbo].[smgrps_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smgrps_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smgrps_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smgrps_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smgrps_vw] TO [public]
GO

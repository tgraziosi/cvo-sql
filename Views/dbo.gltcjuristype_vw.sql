SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                

CREATE VIEW [dbo].[gltcjuristype_vw] AS 
	select '0' tc_juristype, 'Composite' juris_type_name union
	select '1', 'State' union
	select '2', 'County' union
	select '3', 'City' union
	select '4', 'Special'
GO
GRANT REFERENCES ON  [dbo].[gltcjuristype_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gltcjuristype_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gltcjuristype_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gltcjuristype_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltcjuristype_vw] TO [public]
GO

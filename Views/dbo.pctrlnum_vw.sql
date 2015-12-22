SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\VW\pctrlnum.VWv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[pctrlnum_vw]
AS 
SELECT 	process_num,
	process_mask
FROM	CVO_Control..pctrlnum



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[pctrlnum_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[pctrlnum_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[pctrlnum_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[pctrlnum_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[pctrlnum_vw] TO [public]
GO

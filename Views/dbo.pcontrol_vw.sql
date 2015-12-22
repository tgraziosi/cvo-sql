SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\VW\pcontrol.VWv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[pcontrol_vw]
AS 
SELECT 	process_ctrl_num,
	process_parent_app,
	process_parent_company,
	process_description,
	process_user_id,
	process_server_id,
	process_host_id,
	process_kpid,
	process_start_date,
	process_end_date,
	process_state,
	process_status,
	process_type
FROM	CVO_Control..pcontrol



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[pcontrol_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[pcontrol_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[pcontrol_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[pcontrol_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[pcontrol_vw] TO [public]
GO

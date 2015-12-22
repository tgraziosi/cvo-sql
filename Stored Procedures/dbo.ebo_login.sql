SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                



CREATE PROCEDURE [dbo].[ebo_login]

AS	

		DECLARE @org_id varchar(30), @global_user smallint

		IF EXISTS (SELECT name FROM sysobjects          
				WHERE name = 'smspiduser_vw' )     
		BEGIN
			SELECT @org_id =''
			SELECT @org_id = org_id FROM sm_current_organization c
			WHERE  name =  SUSER_SNAME() 
		
			DELETE smspiduser_vw WHERE spid = @@SPID


			DELETE smspiduser_vw 
			WHERE spid NOT IN (SELECT spid  FROM  master..sysprocesses p)	
			





			SELECT @global_user =0
			SELECT @global_user = COUNT(DISTINCT global_flag) FROM CVO_Control..smgrphdr h
		  		INNER JOIN smgrpdet_vw d
			  		ON h.group_id = d.group_id
			  	AND d.domain_username = SUSER_SNAME()
			  	AND ISNULL(h.global_flag,0)=1
		



			INSERT INTO smspiduser_vw (	spid, 	user_name,	org_id, 	db_name,	global_user) 
			SELECT DISTINCT		@@SPID,	 SUSER_SNAME() ,	@org_id,	DB_NAME(),	@global_user 
	


			IF NOT EXISTS ( SELECT 1 FROM dbo.sm_get_orgs_with_access_fn() a  WHERE a.organization_id = @org_id)
				BEGIN
					SELECT @org_id =''
					
					UPDATE smspiduser_vw
					SET org_id = ''
					WHERE spid = @@SPID
									
					UPDATE 	sm_current_organization
					SET 	org_id = '',
					        organization_name = ''
					WHERE 	name =  SUSER_SNAME() 		
				END
			
		END
	  
	
	                                                              

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ebo_login] TO [public]
GO

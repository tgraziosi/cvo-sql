SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[smlinkspiduser_sp]
		@user_name varchar(30)='',
		@data_base varchar(30)=''
AS	

	DECLARE @org_id	 varchar(30)
	
	IF EXISTS (SELECT 1 FROM master..masterlst WHERE master_db_name = @data_base)
	BEGIN
		IF EXISTS (SELECT name FROM sysobjects          
				WHERE name = 'smspiduser' )     
		BEGIN
			DELETE smspiduser WHERE spid = @@SPID

			INSERT INTO smspiduser (	spid, 	user_name, org_id, 	db_name) 
				SELECT DISTINCT	@@SPID,	@user_name,	'',	      @data_base  
		END
	END
	ELSE
	BEGIN	
		IF EXISTS (SELECT name FROM sysobjects          
				WHERE name = 'smspiduser_vw' )     
		BEGIN
			SELECT @org_id =''
			SELECT @org_id = org_id FROM sm_current_organization c
			WHERE  name = @user_name
		
			DELETE smspiduser_vw WHERE spid = @@SPID	
			
			INSERT INTO smspiduser_vw (	spid, 	user_name,	org_id, 	db_name) 
			SELECT DISTINCT		@@SPID,	@user_name,	@org_id,	@data_base 


			IF NOT EXISTS ( SELECT 1 FROM dbo.sm_get_orgs_with_access_fn() a  WHERE a.organization_id = @org_id)
				BEGIN
					SELECT @org_id =''
					
					UPDATE smspiduser_vw
					SET org_id = ''
					WHERE spid = @@SPID
									
					UPDATE 	sm_current_organization
					SET 	org_id = ''
					WHERE 	name = @user_name		
				END
			
		END
	  
	END
	
	                                              
GO
GRANT EXECUTE ON  [dbo].[smlinkspiduser_sp] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[sm_login_sp]
		@user_name varchar(255)='',
		@data_base varchar(30)=''
AS	
	
RETURN 0

--
--	IF (EXISTS (select 1 from CVO_Control..dminfo WHERE property_id = 53000) AND SUSER_SNAME() NOT IN ('pltsa', 'sa', 'psqladm'))
--		RETURN 0
--
--	IF (LEN(ISNULL(@user_name,'')) = 0) SELECT @user_name = SUSER_SNAME()
--
--	
--	DECLARE @org_id	 varchar(30), @organization_name varchar(60)
--	
--	
--	IF EXISTS (SELECT 1 FROM master..masterlst WHERE master_db_name = @data_base)
--	BEGIN
--		IF EXISTS (SELECT name FROM sysobjects          
--				WHERE name = 'smspiduser' )     
--		BEGIN
--
--		    DELETE smspiduser 
--		    WHERE spid NOT IN (SELECT spid  FROM  master..sysprocesses p)
--
--
--			DELETE smspiduser WHERE spid = @@SPID
--
--			INSERT INTO smspiduser (	spid, 	user_name, org_id, 	db_name,global_user) 
--				SELECT DISTINCT	@@SPID,	@user_name,	'',	      @data_base  ,0
--		END
--	END
--	ELSE
--	BEGIN	
--		IF EXISTS (SELECT name FROM sysobjects          
--				WHERE name = 'smspiduser_vw' )     
--		BEGIN
--			SELECT @org_id =''
--			
--			DELETE smspiduser_vw WHERE spid = @@SPID
--
--
--			DELETE smspiduser_vw 
--			WHERE spid NOT IN (SELECT spid  FROM  master..sysprocesses p)	
--
--			SELECT @org_id = org_id FROM sm_current_organization c WHERE  name = @user_name
--			
--			INSERT INTO smspiduser_vw (	spid, 	user_name,	org_id, 	db_name,global_user) 
--			SELECT DISTINCT		@@SPID,	@user_name,	@org_id,	@data_base , 0
-- 
--			IF ((SELECT ib_flag FROM glco) =0)
--                       	BEGIN 
--
--                                SELECT 	@org_id = organization_id, @organization_name = organization_name
--				FROM    Organization
--				WHERE   outline_num ='1'
--
--				UPDATE 	smspiduser_vw
--				SET 	org_id = @org_id
--				WHERE 	spid = @@SPID
--
--				IF NOT EXISTS (SELECT 1 FROM sm_current_organization WHERE name = @user_name )
--				BEGIN
--					INSERT sm_current_organization VALUES(NULL, @user_name, @org_id, GETDATE(), @organization_name)
--				END
--
--			END				
--
--			IF NOT EXISTS ( SELECT 1 FROM dbo.sm_get_orgs_with_access_fn() a  WHERE a.organization_id = @org_id)
--				BEGIN
--					SELECT @org_id =''
--					
--					UPDATE smspiduser_vw
--					SET org_id = ''
--					WHERE spid = @@SPID
--									
--					UPDATE 	sm_current_organization
--					SET 	org_id = '',
--					        organization_name = ''
--					WHERE 	name = @user_name		
--				END
--			
--		END
--	  
--	END
	
	                                              
GO
GRANT EXECUTE ON  [dbo].[sm_login_sp] TO [public]
GO

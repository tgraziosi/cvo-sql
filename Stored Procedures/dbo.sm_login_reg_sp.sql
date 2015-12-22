SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[sm_login_reg_sp] 
AS
DECLARE @buf varchar(8000)
DECLARE	@buf2  varchar(100)
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''sm_login_sp'' ) 
		DROP PROCEDURE sm_login_sp '
EXEC (@buf)

SELECT @buf =	'CREATE PROCEDURE sm_login_sp
		@user_name varchar(255)='''',
		@data_base varchar(30)=''''
		AS '

IF  EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=0 )
	AND EXISTS (SELECT 1 FROM glco WHERE ib_flag = 0)
		BEGIN
			SELECT @buf = @buf + ' 
			RETURN 0
		'
		END
	ELSE
		BEGIN
			SELECT @buf = @buf + '	
	IF (EXISTS (select 1 from CVO_Control..dminfo WHERE property_id = 53000) AND SUSER_SNAME() NOT IN (''pltsa'', ''sa'', ''psqladm''))
		RETURN 0
	IF (LEN(ISNULL(@user_name,'''')) = 0) SELECT @user_name = SUSER_SNAME()
	DECLARE @org_id	 varchar(30), @organization_name varchar(60), @global_user smallint

	SELECT @global_user =0
	SELECT @global_user = COUNT(DISTINCT global_flag) FROM CVO_Control..smgrphdr h
	INNER JOIN smgrpdet_vw d
	ON h.group_id = d.group_id
	AND d.domain_username = @user_name
	AND ISNULL(h.global_flag,0)=1

	IF EXISTS (SELECT 1 FROM master..masterlst WHERE master_db_name = @data_base)
	BEGIN
		IF EXISTS (SELECT name FROM sysobjects          
				WHERE name = ''smspiduser'' )     
		BEGIN
			IF (SELECT COUNT(1) FROM smspiduser (nolock) WHERE spid = @@SPID) = 0
				INSERT INTO smspiduser ( spid, user_name, org_id, db_name, global_user) 
				SELECT @@SPID, @user_name, '''', @data_base, @global_user
			ELSE
				UPDATE smspiduser 
				SET user_name=@user_name, org_id='''', db_name=@data_base, global_user=@global_user
				WHERE spid = @@SPID
		END
	END
	ELSE
	BEGIN	
		IF EXISTS (SELECT name FROM sysobjects          
			WHERE name = ''smspiduser_vw'' )     
		BEGIN
			SELECT @org_id =''''
			'
		IF EXISTS (SELECT 1 FROM glco WHERE ib_flag = 0) 
			SELECT @buf = @buf + '	
                SELECT 	@org_id = organization_id, @organization_name = organization_name
				FROM    Organization_all (nolock)
				WHERE   outline_num =''1''
				'
		ELSE
			SELECT @buf = @buf + '	
			SELECT @org_id = org_id FROM sm_current_organization c (nolock) WHERE  name = @user_name '
			
		SELECT @buf = @buf + '		
			IF (SELECT COUNT(1) FROM smspiduser_vw (nolock) WHERE spid = @@SPID) = 0
				INSERT INTO smspiduser_vw (spid, user_name, org_id, db_name, global_user) 
				SELECT @@SPID, @user_name, @org_id, @data_base, @global_user
			ELSE
				UPDATE smspiduser_vw 
				SET user_name=@user_name, org_id=@org_id, db_name=@data_base, global_user=@global_user
				WHERE spid = @@SPID 
			'
		
		IF EXISTS (SELECT 1 FROM glco WHERE ib_flag = 0) 
		BEGIN
			SELECT @buf = @buf + '	
			IF NOT EXISTS (SELECT 1 FROM sm_current_organization WHERE name = @user_name )
			BEGIN
				INSERT sm_current_organization VALUES(NULL, @user_name, @org_id, GETDATE(), @organization_name)
			END 
			'
			SELECT @buf2 = 'Organization_all'
		END
		ELSE
			SELECT @buf2 = 'dbo.sm_get_orgs_with_access_fn()'
			
		SELECT @buf = @buf + '	
			IF NOT EXISTS ( SELECT 1 FROM ' + @buf2 + ' a  WHERE a.organization_id = @org_id)
			BEGIN
				SELECT @org_id =''''
				
				UPDATE smspiduser_vw
				SET org_id = ''''
				WHERE spid = @@SPID
								
				UPDATE 	sm_current_organization
				SET 	org_id = '''',
				        organization_name = ''''
				WHERE 	name = @user_name		
			END
		END
	END
	'
		END
		
EXEC (@buf)

SELECT @buf ='	GRANT EXECUTE  ON sm_login_sp TO PUBLIC '
EXEC (@buf)
GO
GRANT EXECUTE ON  [dbo].[sm_login_reg_sp] TO [public]
GO

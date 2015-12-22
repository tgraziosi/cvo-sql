SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[sm_get_unique_user_name_sp] 
	@user_name varchar(255),
	@debug int = 0
AS

  DECLARE  @inc smallint,
	   @unique_user_name varchar(30),
	   @domain_username varchar (30)
BEGIN
  SET @domain_username = SUBSTRING(@user_name,CHARINDEX('\', @user_name)+1,LEN(@user_name))

IF(CHARINDEX('\', @user_name) = 0)-- IF is a SQL user CHARINDEX = 0
	BEGIN
		IF NOT EXISTS (SELECT [domain_username] FROM smusers WHERE [domain_username] = @user_name )
		  BEGIN
		    	SELECT @inc = COUNT([user_name]) FROM   smusers 
	 		WHERE  [user_name] LIKE @user_name + '%'
			IF(@inc = 0)
				BEGIN
				SET @unique_user_name = @user_name
				SELECT @unique_user_name 
				RETURN
				END
			SET @unique_user_name = @user_name + CONVERT(varchar(5), @inc)
			SELECT @unique_user_name 
		  RETURN 
		END
		SET @unique_user_name = @user_name
     		SELECT @unique_user_name 
		RETURN	
	END

IF NOT EXISTS (SELECT [user_name] FROM smusers WHERE [user_name] = @user_name)--Checking for similar domain_usernames
	BEGIN
		SELECT @inc = COUNT(user_name) FROM   smusers 
	 	WHERE  [user_name] LIKE @domain_username + '%' AND domain_username NOT LIKE @user_name
			IF(@inc = 0)
				BEGIN
				SET @unique_user_name = @domain_username
				SELECT @unique_user_name 
				RETURN
				END
		SET @unique_user_name = @domain_username + CONVERT(varchar(5), @inc)
		SELECT @unique_user_name 
		RETURN
	END
	SET @unique_user_name = @domain_username
     	SELECT @unique_user_name 	  		 
  RETURN	
END
GO
GRANT EXECUTE ON  [dbo].[sm_get_unique_user_name_sp] TO [public]
GO

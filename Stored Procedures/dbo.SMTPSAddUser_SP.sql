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


CREATE PROCEDURE [dbo].[SMTPSAddUser_SP] @username              varchar( 255 ),
								 @userpassword  varchar( 255 )


















AS


BEGIN

	DECLARE @result int
	
	SELECT @result = 0
	

	IF NOT EXISTS ( SELECT  name 
					FROM    master..syslogins
					WHERE   name = @username )
		EXEC sp_addlogin @username, @userpassword
	
	IF ( @@error != 0 )
		SELECT @result = 1
	ELSE

		IF NOT EXISTS ( SELECT  name 
						FROM    sysusers
						WHERE   name = @username )
			EXEC sp_adduser @username

		IF ( @@error != 0 )
			SELECT  @result = 1
		ELSE
			IF NOT EXISTS ( SELECT  domain_username 
							FROM    CVO_Control..smusers
							WHERE   domain_username = @username )
			BEGIN
				BEGIN TRAN

				UPDATE  CVO_Control..smuid
				SET             user_id = user_id + 1
		
				IF ( @@error != 0 )
					SELECT @result = 1
				ELSE
					INSERT  CVO_Control..smusers
					SELECT  NULL, user_id, @username, 1, 0, 0, 0, @username, 0 , 0
					FROM    CVO_Control..smuid
					
				IF ( @@error != 0 )
				BEGIN
					ROLLBACK TRAN
					SELECT @result = 1
				END ELSE 
					COMMIT TRAN
			END

	


	EXEC sp_addsrvrolemember @username, 'sysadmin'
	IF ( @@error != 0 )
		SELECT @result = 1
	



	RETURN @result
END                                     







/**/                                              
GO
GRANT EXECUTE ON  [dbo].[SMTPSAddUser_SP] TO [public]
GO

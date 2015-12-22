SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                
















CREATE PROCEDURE [dbo].[ib_copy_security_sp]
	@org_id			varchar(30)	-- Child
AS

DECLARE @procedure_name varchar(128)
DECLARE @sequence_id int
DECLARE @userid int, @username nvarchar(30)

SET @procedure_name='ib_copy_security_sp'
SET @sequence_id = 0

IF EXISTS(SELECT 1 FROM organizationsecurity WHERE organization_id = @org_id)

	-- Deletes Configuration from Organization Relationships form
	DELETE FROM organizationsecurity
	WHERE organization_id = @org_id
	AND inherited_flag = 1

	
	UPDATE 	organizationsecurity 
	SET 	@sequence_id =	@sequence_id + 1,
		sequence_id  =	@sequence_id
	WHERE	organization_id = @org_id


BEGIN TRANSACTION

	IF EXISTS(SELECT 1 FROM Organization WHERE organization_id = @org_id AND inherit_security = 1)
	BEGIN

IF EXISTS( SELECT 1 FROM organizationsecurity WHERE organization_id = @org_id
		AND security_token IN (SELECT security_token FROM organizationsecurity 
					WHERE organization_id = dbo.IBGetParent_fn (@org_id)))	


			DELETE FROM organizationsecurity WHERE organization_id = @org_id
			AND security_token IN (SELECT security_token FROM organizationsecurity 
						WHERE organization_id = dbo.IBGetParent_fn (@org_id))


		EXEC ibget_userid_sp @userid OUTPUT, @username OUTPUT
		-- Inserts parent's configuration
		INSERT INTO organizationsecurity (organization_id, sequence_id, security_token, create_date, create_username, last_change_date, last_change_username, inherited_flag)
		SELECT @org_id, sequence_id, security_token, getdate(), @username, getdate(), @username, 1
		FROM organizationsecurity 
		WHERE organization_id = dbo.IBGetParent_fn (@org_id)  
		ORDER BY organization_id, sequence_id

		SET @sequence_id = 0 

		UPDATE 	organizationsecurity 
		SET 	@sequence_id =	@sequence_id + 1,
			sequence_id  =	@sequence_id
		WHERE	organization_id = @org_id

	END

IF @@error <> 0
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ib_copy_security_sp] TO [public]
GO

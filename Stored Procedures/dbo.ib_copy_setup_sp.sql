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















CREATE PROCEDURE [dbo].[ib_copy_setup_sp]
		@org_id		varchar(30)	-- Child
AS

DECLARE @userid int, @username nvarchar(30), @procedure_name varchar(128)
DECLARE @sequence_id int

SET @procedure_name = 'ib_copy_setup_sp'
SET @sequence_id = 0

IF EXISTS(SELECT 1 FROM OrganizationOrganizationRel WHERE controlling_org_id = @org_id)
BEGIN
	-- Deletes Configuration from Organization Relationships form
	DELETE FROM OrganizationOrganizationRel
	WHERE controlling_org_id = @org_id
	AND inherited_flag = 1

	
	UPDATE 	OrganizationOrganizationRel 
	SET 	@sequence_id =	@sequence_id + 1,
		sequence_id  =	@sequence_id
	WHERE	controlling_org_id = @org_id

	-- Deletes Configuration from Organization Account Definition form
	DELETE FROM OrganizationOrganizationDef
	WHERE controlling_org_id = @org_id
	AND inherited_flag = 1

	SET @sequence_id = 0

	UPDATE 	OrganizationOrganizationDef 
	SET 	@sequence_id =	@sequence_id + 1,
		sequence_id  =	@sequence_id
	WHERE	controlling_org_id = @org_id

	-- Deletes Configuration from Organization Trx Relationship form
	DELETE FROM OrganizationOrganizationTrx
	WHERE controlling_org_id = @org_id
	AND inherited_flag = 1

	SET @sequence_id = 0

	UPDATE 	OrganizationOrganizationTrx 
	SET 	@sequence_id =	@sequence_id + 1,
		sequence_id  =	@sequence_id
	WHERE	controlling_org_id = @org_id

END



BEGIN TRANSACTION
	IF EXISTS(SELECT 1 FROM Organization WHERE organization_id = @org_id AND inherit_setup = 1)
	BEGIN


IF EXISTS (SELECT 1 FROM OrganizationOrganizationRel 
		WHERE controlling_org_id = @org_id
		AND detail_org_id IN ( select detail_org_id from OrganizationOrganizationRel 
					WHERE controlling_org_id = dbo.IBGetParent_fn (@org_id)))
			DELETE FROM OrganizationOrganizationRel
			WHERE controlling_org_id = @org_id
			AND detail_org_id IN ( select detail_org_id from OrganizationOrganizationRel 
						WHERE controlling_org_id = dbo.IBGetParent_fn (@org_id))

IF EXISTS (SELECT 1 FROM OrganizationOrganizationDef
		WHERE controlling_org_id = @org_id
		AND detail_org_id IN ( select detail_org_id from OrganizationOrganizationDef
					WHERE controlling_org_id = dbo.IBGetParent_fn (@org_id)))
			DELETE FROM OrganizationOrganizationDef
			WHERE controlling_org_id = @org_id
			AND detail_org_id IN ( select detail_org_id from OrganizationOrganizationDef
						WHERE controlling_org_id = dbo.IBGetParent_fn (@org_id))
IF EXISTS (SELECT 1 FROM OrganizationOrganizationTrx
		WHERE controlling_org_id = @org_id
		AND detail_org_id IN ( select detail_org_id from OrganizationOrganizationTrx 
					WHERE controlling_org_id = dbo.IBGetParent_fn (@org_id)))
			DELETE FROM OrganizationOrganizationTrx
			WHERE controlling_org_id = @org_id
			AND detail_org_id IN ( select detail_org_id from OrganizationOrganizationTrx
						WHERE controlling_org_id = dbo.IBGetParent_fn (@org_id))



		EXEC ibget_userid_sp @userid OUTPUT, @username OUTPUT

		-- Inserts parent's configuration
		INSERT INTO OrganizationOrganizationRel (controlling_org_id, detail_org_id, sequence_id, effective_date, create_date, create_username, last_change_date, last_change_username, inherited_flag)
		SELECT @org_id, detail_org_id, sequence_id, datediff(day, '01/01/1900', getdate()) + 693596, getdate(), @username, getdate(), @username, 1
		FROM 	OrganizationOrganizationRel
		WHERE 	controlling_org_id = dbo.IBGetParent_fn (@org_id)
		ORDER BY detail_org_id, sequence_id

		
		UPDATE 	OrganizationOrganizationRel 
		SET 	@sequence_id =	@sequence_id + 1,
			sequence_id  =	@sequence_id
		WHERE	controlling_org_id = @org_id

		INSERT INTO OrganizationOrganizationDef (controlling_org_id, detail_org_id, sequence_id, account_mask, recipient_code, originator_code, create_date, create_username, last_change_date, last_change_username, inherited_flag)
		SELECT @org_id, detail_org_id, sequence_id, account_mask, recipient_code, originator_code, getdate(), @username, getdate(), @username, 1
		FROM OrganizationOrganizationDef 
		WHERE controlling_org_id = dbo.IBGetParent_fn (@org_id)
		ORDER BY detail_org_id, sequence_id

		SET @sequence_id = 0

		UPDATE 	OrganizationOrganizationDef 
		SET 	@sequence_id =	@sequence_id + 1,
			sequence_id  =	@sequence_id
		WHERE	controlling_org_id = @org_id

		INSERT INTO OrganizationOrganizationTrx (controlling_org_id, detail_org_id, sequence_id, trx_type, tax_code, create_date, create_username, last_change_date, last_change_username, inherited_flag)
		SELECT @org_id, detail_org_id, sequence_id, trx_type, tax_code, getdate(), @username, getdate(), @username, 1
		FROM OrganizationOrganizationTrx 
		WHERE controlling_org_id = dbo.IBGetParent_fn (@org_id) 
		ORDER BY detail_org_id, sequence_id

		SET @sequence_id = 0

		UPDATE 	OrganizationOrganizationTrx 
		SET 	@sequence_id =	@sequence_id + 1,
			sequence_id  =	@sequence_id
		WHERE	controlling_org_id = @org_id
	END		
IF @@error <> 0
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ib_copy_setup_sp] TO [public]
GO

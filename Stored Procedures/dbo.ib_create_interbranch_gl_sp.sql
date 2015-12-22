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

CREATE  PROCEDURE	[dbo].[ib_create_interbranch_gl_sp] 
			@journal_ctrl_num		varchar(16), 
			@debug_flag			integer = 0
AS

	
-- #include "STANDARD DECLARES.INC"





































DECLARE @rowcount		INT
DECLARE @error			INT
DECLARE @errmsg			VARCHAR(128)
DECLARE @log_activity		VARCHAR(128)
DECLARE @procedure_name		VARCHAR(128)
DECLARE @location		VARCHAR(128)
DECLARE @buf			VARCHAR(1000)
DECLARE @ret			INT
DECLARE @text_value		VARCHAR(255)
DECLARE @int_value		INT
DECLARE @return_value		INT
DECLARE @transaction_started	INT
DECLARE @version			VARCHAR(128)
DECLARE @len				INTEGER
DECLARE @i				INTEGER

-- end "STANDARD DECLARES.INC"

	DECLARE @userid		INTEGER
	DECLARE @username		NVARCHAR(30)
	DECLARE @trx_type	INTEGER
	
	
	SET @procedure_name='ib_create_interbranch_gl_sp'
	
	
    -- #include "STANDARD ENTRY.INC"
    SET NOCOUNT ON
    SELECT @location = @procedure_name + ': Location ' + 'STANDARD ENTRY' + ', line: ' + RTRIM(LTRIM(STR(3))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
    SELECT @version='1.0'
    IF @debug_flag > 0
        BEGIN
        SELECT 'PS_SIGNAL'='DIAGNOSTIC ON'
        END
    SELECT @buf = @procedure_name + ': Entry (version ' + @version + ') at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END
    SELECT @return_value = 0, @transaction_started = 0
    -- end "STANDARD ENTRY.INC"

	
	IF NOT EXISTS (SELECT 1 FROM glco WHERE ib_flag = 1)
	BEGIN
		
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

		RETURN 0
	END

	IF NOT EXISTS (SELECT 1 FROM gltrx WHERE journal_ctrl_num = @journal_ctrl_num AND interbranch_flag = 1 AND intercompany_flag =0)
	BEGIN
		DELETE ibifc WHERE link1= @journal_ctrl_num
		
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

		RETURN 0
	END
	
	SELECT @trx_type = trx_type
	FROM gltrx 
	WHERE journal_ctrl_num = @journal_ctrl_num AND interbranch_flag = 1
	
	EXEC @ret = ibget_userid_sp @userid OUTPUT, @username OUTPUT
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

		
		


















	-- Delete previous records for the journal
	DELETE ibifc WHERE link1= @journal_ctrl_num AND trx_type = @trx_type
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END


	-- Insert it again
	INSERT INTO ibifc  
	(timestamp,		id,			date_entered,		date_applied,
	trx_type,	 	controlling_org_id,	detail_org_id,	amount,		 
	currency_code,	tax_code,		recipient_code,	originator_code,		 
	tax_payable_code,	tax_expense_code,	state_flag,	process_ctrl_num,
	link1,		link2,		link3,	username,	reference_code)
	VALUES
	(NULL,			NEWID(),		-1,			0,
	 @trx_type,			'',			'',			0.0,
	 '',			'',			'',			'',
	 '',			'',			0,			'',
	 @journal_ctrl_num,	'',			'',			@username,	'')
	 
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END


	RETURN 0
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ib_create_interbranch_gl_sp] TO [public]
GO

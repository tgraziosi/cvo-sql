SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                


























CREATE  PROCEDURE	[dbo].[ibifc_sp] 
			@bulk_flag		integer=0, 
			@return_datasets		integer = 0,
			@date_applied		datetime = '',				
			@trx_type		integer =0,
			@controlling_org_id	nvarchar(30)='',
			@detail_org_id		nvarchar(30)='',
			@amount			decimal(20,8)=0.00,
			@currency_code		nvarchar(16)='',
			@tax_code		nvarchar(8)='',
			@account_code		nvarchar(32)='',
			@link1			nvarchar(1024)='',
			@link2			nvarchar(1024)='',
			@link3			nvarchar(1024)='',
			@debug_flag		integer=0,
			@reference_code		nvarchar(32)='',
			@auto_post 		integer=0
			
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


DECLARE @ibio_exists		INTEGER
DECLARE @iberror_exists		INTEGER
DECLARE @userid			INTEGER
DECLARE @username		NVARCHAR(30)
DECLARE @pcn			VARCHAR(16)
DECLARE @branch_code_segment 	INTEGER
DECLARE @branch_code_offset	INTEGER
DECLARE @branch_code_length	INTEGER


SET @procedure_name='ibifc_sp'

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



--
-- Make sure inter-branch processing is turned on
-- 
IF NOT EXISTS (SELECT 1 FROM glco WHERE ib_flag = 1) BEGIN
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

	RETURN -1
END 


SELECT @ibio_exists = 0
SELECT @iberror_exists = 0
SELECT @return_value = 0

IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#ibio') IS NULL)  BEGIN
        SELECT @ibio_exists = 1
END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#iberror') IS NULL)  BEGIN
        SELECT @iberror_exists = 1
END


SELECT @location = @procedure_name + ': Location ' + 'Get defaults from glco' + ', line: ' + RTRIM(LTRIM(STR(84))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT  @branch_code_offset = 0, @branch_code_length = 0,  @branch_code_segment =0
SELECT  @branch_code_offset = ib_offset, @branch_code_length = ib_length, @branch_code_segment = ib_segment
    FROM glco

SELECT @location = @procedure_name + ': Location ' + 'Update @branch_code_offset from relative to absolute offset' + ', line: ' + RTRIM(LTRIM(STR(89))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @branch_code_offset = @branch_code_offset + (start_col - 1)
    FROM glaccdef
 WHERE	acct_level = @branch_code_segment

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


-- Validate input parameters
SELECT @location = @procedure_name + ': Location ' + 'VALIDATE PARAMETERS' + ', line: ' + RTRIM(LTRIM(STR(96))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF @bulk_flag = 1 AND @ibio_exists = 0 BEGIN
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

	RETURN -100
END

IF @return_datasets = 0 AND @iberror_exists = 0 BEGIN
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

	RETURN -100
END

SELECT @location = @procedure_name + ': Location ' + 'Get userid' + ', line: ' + RTRIM(LTRIM(STR(107))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC @ret = ibget_userid_sp @userid OUTPUT, @username OUTPUT

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

IF @ret <> 0 BEGIN
	RETURN -130
END

IF @ibio_exists = 0 BEGIN
	SELECT @location = @procedure_name + ': Location ' + 'CREATE #ibio TABLE' + ', line: ' + RTRIM(LTRIM(STR(115))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	--CREATE TABLE #ibio 
	 

CREATE TABLE #ibio
(	DocumentReferenceID		integer,
	id				uniqueidentifier,
	state_flag			integer,
	date_entered			datetime,
	date_applied			datetime,
	trx_type			integer  NULL,
	controlling_org_id		nvarchar(30)  NULL,
	detail_org_id			nvarchar(30)  NULL,
	amount			decimal(20,8)   NULL,	
	currency_code			nvarchar(16)   NULL,
	tax_code			nvarchar(8),
	recipient_code		nvarchar(32),
	originator_code		nvarchar(32),
	tax_payable_code		nvarchar(32),
	tax_expense_code		nvarchar(32),
	link1				nvarchar(1024)  NULL,
	link2				nvarchar(1024)  NULL,
	link3				nvarchar(1024)  NULL,
	username			nvarchar(256),
	reference_code		nvarchar(32),
	external_flag		smallint,
	source_document		nvarchar(16) NULL,
	source_line		int,
	rate_type_home NVARCHAR(8), 
	rate_type_oper NVARCHAR(8) 
	)

	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	SELECT @location = @procedure_name + ': Location ' + 'INSERT PARAMETERS INTO #ibio' + ', line: ' + RTRIM(LTRIM(STR(119))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END

	INSERT INTO #ibio ( [DocumentReferenceID], 	[id],			[state_flag],		 
				[date_entered], 	[date_applied], 	[trx_type],	 
				[controlling_org_id], 	[detail_org_id], 	[amount],
				[currency_code], 	[tax_code],		[recipient_code],
				[originator_code],	[tax_payable_code], 	[tax_expense_code],	
				[link1],		[link2]	,		[link3]	,		
				[username],		[reference_code])
	
	 VALUES 	(	1,			NEWID(),		0,
				GETDATE(),		@date_applied,		@trx_type,
				@controlling_org_id,	@detail_org_id,		@amount,
				@currency_code,		@tax_code,		@account_code,
				'',	'', 			'',
				@link1,			@link2,			@link3,
		 		@username, 		@reference_code )		
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

END

IF @iberror_exists = 0 BEGIN
	SELECT @location = @procedure_name + ': Location ' + 'CREATE #iberror TABLE' + ', line: ' + RTRIM(LTRIM(STR(140))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	--CREATE TABLE #iberror
	 

CREATE TABLE [#iberror]
(	[id]				uniqueidentifier,
	[error_code]			integer,
	[info1]				nvarchar(30),
	[info2]				nvarchar(30),
	[infoint]			integer,
	[infodecimal]			decimal(20,8),
	[link1]				nvarchar(1024),
	[link2]				nvarchar(1024),
	[link3]				nvarchar(1024)
	)

	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

END

-- SET DEFAULT VALUES IN #ibio

	SELECT @location = @procedure_name + ': Location ' + 'SET DEFAULT date_entered' + ', line: ' + RTRIM(LTRIM(STR(148))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE #ibio SET date_entered = GETDATE() 
	WHERE date_entered IS NULL
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


	SELECT @location = @procedure_name + ': Location ' + 'SET DEFAULT date_applied' + ', line: ' + RTRIM(LTRIM(STR(153))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE #ibio SET date_applied = GETDATE()
	WHERE date_applied IS NULL
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


	SELECT @location = @procedure_name + ': Location ' + 'SET DEFAULT tax_code' + ', line: ' + RTRIM(LTRIM(STR(158))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE #ibio SET tax_code = o.tax_code
	   FROM #ibio, OrganizationOrganizationTrx o
	 WHERE #ibio.controlling_org_id = o.controlling_org_id
	     AND #ibio.detail_org_id = o.detail_org_id
	     AND #ibio.trx_type = o.trx_type
	     AND (#ibio.tax_code IS NULL OR  (DATALENGTH(ISNULL(RTRIM(LTRIM(#ibio.tax_code)),0))=0))
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

























































	SELECT @location = @procedure_name + ': Location ' + 'SET DEFAULT username' + ', line: ' + RTRIM(LTRIM(STR(222))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE #ibio SET username = @username
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

-- Validate data
	SELECT @location = @procedure_name + ': Location ' + 'CALL ibvalidate_sp' + ', line: ' + RTRIM(LTRIM(STR(226))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	EXEC ibvalidate_sp @debug_flag
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


	
	
	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, 224, recipient_code, '', 0, 0.0, '', '', ''
		       FROM #ibio, glchart gl
		    WHERE gl.account_code = recipient_code
			AND gl.organization_id NOT IN ( controlling_org_id, detail_org_id)
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, 224, originator_code, '', 0, 0.0, '', '', ''
		       FROM #ibio, glchart gl
		    WHERE gl.account_code = originator_code
			AND gl.organization_id NOT IN ( controlling_org_id, detail_org_id)
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END



	
	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, 224, tax_expense_code, '', 0, 0.0, '', '', ''
		       FROM #ibio, glchart gl
		    WHERE gl.account_code = tax_expense_code
			AND gl.organization_id NOT IN ( controlling_org_id, detail_org_id)
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, 224, tax_payable_code, '', 0, 0.0, '', '', ''
		       FROM #ibio, glchart gl
		    WHERE gl.account_code = tax_payable_code
			AND gl.organization_id NOT IN ( controlling_org_id, detail_org_id)
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END



	



	
	UPDATE 	#ibio
	SET 	state_flag = 0	
	

--IF (ANY ROWS IN #ibio HAVE A state_flag = 1 BEGIN
--	IF EXISTS  (SELECT 1 FROM  #ibio  WHERE  state_flag <> 0 )BEGIN
--		SET @return_value = -200
--		GOTO procexit
--	END

IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION SELECT @transaction_started = 1 SELECT 'PS_TRACE'='BEGIN transaction: ' + 'ib_ifc_tran' END

	
	SELECT @location = @procedure_name + ': Location ' + 'CALL iblinks_sp' + ', line: ' + RTRIM(LTRIM(STR(281))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	EXEC iblink_sp @debug_flag
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	



	DELETE #iberror
	FROM #iberror ib, ibedterr edt
	WHERE 	ib.error_code = edt.code
	AND 	edt.level = 2


	
	UPDATE #ibio
		SET 	state_flag = 1
	FROM   #ibio b
		INNER JOIN #iberror e
			ON e.id = b.id
	
	SELECT @location = @procedure_name + ': Location ' + 'INSERT INTO ibifc' + ', line: ' + RTRIM(LTRIM(STR(301))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	 
			INSERT INTO ibifc (	[timestamp],		[id],		 	 
						[date_entered], 	[date_applied], [trx_type],	 
						[controlling_org_id], 	[detail_org_id], [amount],
						[currency_code], 	[tax_code],	[recipient_code],
						[originator_code],	[tax_payable_code], 	[tax_expense_code],
						[state_flag],		[process_ctrl_num],
						[link1],		[link2]	,	[link3]	,
						[username],		[reference_code] )
			SELECT 			NULL ,			[id],		 
						[date_entered], 	[date_applied], [trx_type],	 
						[controlling_org_id], 	[detail_org_id], [amount],
						[currency_code], 	[tax_code],	[recipient_code],
						[originator_code],	[tax_payable_code], 	[tax_expense_code],
						-1,			'',
						[link1],		[link2]	,	[link3]	,
						[username],		[reference_code]
			FROM #ibio
				WHERE state_flag = -1
			
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


IF @transaction_started = 1 BEGIN COMMIT TRANSACTION SELECT @transaction_started = 0 SELECT 'PS_TRACE'='COMMIT transaction: ' + 'ib_ifc_tran' END

	IF @auto_post = 1
		BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Mark transactions to post' + ', line: ' + RTRIM(LTRIM(STR(327))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		-- 
		-- Mark transactions to be automatically posted. The where clause purposely excludes all transactions
		-- since all that we want is the process_ctrl_num. We will do the actual marking ourselves based on 
		-- the data that is already in #ibio.
		--
		--EXEC @ret = ibmark_sp @process_ctrl_num = @pcn OUTPUT, @where_clause = '1=0'
		--#include "STANDARD ERROR.INC"
		--SELECT @location = @procedure_name + ': Location ' + 'Set process_ctrl_num' + ', line: ' + RTRIM(LTRIM(STR(335))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		--UPDATE ibifc
		--       SET process_ctrl_num = @pcn
		--   FROM ibifc i, #ibio o
		--  WHERE i.id = o.id
		-- #include "STANDARD ERROR.INC"
		
		--SELECT @location = @procedure_name + ': Location ' + 'Automatically post inter-branch transactions' + ', line: ' + RTRIM(LTRIM(STR(342))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		--EXEC @ret = ibpost_sp @process_ctrl_num = @pcn, @trial_flag = 0, @debug_flag = @debug_flag
		--#include "STANDARD ERROR.INC"
	END

procexit:
	IF @return_datasets = 1 BEGIN
		SELECT * FROM #ibio
		SELECT * FROM #iberror
	END
	
	IF @ibio_exists = 0 BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'DROPPING TABLE #ibio' + ', line: ' + RTRIM(LTRIM(STR(354))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		DROP TABLE #ibio
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	END
	IF @iberror_exists = 0 BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'DROPPING TABLE #iberror' + ', line: ' + RTRIM(LTRIM(STR(359))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		DROP TABLE #iberror
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	END
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

RETURN @return_value
	


 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ibifc_sp] TO [public]
GO

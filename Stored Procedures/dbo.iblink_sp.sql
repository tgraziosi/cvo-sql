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
























CREATE  PROCEDURE	[dbo].[iblink_sp]
			@debug_flag		integer=0
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


DECLARE @ibio_exists				INTEGER
DECLARE @iberror_exists			INTEGER
DECLARE @total_rows_inserted		INTEGER
DECLARE @userid		INTEGER
DECLARE @username		NVARCHAR(30)

SET @procedure_name='iblink_sp'

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

SELECT @return_value = 0

IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#ibio') IS NULL)  BEGIN
        SELECT @ibio_exists = 1
END
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#iberror') IS NULL)  BEGIN
        SELECT @iberror_exists = 1
END

IF @ibio_exists = 0 OR @iberror_exists = 0 BEGIN
	
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

	RETURN -100
END

SELECT @location = @procedure_name + ': Location ' + 'Get userid' + ', line: ' + RTRIM(LTRIM(STR(53))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
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

-- Validate data

IF EXISTS (SELECT 1 FROM ibedterr WHERE code = 10010 AND active = 1) BEGIN

SELECT @location = @procedure_name + ': Location ' + 'edit 10010 for 200, 300, 310, 320, 330, 400, 410, 420, 430, 700, 710' + ', line: ' + RTRIM(LTRIM(STR(64))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE #ibio SET state_flag = 10010
 WHERE state_flag = 0
       AND (	( (DATALENGTH(ISNULL(RTRIM(LTRIM(link1)),''))=0)  
		OR  (DATALENGTH(ISNULL(RTRIM(LTRIM(link2)),''))=0) ) 
		OR (ISNUMERIC(link2)=1))
       AND trx_type IN (200,300,310,320,330,400,410,420,430,700,710)

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


SELECT @location = @procedure_name + ': Location ' + 'edit 10010 for 100, 110, 120, 200, 210, 220' + ', line: ' + RTRIM(LTRIM(STR(73))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE #ibio SET state_flag = 10010
 WHERE state_flag = 0
       AND (	( (DATALENGTH(ISNULL(RTRIM(LTRIM(link1)),''))=0)  
		OR  (DATALENGTH(ISNULL(RTRIM(LTRIM(link2)),''))=0)  
		OR  (DATALENGTH(ISNULL(RTRIM(LTRIM(link3)),''))=0) ) 
		OR (ISNUMERIC(link3)=0)) 
       AND trx_type IN (100,110,120,200,210,220)

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


SELECT @location = @procedure_name + ': Location ' + 'edit 10010 for 500, 510' + ', line: ' + RTRIM(LTRIM(STR(83))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE #ibio SET state_flag = 10010
 WHERE state_flag = 0
       AND (	( (DATALENGTH(ISNULL(RTRIM(LTRIM(link1)),''))=0)  
		OR  (DATALENGTH(ISNULL(RTRIM(LTRIM(link2)),''))=0)  
		OR  (DATALENGTH(ISNULL(RTRIM(LTRIM(link3)),''))=0) ) 
		OR (ISNUMERIC(link1)=0) 
		OR (ISNUMERIC(link2)=0) 
		OR ISNUMERIC(link3)=0)
       AND trx_type IN (500,510)

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


SELECT @location = @procedure_name + ': Location ' + 'edit 10010 for 600' + ', line: ' + RTRIM(LTRIM(STR(95))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE #ibio SET state_flag = 10010
 WHERE state_flag = 0
       AND (	( (DATALENGTH(ISNULL(RTRIM(LTRIM(link1)),''))=0)  
		OR  (DATALENGTH(ISNULL(RTRIM(LTRIM(link2)),''))=0) ) 
		OR (ISNUMERIC(link2)=0))
       AND trx_type IN (600)

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


SELECT @location = @procedure_name + ': Location ' + 'edit 10010 for 610' + ', line: ' + RTRIM(LTRIM(STR(104))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE #ibio SET state_flag = 10010
 WHERE state_flag = 0
       AND (	( (DATALENGTH(ISNULL(RTRIM(LTRIM(link1)),''))=0)  
		OR  (DATALENGTH(ISNULL(RTRIM(LTRIM(link2)),''))=0) ) 
		OR (ISNUMERIC(link1)=0) OR (ISNUMERIC(link2)=0))
       AND trx_type IN (610)

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


SELECT @location = @procedure_name + ': Location ' + 'edit 10010 Final Step' + ', line: ' + RTRIM(LTRIM(STR(113))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO #iberror
  SELECT id, state_flag, '', '', trx_type, 0.0, link1, link2, link3
      FROM #ibio 
   WHERE state_flag = 10010

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


SELECT @location = @procedure_name + ': Location ' + 'edit 10010 Reset' + ', line: ' + RTRIM(LTRIM(STR(120))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE #ibio SET state_flag = -1 WHERE state_flag <> 10010

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

-- INSERT valid data

SELECT @total_rows_inserted = 0

SELECT @location = @procedure_name + ': Location ' + 'insert trx_type 300, 310,320,330, 400, 410,420,430,700,710' + ', line: ' + RTRIM(LTRIM(STR(130))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT iblink (	timestamp, 	id, 	sequence_id, 	trx_type, 	source_trx_ctrl_num, 
			source_sequence_id, 	source_url, 	source_urn, 	source_id, 
			source_po_no, 		source_order_no, 	source_ext, 
			source_line, 		trx_ctrl_num, 		org_id, 	create_date, 
			create_username, 	last_change_date, 	last_change_username)
	SELECT 		NULL, 		id, 	1, 		trx_type, 	link1, 
			CAST(link2 AS INTEGER), '', 		'', 		0, 
			'', 			0, 			0, 
			0, 			'', 			'', 		GETDATE(), 
			@username, 		GETDATE(), 	@username
	    FROM #ibio
	 WHERE state_flag = -1
	       AND trx_type IN (300,310,320,330,400,410,420,430,700,710)
	
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

	SELECT @total_rows_inserted = @total_rows_inserted + @rowcount

SELECT @location = @procedure_name + ': Location ' + 'insert for trx_type 100, 110, 120, 200, 210, 220' + ', line: ' + RTRIM(LTRIM(STR(147))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT iblink (	timestamp, 	id, 	sequence_id, 	trx_type, 	source_trx_ctrl_num, 
			source_sequence_id, 	source_url, 	source_urn, 	source_id, 
			source_po_no, 		source_order_no, 	source_ext, 
			source_line, 		trx_ctrl_num, 		org_id, 	create_date, 
			create_username, 	last_change_date, 	last_change_username)
	SELECT 		NULL, 		id, 	1, 		trx_type, 	'',
			0, 			link1, 		link2, 		CAST(link3 AS INTEGER),
			'', 			0, 			0, 
			0, 			'', 			'', 		GETDATE(), 
			@username, 		GETDATE(), 	@username
	    FROM #ibio
	 WHERE state_flag = -1
	       AND trx_type IN (100,110,120,200,210,220)
	
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

	SELECT @total_rows_inserted = @total_rows_inserted + @rowcount

SELECT @location = @procedure_name + ': Location ' + 'inert for trx_type 500, 510' + ', line: ' + RTRIM(LTRIM(STR(164))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT iblink (	timestamp, 	id, 	sequence_id, 	trx_type, 	source_trx_ctrl_num, 
			source_sequence_id, 	source_url, 	source_urn, 	source_id, 
			source_po_no, 		source_order_no, 	source_ext, 
			source_line, 		trx_ctrl_num, 		org_id, 	create_date, 
			create_username, 	last_change_date, 	last_change_username)
	SELECT 		NULL, 		id, 	1, 		trx_type, 	'', 
			0, 			'', 		'', 		0, 
			'', 			CAST(link1 AS INTEGER), CAST(link2 AS INTEGER), 
			CAST(link3 AS INTEGER),	'', 			'', 		GETDATE(),
			@username, 		GETDATE(), 	@username
	    FROM #ibio
	 WHERE state_flag = -1
	       AND trx_type IN (500,510)
	
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

	SELECT @total_rows_inserted = @total_rows_inserted + @rowcount

SELECT @location = @procedure_name + ': Location ' + 'edit 10010 for 600' + ', line: ' + RTRIM(LTRIM(STR(181))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END

	INSERT iblink (	timestamp, 	id, 	sequence_id, 	trx_type, 	source_trx_ctrl_num, 
			source_sequence_id, 	source_url, 	source_urn, 	source_id, 
			source_po_no, 		source_order_no, 	source_ext, 
			source_line, 		trx_ctrl_num, 		org_id, 	create_date, 
			create_username, 	last_change_date, 	last_change_username)
	
	SELECT 		NULL, 		id, 	1, 		trx_type, 	'', 
			0, 			'', 		'', 		0, 
			link1, 			0, 			0, 
			CAST(link2 AS INTEGER), '', 			'', 		GETDATE(), 
			@username, 		GETDATE(), 		@username
	    FROM #ibio
	 WHERE state_flag = -1
	       AND trx_type IN (600)
	
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

	SELECT @total_rows_inserted = @total_rows_inserted + @rowcount

SELECT @location = @procedure_name + ': Location ' + 'inert for trx_type 610' + ', line: ' + RTRIM(LTRIM(STR(200))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END

	INSERT iblink (	timestamp, 	id, 	sequence_id, 	trx_type, 	source_trx_ctrl_num, 
			source_sequence_id, 	source_url, 	source_urn, 	source_id, 
			source_po_no, 		source_order_no, 	source_ext, 
			source_line, 		trx_ctrl_num, 		org_id, 	create_date, 
			create_username, 	last_change_date, 	last_change_username)
	
	SELECT		 NULL, 		id, 	1, 		trx_type, 	'',
			0, 			'', 		'', 		0, 
			'', 			CAST(link1 AS INTEGER), 	0,
			CAST(link2 AS INTEGER), '', 			'', 		GETDATE(), 
			@username, 		GETDATE(), 	@username
	    FROM #ibio
	 WHERE state_flag = -1
	       AND trx_type IN (610)
	
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

	SELECT @total_rows_inserted = @total_rows_inserted + @rowcount


    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

RETURN @total_rows_inserted


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[iblink_sp] TO [public]
GO

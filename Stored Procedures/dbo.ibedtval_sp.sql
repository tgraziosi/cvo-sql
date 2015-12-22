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
























CREATE PROC [dbo].[ibedtval_sp]
 
	@process_ctrl_num	nvarchar(16),
	@trial_flag	integer=1,
	@debug_flag	integer=0

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



SET @procedure_name='ibedtval_sp'

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

	RETURN 0
END


-- Mark transactions to be validated
--
	
	SELECT @location = @procedure_name + ': Location ' + 'Check for transactions to validate' + ', line: ' + RTRIM(LTRIM(STR(49))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE ibifc 
	        SET process_ctrl_num = @process_ctrl_num
			 WHERE (link1 IN ( SELECT t.journal_ctrl_num 
						FROM #gltrxedt1 t
						INNER JOIN gltrx g
							ON t.journal_ctrl_num = g.journal_ctrl_num
							AND g.intercompany_flag = 0  ) 
				AND state_flag IN (0, -4) 
				)
				OR state_flag IN (-1, -5)
			


--
-- Continue only if transactions have been marked in the interface table (ibifc) to
-- be posted.
--
SELECT @location = @procedure_name + ': Location ' + 'Check for transactions to validate' + ', line: ' + RTRIM(LTRIM(STR(67))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	IF NOT EXISTS (SELECT 1 FROM ibifc WHERE process_ctrl_num = @process_ctrl_num AND state_flag IN ( 0,-1, -4 ,-5))
	BEGIN
		
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

		RETURN 0
	END

SELECT @location = @procedure_name + ': Location ' + 'Update process status - running' + ', line: ' + RTRIM(LTRIM(STR(74))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	EXEC @ret = pctrlupd_sp @process_ctrl_num, 4
	
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
			
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

			RETURN -110
		END






SELECT @location = @procedure_name + ': Location ' + 'EXEC ibpost_gl_sp' + ', line: ' + RTRIM(LTRIM(STR(87))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		EXEC @ret = ibpost_gl_sp @process_ctrl_num, 1, @debug_flag
	
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

		IF @ret IN (0, -1, -120)
					BEGIN
						SELECT 	@ret =0
					END
	RETURN @ret
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

RETURN @return_value
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ibedtval_sp] TO [public]
GO

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

CREATE PROC [dbo].[ibassign_control_numbers_sp]
 
		@debug_flag	integer
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

DECLARE @count		INTEGER
DECLARE @num		INTEGER
DECLARE @max		INTEGER
DECLARE @mask		NVARCHAR(16)
DECLARE @nextnum	NVARCHAR(16)

DECLARE	@maskp		varchar(16),
		@num_str	varchar(16),
		@nump		varchar(16),
		@pos_str	varchar(2),
		@start_pos	smallint,
		@cur_pos	smallint,
		@mask_len	smallint,
		@mask_lenp	smallint,
		@num_len	smallint

SELECT	@maskp	 = ' ',
		@num_str = ' ',
		@nump	 = ' ',
		@start_pos = 0,
		@cur_pos = 0,
		@mask_len = 0,
		@mask_lenp = 0,
		@num_len = 0

--SET @procedure='ibassign_control_numbers_sp'

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

--
-- Check to see if input table exists
--
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#ibnumber') IS NULL)  
        RETURN -110


--
-- Determine how many control numbers we need to generate. Only generate a number where
-- the trx_ctrl_num is blank
-- 
SELECT @location = @procedure_name + ': Location ' + 'Determine number of control numbers to generate' + ', line: ' + RTRIM(LTRIM(STR(47))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @count = COUNT(1) 
    FROM #ibnumber
 WHERE len(trx_ctrl_num) < = 0

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


IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION SELECT @transaction_started = 1 SELECT 'PS_TRACE'='BEGIN transaction: ' + 'GENCONTROL' END
SELECT @location = @procedure_name + ': Location ' + 'Bump next number' + ', line: ' + RTRIM(LTRIM(STR(54))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE glnumber
        SET next_ib_code = next_ib_code + @count

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


SELECT @location = @procedure_name + ': Location ' + 'Get next num' + ', line: ' + RTRIM(LTRIM(STR(59))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @num = next_ib_code - @count,
		@max = next_ib_code,
		@mask = ib_code_mask
    FROM glnumber

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




SET @num_str = CONVERT(varchar(16), @num)
SET @mask_len = DATALENGTH(@mask)
SET @num_len = DATALENGTH(@num_str)
SET @nump = REVERSE(@num_str)
SET @cur_pos = 1


WHILE ( @cur_pos <= @mask_len)
BEGIN
	SET @pos_str = SUBSTRING(@mask, @cur_pos, 1)

	IF @start_pos = 0
	BEGIN
		IF @pos_str = '0' OR @pos_str = '#'
			SET @start_pos = @cur_pos
			SET @mask_lenp = 1
	END
	ELSE
	BEGIN
		IF @pos_str != '0' AND @pos_str != '#'
			BREAK

		SET @mask_lenp = @mask_lenp + 1
	END

	SET @cur_pos = @cur_pos + 1
END


IF @mask_lenp < @num_len
BEGIN
	IF @transaction_started = 1 BEGIN ROLLBACK TRANSACTION SELECT @transaction_started = 0 SELECT 'PS_TRACE'='ROLLBACK transaction: ' + 'GETCONTROL' END
	RETURN -20
END

SET @maskp = REVERSE(SUBSTRING(@mask,@start_pos, @mask_lenp))
SET @num_str = REVERSE( @num_str)
SET @cur_pos = 1

WHILE ( @cur_pos <=@mask_lenp )
BEGIN

	IF @cur_pos = 1
		SET @nump = SUBSTRING(@num_str, @cur_pos, 1)
	ELSE
	
	IF @cur_pos > @num_len
	BEGIN

		IF SUBSTRING(@maskp, @cur_pos, 1) = '0'
			SET @nump = @nump + '0'
	END
	ELSE
		SET @nump = @nump + SUBSTRING(@num_str, @cur_pos, 1)

	SET @cur_pos = @cur_pos + 1
END

SET @nump = REVERSE( @nump)
SET	@maskp = REVERSE(@maskp)

UPDATE #ibnumber
	SET trx_ctrl_num = (STUFF(@mask, CHARINDEX ( @maskp , @mask ), 
						LEN(@maskp), 
						REVERSE(REPLACE(STUFF(reverse(@maskp), 1, len(@num), reverse(@num)), '#','')))),
		@num = @num + 1
WHERE LEN(trx_ctrl_num)< = 0



IF @transaction_started = 1 BEGIN COMMIT TRANSACTION SELECT @transaction_started = 0 SELECT 'PS_TRACE'='COMMIT transaction: ' + 'GENCONTROL' END


    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

RETURN @return_value

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ibassign_control_numbers_sp] TO [public]
GO

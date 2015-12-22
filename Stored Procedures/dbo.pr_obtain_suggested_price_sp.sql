SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[pr_obtain_suggested_price_sp] @WhereClause VARCHAR(1000)
    AS
    DECLARE @current_appdate INT    
    DECLARE @fs_get_price_price DECIMAL(20, 8)
    DECLARE @glco_curr_precision FLOAT
    DECLARE @gross_amount_purchased_to_date FLOAT
    DECLARE @L VARCHAR(10)
    DECLARE @location VARCHAR(10)
    DECLARE @L_End INT
    DECLARE @L_Length INT
    DECLARE @L_Start INT
    DECLARE @P VARCHAR(30)
    DECLARE @part_no VARCHAR(30)
    DECLARE @P_End INT
    DECLARE @P_Length INT
    DECLARE @P_Start INT 
    DECLARE @Q VARCHAR(30)
    DECLARE @qty FLOAT
    DECLARE @Q_End INT
    DECLARE @Q_Length INT
    DECLARE @Q_Start INT 
    DECLARE @quantity_purchased_to_date FLOAT
    DECLARE @sp_result INT
    DECLARE @V VARCHAR(16)
    DECLARE @customer_code VARCHAR(16)
    DECLARE @V_End INT
    DECLARE @V_Length INT
    DECLARE @V_Start INT
    --
    SET NOCOUNT ON
    IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#possible_price') IS NULL)
        DROP TABLE [#possible_price]

    CREATE TABLE [#possible_price] (
		[contract_ctrl_num]		VARCHAR(16) NULL,
		[part_number]			VARCHAR(30) NULL,
		[description]			VARCHAR(255) NULL,
		[quantity_purchased_to_date]	FLOAT NULL,
		[amount_purchased_to_date]	FLOAT NULL,
		[unit_price]			FLOAT NULL,
		[next_quantity_break]		FLOAT NULL,
		[next_unit_price]		FLOAT NULL,
		[rebate]			FLOAT NULL,
		[level]				INT NULL,
		[next_rebate]			FLOAT NULL,
		[rebate_percent_flag]		INT NULL)
    --                                    
    --
    -- Parse customer from @WhereClause.
    --
    SET @V_Start = CHARINDEX('V like', @WhereClause, 1)
    IF @V_Start = 0 
        BEGIN
        RAISERROR('A customer code must be entered', 1, 1)
        GOTO Final_SELECT_Statement
        END
    SET @V_Start = @V_Start + 9
    SET @V_End = CHARINDEX('%', @WhereClause, @V_Start)
    IF @V_End = 0
        SET @V_End = LEN(@WhereClause)
    SET @V_Length = @V_End - @V_Start
    SET @V = SUBSTRING(@WhereClause, @V_Start, @V_Length)
    IF CHARINDEX('''', @V, 1) > 0
            OR @V_End = 0
        BEGIN
        SET @V_End = CHARINDEX('''', @WhereClause, @V_Start)
        END
    SET @V_End = CHARINDEX('%', @WhereClause, @V_Start)
    SET @V_Length = @V_End - @V_Start
    SET @V = SUBSTRING(@WhereClause, @V_Start, @V_Length)
    IF LTRIM(RTRIM(@V)) = ''
        BEGIN
        RAISERROR('A customer must be entered', 1, 1)
        GOTO Final_SELECT_Statement
        END
    --
    -- Parse location from @WhereClause.
    --
    SET @L_Start = CHARINDEX('L like', @WhereClause, 1)
    IF @L_Start = 0
        BEGIN
        RAISERROR('A location code must be entered', 1, 1)
        GOTO Final_SELECT_Statement
        END
    SET @L_Start = @L_Start + 9
    IF @L_End = 0
        SET @L_End = LEN(@WhereClause)
    SET @L_Length = @L_End - @L_Start
    SET @L = SUBSTRING(@WhereClause, @L_Start, @L_Length)
    IF CHARINDEX('''', @L, 1) > 0
            OR @L_End = 0
        BEGIN
        SET @L_End = CHARINDEX('''', @WhereClause, @L_Start)
        END
    SET @L_End = CHARINDEX('%', @WhereClause, @L_Start)
    SET @L_Length = @L_End - @L_Start
    SET @L = SUBSTRING(@WhereClause, @L_Start, @L_Length)
    IF LTRIM(RTRIM(@L)) = ''
        BEGIN
        RAISERROR('A location must be entered', 1, 1)
        GOTO Final_SELECT_Statement
        END
    --
    -- Parse part number from @WhereClause.
    --
    SET @P_Start = CHARINDEX('P like', @WhereClause, 1)
    IF @P_Start = 0
        BEGIN
        RAISERROR('A part number must be entered', 1, 1)
        GOTO Final_SELECT_Statement
        END
    SET @P_Start = @P_Start + 9
    SET @P_End = CHARINDEX('%', @WhereClause, @P_Start)
    IF @P_End = 0
        SET @P_End = LEN(@WhereClause)
    SET @P_Length = @P_End - @P_Start
    SET @P = SUBSTRING(@WhereClause, @P_Start, @P_Length)
    IF CHARINDEX('''', @P, 1) > 0
            OR @P_End = 0 
        BEGIN
        SET @P_End = CHARINDEX('''', @WhereClause, @P_Start)
        END
    SET @P_Length = @P_End - @P_Start
    SET @P = SUBSTRING(@WhereClause, @P_Start, @P_Length)
    IF LTRIM(RTRIM(@P)) = ''
        BEGIN
        RAISERROR('A part number must be entered', 1, 1)
        GOTO Final_SELECT_Statement
        END
    --
    -- Parse quantity from @WhereClause.
    --
    SET @Q_Start = CHARINDEX('Q like', @WhereClause, 1)
    IF @Q_Start = 0
        BEGIN
        RAISERROR('A quantity must be entered', 1, 1)
        GOTO Final_SELECT_Statement
        END
    SET @Q_Start = @Q_Start + 9
    SET @Q_End = CHARINDEX('%', @WhereClause, @Q_Start)
    IF @Q_End = 0
        SET @Q_End = LEN(@WhereClause)
    SET @Q_Length = @Q_End - @Q_Start
    SET @Q = SUBSTRING(@WhereClause, @Q_Start, @Q_Length)
    IF CHARINDEX('''', @Q, 1) > 0
            OR @Q_End = 0 
        BEGIN
        SET @Q_End = CHARINDEX('''', @WhereClause, @Q_Start)
        END
    SET @Q_Length = @Q_End - @Q_Start
    SET @Q = SUBSTRING(@WhereClause, @Q_Start, @Q_Length)
    IF LTRIM(RTRIM(@Q)) = ''
        BEGIN
        RAISERROR('A part number must be entered', 1, 1)
        GOTO Final_SELECT_Statement
        END
    SELECT @qty = CAST(@Q AS FLOAT)

    IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#fs_get_price_results') IS NULL)
        DROP TABLE [#fs_get_price_results]
    CREATE TABLE [#fs_get_price_results] ([price_level] CHAR(1), 
                                          [price] DECIMAL(20, 8), 
                                          [next_qty] DECIMAL(20, 8), 
                                          [next_price] DECIMAL(20, 8), 
                                          [promo_price] DECIMAL(20, 8), 
                                          [sales_comm] DECIMAL(20, 8), 
                                          [qloop] INT, 
                                          [quote_level] INT, 
                                          [quote_curr] VARCHAR(10))
    INSERT INTO [#fs_get_price_results] 
      EXEC fs_get_price @V, '', '', @P, @L, '', @qty, 0, '', 1, 'N'

    UPDATE [#possible_price]
       SET [unit_price] = f.[price]
      FROM [#fs_get_price_results] f 

    UPDATE [#possible_price]
       SET [contract_ctrl_num] = '<NONE>'
     WHERE ISNULL(DATALENGTH(RTRIM(LTRIM([contract_ctrl_num]))),0) = 0

    DROP TABLE [#fs_get_price_results]       
	

Final_SELECT_Statement:
    SELECT [contract_ctrl_num], [part_number], [description], [quantity_purchased_to_date], [amount_purchased_to_date], [unit_price], [next_quantity_break], [rebate], [level], [next_rebate], [rebate_percent_flag] FROM [#possible_price]
    RETURN
GO
GRANT EXECUTE ON  [dbo].[pr_obtain_suggested_price_sp] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[pr_obtain_suggested_cost_sp] @WhereClause VARCHAR(1000)
    AS
    DECLARE @current_appdate INT    
    DECLARE @glco_curr_precision FLOAT
    DECLARE @gross_amount_purchased_to_date FLOAT
    DECLARE @inventory_cost DECIMAL(20, 8)
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
    DECLARE @quantity_purchased_to_date FLOAT
    DECLARE @sp_result INT
    DECLARE @V VARCHAR(16)
    DECLARE @vendor_code VARCHAR(16)
    DECLARE @V_End INT
    DECLARE @V_Length INT
    DECLARE @V_Start INT
    DECLARE @Q VARCHAR(30)
    DECLARE @qty FLOAT
    DECLARE @Q_End INT
    DECLARE @Q_Length INT
    DECLARE @Q_Start INT 
    --
    SET NOCOUNT ON
    IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#possible_cost') IS NULL)
        DROP TABLE [#possible_cost]
    CREATE TABLE [#possible_cost] (
		[contract_ctrl_num]		VARCHAR(16) NULL,
		[part_number]			VARCHAR(30) NULL,
		[description]			VARCHAR(255) NULL,
		[quantity_purchased_to_date]	FLOAT NULL,
		[amount_purchased_to_date]	FLOAT NULL,
		[unit_cost]			FLOAT NULL,
		[next_quantity_break]		FLOAT NULL,
		[next_unit_cost]		FLOAT NULL,
		[rebate]			FLOAT NULL,
		[level]				INT NULL,
		[next_rebate]			FLOAT NULL,
		[rebate_percent_flag]		INT NULL)
    --                                    
    --
    -- Parse vendor from @WhereClause.
    --
    SET @V_Start = CHARINDEX('V like', @WhereClause, 1)
    IF @V_Start = 0 
        BEGIN
        RAISERROR('A vendor code must be entered', 1, 1)
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
        RAISERROR('A vendor must be entered', 1, 1)
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

    EXEC [pr_get_cost_sp] @V, @P, @L, @qty

    --
Final_SELECT_Statement:
    SELECT * FROM [#possible_cost]
    DROP TABLE [#possible_cost]
    RETURN
GO
GRANT EXECUTE ON  [dbo].[pr_obtain_suggested_cost_sp] TO [public]
GO

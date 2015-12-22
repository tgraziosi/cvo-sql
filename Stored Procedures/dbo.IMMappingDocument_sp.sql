SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC
[dbo].[IMMappingDocument_sp] @IMMappingDocument_sp_Table_Name VARCHAR(128) = '',
                     @IMMappingDocument_sp_User_Name VARCHAR(30) = '',
                     @IMMappingDocument_sp_Sort_Order VARCHAR(12) = 'ALPHABETICAL'
                    
    AS
    --
    -- Note that the description column is always returned as a non-zero-length string
    -- because Crystal Reports treats a zero-length string differently than a non-zero-length
    -- string.
    --
    DECLARE @glco_company_id INT
    DECLARE @im_config_eBackOffice_Version VARCHAR(100)
    --
    SET @im_config_eBackOffice_Version = ''
    SELECT @im_config_eBackOffice_Version = LTRIM(RTRIM(ISNULL([Text Value], '')))
            FROM [im_config]
            WHERE UPPER(LTRIM(RTRIM([Item Name]))) = 'EBACKOFFICE VERSION'
    --
    -- The test for a blank (absent) user name is for the benefit of the Crystal 
    -- version of the mapping document.  When the information is simply printed
    -- out there's no need for a security check.
    --        
    IF @im_config_eBackOffice_Version = '7'
            OR @IMMappingDocument_sp_User_Name = ''       
        BEGIN
        IF UPPER(@IMMappingDocument_sp_Sort_Order) = 'ALPHABETICAL'
            BEGIN
            SELECT [name] AS 'Name',
                    CASE
                        WHEN [xtype] = 106 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([xprec] AS VARCHAR) + ',' + CAST([xscale] AS VARCHAR) + ')'
                        WHEN [xtype] = 167 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 175 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 231 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 239 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        ELSE UPPER(TYPE_NAME([xtype]))
                    END AS 'Type', 
                    CASE WHEN COLUMNPROPERTY(OBJECT_ID(LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name))), [name], 'AllowsNull') = 1
                        THEN 'Yes' 
                        ELSE 'No' 
                    END AS 'Nullable',
                    CASE
                        WHEN UPPER([Allow_Editing]) = 'O' THEN 'Yes'
                        WHEN UPPER([Allow_Editing]) = 'R' THEN 'Yes'
                        WHEN LTRIM(RTRIM([Allow_Editing])) = '' THEN 'Yes'
                        WHEN [Allow_Editing] IS NULL THEN 'Yes'
                        ELSE 'Yes'
                    END AS 'Allow Editing',
                    [foreignKey] AS 'Foreign Key',
                    CASE
                        WHEN LTRIM(RTRIM([description])) = '' THEN ' '
                        WHEN [description] IS NULL THEN ' '
                        ELSE LTRIM(RTRIM([description]))
                    END AS 'Description',
                    ISNULL([Header_Detail_Link], 'No') AS 'Header/Detail Link',
                    '' AS 'Setup Form Class ID',
                    'Yes' AS 'Setup Form Permission'
                    FROM [CVO_Control]..[imdmapping] 
                    INNER JOIN [syscolumns]
                            ON [CVO_Control]..[imdmapping].[columnname] = [syscolumns].[name]
                    WHERE [tablename] = LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name))
                            AND [syscolumns].[id] = OBJECT_ID(LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name)))
                    ORDER BY UPPER([name])
            END
        ELSE        
            BEGIN
            SELECT [name] AS 'Name',
                    CASE
                        WHEN [xtype] = 106 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([xprec] AS VARCHAR) + ',' + CAST([xscale] AS VARCHAR) + ')'
                        WHEN [xtype] = 167 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 175 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 231 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 239 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        ELSE UPPER(TYPE_NAME([xtype]))
                    END AS 'Type', 
                    CASE WHEN COLUMNPROPERTY(OBJECT_ID(LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name))), [name], 'AllowsNull') = 1
                        THEN 'Yes' 
                        ELSE 'No' 
                    END AS 'Nullable',
                    CASE
                        WHEN UPPER([Allow_Editing]) = 'O' THEN 'Yes'
                        WHEN UPPER([Allow_Editing]) = 'R' THEN 'Yes'
                        WHEN LTRIM(RTRIM([Allow_Editing])) = '' THEN 'Yes'
                        WHEN [Allow_Editing] IS NULL THEN 'Yes'
                        ELSE 'Yes'
                    END AS 'Allow Editing',
                    [foreignKey] AS 'Foreign Key',
                    CASE
                        WHEN LTRIM(RTRIM([description])) = '' THEN ' '
                        WHEN [description] IS NULL THEN ' '
                        ELSE LTRIM(RTRIM([description]))
                    END AS 'Description',
                    ISNULL([Header_Detail_Link], 'No') AS 'Header/Detail Link',
                    '' AS 'Setup Form Class ID',
                    'Yes' AS 'Setup Form Permission',
                    [syscolumns].[colid]
                    FROM [CVO_Control]..[imdmapping] 
                    INNER JOIN [syscolumns]
                            ON [CVO_Control]..[imdmapping].[columnname] = [syscolumns].[name]
                    WHERE [tablename] = LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name))
                            AND [syscolumns].[id] = OBJECT_ID(LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name)))
                    ORDER BY [syscolumns].[colid]
            END    
        END    
    ELSE
        BEGIN
        SELECT @glco_company_id = [company_id]
                FROM [glco]
        IF UPPER(@IMMappingDocument_sp_Sort_Order) = 'ALPHABETICAL'
            BEGIN
            SELECT DISTINCT [name] AS 'Name',
                    CASE
                        WHEN [xtype] = 106 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([xprec] AS VARCHAR) + ',' + CAST([xscale] AS VARCHAR) + ')'
                        WHEN [xtype] = 167 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 175 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 231 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 239 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        ELSE UPPER(TYPE_NAME([xtype]))
                    END AS 'Type', 
                    CASE WHEN COLUMNPROPERTY(OBJECT_ID(LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name))), [name], 'AllowsNull') = 1
                        THEN 'Yes' 
                        ELSE 'No' 
                    END AS 'Nullable',
                    CASE
                        WHEN UPPER([Allow_Editing]) = 'O' THEN 'Yes'
                        WHEN UPPER([Allow_Editing]) = 'R' THEN 'Yes'
                        WHEN LTRIM(RTRIM([Allow_Editing])) = '' THEN 'Yes'
                        WHEN [Allow_Editing] IS NULL THEN 'Yes'
                        WHEN LTRIM(RTRIM(UPPER([Allow_Editing]))) = 'NO' THEN 'No'
                        ELSE 'Yes'
                    END AS 'Allow Editing',
                    [foreignKey] AS 'Foreign Key',
                    CASE
                        WHEN LTRIM(RTRIM([description])) = '' THEN ' '
                        WHEN [description] IS NULL THEN ' '
                        ELSE LTRIM(RTRIM([description]))
                    END AS 'Description',
                    ISNULL([Header_Detail_Link], 'No') AS 'Header/Detail Link',
                    ISNULL([Setup_Form_Class_ID], '') AS 'Setup Form Class ID',
                    CASE
                        WHEN ISNULL(P.[write], 0) > 0 THEN 'Yes'
                        ELSE 'No'
                    END AS 'Setup Form Permission'
                    FROM [CVO_Control]..[imdmapping] M
                    INNER JOIN [syscolumns]
                            ON M.[columnname] = [syscolumns].[name]
                    LEFT OUTER JOIN [CVO_Control]..[smcom] C -- Equates class ID to form number
                            ON M.[Setup_Form_Class_ID] = CAST(C.[ClassID] AS VARCHAR(37))
                    LEFT OUTER JOIN [CVO_Control]..[smperm] P -- Defines form permissions
                            ON P.app_id = C.App_ID 
                                    AND P.[form_id] = C.[Form_ID] 
                    LEFT OUTER JOIN [CVO_Control]..[smusers] U -- Equates user ID to user name for WHERE clause
                            ON U.[user_id] = P.[user_id] 
                    WHERE [tablename] = LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name))
                            AND [syscolumns].[id] = OBJECT_ID(LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name)))
                            AND (U.[user_name] = @IMMappingDocument_sp_User_Name OR U.[user_name] IS NULL)
                    -- The following ORDER BY would be nice but it generates the error
                    -- "Invalid column name 'Name'".  Changing it to "name" (lowercase "N")
                    -- generates an error that says something about the ORDER BY in a SELECT
                    -- DISTINCT needs to reference columns in the SELECT list.  The result of
                    -- not having an ORDER BY is that the names are not sorted properly on a
                    -- case-sensitive server.
                    --ORDER BY UPPER([Name])                          
            END
        ELSE
            BEGIN
            SELECT DISTINCT [name] AS 'Name',
                    CASE
                        WHEN [xtype] = 106 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([xprec] AS VARCHAR) + ',' + CAST([xscale] AS VARCHAR) + ')'
                        WHEN [xtype] = 167 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 175 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 231 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        WHEN [xtype] = 239 THEN UPPER(TYPE_NAME([xtype])) + '(' + CAST([length] AS VARCHAR) + ')'
                        ELSE UPPER(TYPE_NAME([xtype]))
                    END AS 'Type', 
                    CASE WHEN COLUMNPROPERTY(OBJECT_ID(LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name))), [name], 'AllowsNull') = 1
                        THEN 'Yes' 
                        ELSE 'No' 
                    END AS 'Nullable',
                    CASE
                        WHEN UPPER([Allow_Editing]) = 'O' THEN 'Yes'
                        WHEN UPPER([Allow_Editing]) = 'R' THEN 'Yes'
                        WHEN LTRIM(RTRIM([Allow_Editing])) = '' THEN 'Yes'
                        WHEN [Allow_Editing] IS NULL THEN 'Yes'
                        WHEN LTRIM(RTRIM(UPPER([Allow_Editing]))) = 'NO' THEN 'No'
                        ELSE 'Yes'
                    END AS 'Allow Editing',
                    [foreignKey] AS 'Foreign Key',
                    CASE
                        WHEN LTRIM(RTRIM([description])) = '' THEN ' '
                        WHEN [description] IS NULL THEN ' '
                        ELSE LTRIM(RTRIM([description]))
                    END AS 'Description',
                    ISNULL([Header_Detail_Link], 'No') AS 'Header/Detail Link',
                    ISNULL([Setup_Form_Class_ID], '') AS 'Setup Form Class ID',
                    CASE
                        WHEN ISNULL(P.[write], 0) > 0 THEN 'Yes'
                        ELSE 'No'
                    END AS 'Setup Form Permission',
                    [syscolumns].[colid]
                    FROM [CVO_Control]..[imdmapping] M
                    INNER JOIN [syscolumns]
                            ON M.[columnname] = [syscolumns].[name]
                    LEFT OUTER JOIN [CVO_Control]..[smcom] C -- Equates class ID to form number
                            ON M.[Setup_Form_Class_ID] = CAST(C.[ClassID] AS VARCHAR(37))
                    LEFT OUTER JOIN [CVO_Control]..[smperm] P -- Defines form permissions
                            ON P.app_id = C.App_ID 
                                    AND P.[form_id] = C.[Form_ID] 
                    LEFT OUTER JOIN [CVO_Control]..[smusers] U -- Equates user ID to user name for WHERE clause
                            ON U.[user_id] = P.[user_id] 
                    WHERE [tablename] = LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name))
                            AND [syscolumns].[id] = OBJECT_ID(LTRIM(RTRIM(@IMMappingDocument_sp_Table_Name)))
                            AND (U.[user_name] = @IMMappingDocument_sp_User_Name OR U.[user_name] IS NULL)
                    ORDER BY [syscolumns].[colid]
            END
        END
    RETURN
GO
GRANT EXECUTE ON  [dbo].[IMMappingDocument_sp] TO [public]
GO

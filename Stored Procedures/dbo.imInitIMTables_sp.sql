SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC
[dbo].[imInitIMTables_sp] @imInitIMTables_sp_User_Name VARCHAR(30) = ''
                    
    AS
    DECLARE @glco_company_id INT
    DECLARE @im_config_eBackOffice_Version VARCHAR(100)
    --
    SET @im_config_eBackOffice_Version = ''
    SELECT @im_config_eBackOffice_Version = LTRIM(RTRIM(ISNULL([Text Value], '')))
            FROM [im_config]
            WHERE UPPER(LTRIM(RTRIM([Item Name]))) = 'EBACKOFFICE VERSION'
    IF @im_config_eBackOffice_Version = '7'        
            OR @imInitIMTables_sp_User_Name = ''
        BEGIN
        SELECT RTRIM(LTRIM(ISNULL([description], ''))) AS 'description',
               RTRIM(LTRIM(ISNULL([dts], ''))) AS 'dts',
               [isTable],
               RTRIM(LTRIM(ISNULL([migproc], ''))) AS 'migproc',
               RTRIM(LTRIM(ISNULL([Name1], ''))) AS 'Name1',
               RTRIM(LTRIM(ISNULL([Control Database Name1], ''))) AS 'Control Database Name1',
               RTRIM(LTRIM(ISNULL([Name2], ''))) AS 'Name2',
               RTRIM(LTRIM(ISNULL([Control Database Name2], ''))) AS 'Control Database Name2',
               RTRIM(LTRIM(ISNULL([Name3], ''))) AS 'Name3',
               RTRIM(LTRIM(ISNULL([Control Database Name3], ''))) AS 'Control Database Name3',
               [type],
               RTRIM(LTRIM(ISNULL([section], ''))) AS 'section',
               RTRIM(LTRIM(ISNULL([valproc], ''))) AS 'valproc',
               ISNULL([valproc Returns A Recordset], 0) AS 'valproc Returns A Recordset',
               ISNULL([migproc Returns A Recordset], 0) AS 'migproc Returns A Recordset',
               LTRIM(RTRIM(ISNULL([Error Messages Retrieval Procedure Name], ''))) AS 'Error Messages Retrieval Procedure Name',
               LTRIM(RTRIM(ISNULL([Error Messages Deletion Procedure Name], ''))) AS 'Error Messages Deletion Procedure Name',
               ISNULL([Indicate Errors Via processed_flag], 0) AS 'Indicate Errors Via processed_flag',
               ISNULL([Transaction Type For Dual Imports], -1) AS 'Transaction Type For Dual Imports',
               ISNULL([Transaction Type Column Name], '') AS 'Transaction Type Column Name',
               LTRIM(RTRIM(ISNULL([Crystal Report File Name], ''))) AS 'Crystal Report File Name',
               LTRIM(RTRIM(ISNULL([Crystal Report File Name 2], ''))) AS 'Crystal Report File Name 2',
               LTRIM(RTRIM(ISNULL([Main Reporting Data Table], ''))) AS 'Main Reporting Data Table',
               LTRIM(RTRIM(ISNULL([Write Operations Use Control Database Names], 0))) AS 'Write Operations Use Control Database Names', 
               LTRIM(RTRIM(ISNULL([Enable Distribution Reports], 0))) AS 'Enable Distribution Reports',
               'Yes' AS 'Permission'
                FROM [imwbtables_vw] 
                WHERE [isTable] = 1 
                ORDER BY UPPER([section]), [process_order]
        END        
    ELSE
        BEGIN 
        SELECT @glco_company_id = ISNULL(company_id, 0)
                FROM [glco]           
        SELECT RTRIM(LTRIM(ISNULL([description], ''))) AS 'description',
               RTRIM(LTRIM(ISNULL([dts], ''))) AS 'dts',
               [isTable],
               RTRIM(LTRIM(ISNULL([migproc], ''))) AS 'migproc',
               RTRIM(LTRIM(ISNULL([Name1], ''))) AS 'Name1',
               RTRIM(LTRIM(ISNULL([Control Database Name1], ''))) AS 'Control Database Name1',
               RTRIM(LTRIM(ISNULL([Name2], ''))) AS 'Name2',
               RTRIM(LTRIM(ISNULL([Control Database Name2], ''))) AS 'Control Database Name2',
               RTRIM(LTRIM(ISNULL([Name3], ''))) AS 'Name3',
               RTRIM(LTRIM(ISNULL([Control Database Name3], ''))) AS 'Control Database Name3',
               [type],
               RTRIM(LTRIM(ISNULL([section], ''))) AS 'section',
               RTRIM(LTRIM(ISNULL([valproc], ''))) AS 'valproc',
               ISNULL([valproc Returns A Recordset], 0) AS 'valproc Returns A Recordset',
               ISNULL([migproc Returns A Recordset], 0) AS 'migproc Returns A Recordset',
               LTRIM(RTRIM(ISNULL([Error Messages Retrieval Procedure Name], ''))) AS 'Error Messages Retrieval Procedure Name',
               LTRIM(RTRIM(ISNULL([Error Messages Deletion Procedure Name], ''))) AS 'Error Messages Deletion Procedure Name',
               ISNULL([Indicate Errors Via processed_flag], 0) AS 'Indicate Errors Via processed_flag',
               ISNULL([Transaction Type For Dual Imports], -1) AS 'Transaction Type For Dual Imports',
               ISNULL([Transaction Type Column Name], '') AS 'Transaction Type Column Name',
               LTRIM(RTRIM(ISNULL([Crystal Report File Name], ''))) AS 'Crystal Report File Name',
               LTRIM(RTRIM(ISNULL([Crystal Report File Name 2], ''))) AS 'Crystal Report File Name 2',
               LTRIM(RTRIM(ISNULL([Main Reporting Data Table], ''))) AS 'Main Reporting Data Table',
               LTRIM(RTRIM(ISNULL([Write Operations Use Control Database Names], 0))) AS 'Write Operations Use Control Database Names', 
               LTRIM(RTRIM(ISNULL([Enable Distribution Reports], 0))) AS 'Enable Distribution Reports',
               CASE
                   WHEN ISNULL(P.[write], 0) > 0 THEN 'Yes'
                   ELSE 'No'
               END AS 'Permission'
                FROM [imwbtables_vw] M
                LEFT OUTER JOIN [CVO_Control]..[smcom] C -- Equates class ID to form number
                        ON M.[Class ID] = C.[ClassID]
                INNER JOIN [CVO_Control]..[smperm] P -- Defines form permissions
                        ON P.[app_id] = C.[App_ID] 
                                AND P.[form_id] = C.[Form_ID] 
                INNER JOIN [CVO_Control]..[smusers] U -- Equates user ID to user name for WHERE clause
                        ON U.[user_id] = P.[user_id] 
                WHERE [isTable] = 1 
                        AND U.[user_name] = @imInitIMTables_sp_User_Name
                        AND P.[company_id] = @glco_company_id
                ORDER BY UPPER([section]), [process_order]
        END        
    RETURN
GO
GRANT EXECUTE ON  [dbo].[imInitIMTables_sp] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW
[dbo].[im_Action_Information_vw]
    AS  
    SELECT 1 AS 'ActionClass',
           ISNULL([ClassId], '') AS 'Class ID',
           ISNULL([ApplicationObjectName], '') AS 'Application Name',
           ISNULL([ApplicationMacroName], '') AS 'Application Command 1',
           ISNULL([ApplicationFormName], '') AS 'Application Command 2'
            FROM [CVO_Control]..[ToolsActions]
            WHERE NOT [ApplicationObjectName] IS NULL
                    AND NOT [ApplicationObjectName] = ''
    UNION
    SELECT 2 AS 'ActionClass',
           ISNULL([ClassId], '') AS 'Class ID',
           ISNULL([ReportObjectName], '') AS 'Application Name',
           ISNULL([ReportMacroName], '') AS 'Application Command 1',
           ISNULL([ReportID1], '') AS 'Application Command 2'
            FROM [CVO_Control]..[ReportActions]
            WHERE NOT [ReportObjectName] IS NULL
                    AND NOT [ReportObjectName] = ''
    UNION
    SELECT 3 AS 'ActionClass',
           ISNULL([ClassId], '') AS 'Class ID',
           ISNULL([ApplicationObjectName], '') AS 'Application Name',
           ISNULL([ApplicationFormName], '') AS 'Application Command 1',
           '' AS 'Application Command 2'
            FROM [CVO_Control]..[ADMActions]
            WHERE NOT [ApplicationObjectName] IS NULL
                    AND NOT [ApplicationObjectName] = ''
    UNION
    SELECT 4 AS 'ActionClass',
           ISNULL([ClassId], '') AS 'Class ID',
           'AM.Application' AS 'Application Name',
           ISNULL([AMForm], '') AS 'Application Command1 ',
           '' AS 'Application Command 2'
            FROM [CVO_Control]..[AMActions]
    UNION
    SELECT 5 AS 'ActionClass',
           ISNULL([ClassId], '') AS 'Class ID',
           ISNULL([DocumentName], '') AS 'Application Name',
           '' AS 'Application Command 1',
           '' AS 'Application Command 2'
            FROM [CVO_Control]..[ShellExecuteActions]
            WHERE NOT [DocumentName] IS NULL
                    AND NOT [DocumentName] = ''
    UNION
    SELECT 6 AS 'ActionClass',
           ISNULL([ClassId], '') AS 'Class ID',
           ISNULL([ApplicationName], '') AS 'Application Name',
           ISNULL([CommandLine], '') AS 'Application Command 1',
           '' AS 'Application Command 2'
            FROM [CVO_Control]..[ShellActions]
            WHERE NOT [ApplicationName] IS NULL
                    AND NOT [ApplicationName] = ''
GO
GRANT SELECT ON  [dbo].[im_Action_Information_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[im_Action_Information_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[im_Action_Information_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[im_Action_Information_vw] TO [public]
GO

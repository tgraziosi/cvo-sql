SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW 
[dbo].[imappdt_vw] AS
    SELECT *
            FROM [CVO_Control]..[imappdt]
GO
GRANT REFERENCES ON  [dbo].[imappdt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imappdt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imappdt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imappdt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imappdt_vw] TO [public]
GO

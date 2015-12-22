SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    CREATE VIEW 
[dbo].[imarpdt_vw] AS
    SELECT *
            FROM [CVO_Control]..[imarpdt]
GO
GRANT REFERENCES ON  [dbo].[imarpdt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imarpdt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imarpdt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imarpdt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imarpdt_vw] TO [public]
GO

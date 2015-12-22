SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



    CREATE VIEW 
[dbo].[imardtl_vw] AS
    SELECT *
            FROM [CVO_Control]..[imardtl]
GO
GRANT REFERENCES ON  [dbo].[imardtl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imardtl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imardtl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imardtl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imardtl_vw] TO [public]
GO

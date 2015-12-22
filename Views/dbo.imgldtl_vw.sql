SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



    CREATE VIEW 
[dbo].[imgldtl_vw] AS
    SELECT *
            FROM [CVO_Control]..[imgldtl]
                                                 
GO
GRANT REFERENCES ON  [dbo].[imgldtl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imgldtl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imgldtl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imgldtl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imgldtl_vw] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW 
[dbo].[imapdtl_vw] 
    AS 
    SELECT * 
            FROM [CVO_Control]..[imapdtl]
GO
GRANT REFERENCES ON  [dbo].[imapdtl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imapdtl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imapdtl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imapdtl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imapdtl_vw] TO [public]
GO

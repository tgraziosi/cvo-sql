SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



    CREATE VIEW 
[dbo].[imglseg_vw] AS
    SELECT *
            FROM [CVO_Control]..[imglseg]
GO
GRANT REFERENCES ON  [dbo].[imglseg_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imglseg_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imglseg_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imglseg_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imglseg_vw] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE VIEW 
[dbo].[imicmerr_vw] AS SELECT * from [CVO_Control]..imicmerr
GO
GRANT REFERENCES ON  [dbo].[imicmerr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imicmerr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imicmerr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imicmerr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imicmerr_vw] TO [public]
GO

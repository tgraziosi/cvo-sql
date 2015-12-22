SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE VIEW 
[dbo].[imvdmerr_vw] AS SELECT * from [CVO_Control]..imvdmerr
GO
GRANT REFERENCES ON  [dbo].[imvdmerr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imvdmerr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imvdmerr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imvdmerr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imvdmerr_vw] TO [public]
GO

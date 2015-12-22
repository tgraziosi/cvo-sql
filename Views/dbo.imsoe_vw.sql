SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW 
[dbo].[imsoe_vw]
    AS
    SELECT * FROM [CVO_Control]..imsoe
GO
GRANT REFERENCES ON  [dbo].[imsoe_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imsoe_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imsoe_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imsoe_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imsoe_vw] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW 
[dbo].[imapvnd_Vendors_vw] 
    AS 
    SELECT * 
            FROM [CVO_Control]..[imapvnd]	
            WHERE [address_type] = 0

GO
GRANT REFERENCES ON  [dbo].[imapvnd_Vendors_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imapvnd_Vendors_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imapvnd_Vendors_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imapvnd_Vendors_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imapvnd_Vendors_vw] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW 
[dbo].[imappyt_vw] 
    AS 
    SELECT * from [CVO_Control]..[imappyt]
GO
GRANT REFERENCES ON  [dbo].[imappyt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imappyt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imappyt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imappyt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imappyt_vw] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW 
[dbo].[imcuserr_vw] 
    AS SELECT * from [CVO_Control]..[imcuserr]
GO
GRANT REFERENCES ON  [dbo].[imcuserr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imcuserr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imcuserr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imcuserr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imcuserr_vw] TO [public]
GO

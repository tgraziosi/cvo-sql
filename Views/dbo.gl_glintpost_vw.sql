SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[gl_glintpost_vw]
AS

SELECT * FROM gl_glinthdr WHERE post_flag = 1
GO
GRANT REFERENCES ON  [dbo].[gl_glintpost_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_glintpost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_glintpost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_glintpost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_glintpost_vw] TO [public]
GO

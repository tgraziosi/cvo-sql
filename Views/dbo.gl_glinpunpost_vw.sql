SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[gl_glinpunpost_vw]
AS

SELECT * FROM gl_glinphdr
WHERE 
(esl_ctrl_num = ''
OR esl_ctrl_num in (SELECT esl_ctrl_num FROM gl_gleslhdr WHERE post_flag = 0)
OR esl_ctrl_num in (SELECT esl_err_num FROM gl_gleslhdr WHERE post_flag = 0)
)
OR
(disp_ctrl_num = ''
OR disp_ctrl_num in (SELECT disp_ctrl_num FROM gl_glinthdr WHERE post_flag = 0)
OR disp_ctrl_num in (SELECT disp_err_num FROM gl_glinthdr WHERE post_flag = 0)
)
OR
(arr_ctrl_num = ''
OR arr_ctrl_num in (SELECT arr_ctrl_num FROM gl_glinthdr WHERE post_flag = 0)
OR arr_ctrl_num in (SELECT arr_err_num FROM gl_glinthdr WHERE post_flag = 0)
)

GO
GRANT REFERENCES ON  [dbo].[gl_glinpunpost_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_glinpunpost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_glinpunpost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_glinpunpost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_glinpunpost_vw] TO [public]
GO

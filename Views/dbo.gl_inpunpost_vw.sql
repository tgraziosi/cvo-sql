SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[gl_inpunpost_vw]
AS

SELECT * FROM gl_glinphdr
WHERE 
(esl_ctrl_num not in (SELECT esl_ctrl_num FROM gl_gleslpost_vw)
AND 
esl_ctrl_num not in (SELECT esl_err_num FROM gl_gleslpost_vw)
)
AND
(
disp_ctrl_num not in (SELECT disp_ctrl_num FROM gl_glintpost_vw)
AND disp_ctrl_num not in (SELECT disp_err_num FROM gl_glintpost_vw)
)
AND
(
arr_ctrl_num not in (SELECT arr_ctrl_num FROM gl_glintpost_vw)
AND arr_ctrl_num not in (SELECT arr_err_num FROM gl_glintpost_vw)
)


GO
GRANT REFERENCES ON  [dbo].[gl_inpunpost_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_inpunpost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_inpunpost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_inpunpost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_inpunpost_vw] TO [public]
GO

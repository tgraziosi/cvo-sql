SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[gl_UnRecuTrans_vw]
AS
	SELECT trx_type = 111, smusers_1rec_vw.user_id,glrecur.date_end_period_1,journal_ctrl_num  
	FROM glrecur,smusers_1rec_vw  
	WHERE date_last_applied =0 
	AND posted_flag =0
GO
GRANT SELECT ON  [dbo].[gl_UnRecuTrans_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_UnRecuTrans_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_UnRecuTrans_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_UnRecuTrans_vw] TO [public]
GO

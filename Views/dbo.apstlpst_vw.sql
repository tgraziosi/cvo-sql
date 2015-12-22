SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
**  apstlpst.vw
**
**      View for the unposted settlement records that are not on hold.
**
**      This view selects only the payment records which are OK to post.
*/
CREATE VIEW     [dbo].[apstlpst_vw]
	AS      SELECT  *
	FROM    apinpstl
	WHERE	hold_flag = 0
    and (
	     select count(*) from apinppyt WHERE apinppyt.printed_flag = 0 
		 and apinppyt.settlement_ctrl_num = apinpstl.settlement_ctrl_num
        )=0
GO
GRANT REFERENCES ON  [dbo].[apstlpst_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apstlpst_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apstlpst_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apstlpst_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apstlpst_vw] TO [public]
GO

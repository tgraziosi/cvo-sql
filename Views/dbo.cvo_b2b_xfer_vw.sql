SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- select * from cvo_b2b_xfer_vw where reason_code = 'BinQTY'

CREATE view [dbo].[cvo_b2b_xfer_vw] 
as 
select c.issue_no, c.location, c.from_bin, c.to_bin,  
case when c.part_no like '7%' or c.part_no like '8%' then
	(select i.part_no from inv_master i  where i.upc_code = c.part_no)
	else part_no end as part_no,
c.qty, c.reason_code, c.err_msg, c.date_tran

From cvo_b2b_xfer_log c


GO
GRANT REFERENCES ON  [dbo].[cvo_b2b_xfer_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_b2b_xfer_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_b2b_xfer_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_b2b_xfer_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_b2b_xfer_vw] TO [public]
GO

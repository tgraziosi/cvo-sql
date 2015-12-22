SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_invtransfer_vw] as 
select top 100 percent
fro.part_no, fro.location from_loc, 
fro.bin_no from_bin, too.location to_loc, too.bin_no to_bin, fro.tran_no from_tran_no, too.tran_no to_tran_no,
fro.who, fro.qty, fro.cost, fro.date_tran from_date_tran, too.date_tran to_date_tran/*, **/ 
from lot_bin_tran fro (nolock), lot_bin_tran too (nolock) 
where fro.part_no = too.part_no 
and fro.bin_no <> too.bin_no 
and fro.tran_no = too.tran_no - 1 
-- and fro.date_tran = Too.date_tran 
and fro.direction = -1 and too.direction = 1
and fro.who = too.who
and fro.tran_code = 'I'

GO
GRANT SELECT ON  [dbo].[cvo_invtransfer_vw] TO [public]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[cvo_orderpicks_vw] as

select b.group_code, b.usage_type_code, p.bin_no, p.part_no, p.qty_to_process
, p.trans_type_no, p.trans_type_ext, p.trans, cast(p.tran_id as varchar(12)) Q_tran_id
from tdc_pick_queue p (nolock)
inner join tdc_bin_master b (nolock) on b.bin_no = p.bin_no and b.location = p.location
where isnull(trans_type_no,0) > 0

GO
GRANT REFERENCES ON  [dbo].[cvo_orderpicks_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_orderpicks_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_orderpicks_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_orderpicks_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_orderpicks_vw] TO [public]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_missingcosts_sp] AS
begin
SET NOCOUNT ON

SELECT  av.part_no ,
        av.description ,
        i.account ,
		av.category ,
        av.po_key ,
		av.date_of_order ,
        av.vendor_no ,
        av.line ,
        av.location ,
        av.unit_cost ,
        av.curr_key ,
        av.curr_cost ,
        av.weight_ea ,
        av.qty_ordered ,
        av.qty_received ,
        av.ext_cost ,
        av.account_no ,
        av.status ,
        av.status_desc ,
        il.std_cost ,
        il.std_ovhd_dolrs ,
        il.std_util_dolrs
FROM    dbo.cvo_adpol_vw AS av
        JOIN inv_list il ON il.location = av.location
                            AND il.part_no = av.part_no
        JOIN inv_master i ON i.part_no = av.part_no
WHERE   status_desc = 'open'
        AND il.std_cost = 0
        AND il.std_cost <> av.unit_cost;

END
GO
GRANT EXECUTE ON  [dbo].[cvo_missingcosts_sp] TO [public]
GO

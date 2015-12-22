SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[iminvmast_loc_vw] as
SELECT  company_code,
        part_no,
        uom,
        location,
        lead_time,
        vw.status,
        loc_note,
        lbs_bin_no as bin_no,
        hold_qty,
        in_stock,
        issued_mtd,
        issued_ytd,
        max_stock,
        min_stock,
        min_order,
        qty_year_end,
        qty_month_end,
        qty_physical,
        cycle_date,
        eoq,
        acct_code,
        loc_avg_cost,
        loc_avg_direct_dolrs,
        loc_avg_ovhd_dolrs,
        loc_avg_util_dolrs,
        loc_std_cost,
        loc_std_direct_dolrs,
        loc_std_ovhd_dolrs,
        loc_std_util_dolrs,
        loc_labor,
        code,
        batch_no,
        dirty_flag,
        record_status_1,
        record_status_2,
        process_status,
        record_type,
        record_id_num,
        [User_ID],
        [po_uom],
        [so_uom],
        [abc_code],
        [abc_code_frozen_flag]
FROM    CVO_Control.dbo.iminvmast vw
where 	(record_type & 0x00000100) > 0



GO
GRANT REFERENCES ON  [dbo].[iminvmast_loc_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[iminvmast_loc_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[iminvmast_loc_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[iminvmast_loc_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[iminvmast_loc_vw] TO [public]
GO

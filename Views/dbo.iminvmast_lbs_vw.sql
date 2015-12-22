SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[iminvmast_lbs_vw]
as
SELECT company_code,
       part_no,
       uom,
       vw.status,
       location,
       loc_note,
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
       reason_code,
       reference_code,
       project1,
       project2,
       project3,
       lb_tracking,
       lbs_bin_no,
       lbs_lot_ser,
       lbs_qty,
       lbs_date_tran,
       lbs_date_expires,
       batch_no,
       dirty_flag,
       record_status_1,
       record_status_2,
       process_status,
       record_type,
       record_id_num,
       [User_ID]
  FROM CVO_Control.dbo.iminvmast vw
  where (record_type & 0x00010000 > 0)


GO
GRANT REFERENCES ON  [dbo].[iminvmast_lbs_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[iminvmast_lbs_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[iminvmast_lbs_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[iminvmast_lbs_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[iminvmast_lbs_vw] TO [public]
GO

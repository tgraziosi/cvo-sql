SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[iminvmast_bom_vw] as
SELECT company_code,
        part_no,
       uom,
       location,
       bom_part_no,
       bom_seq_no,
       bom_qty,
       bom_lag_qty,
       bom_pool_qty,
       bom_plan_pcs,
       bom_active_flag,
       bom_constrain,
       bom_fixed,
       bom_conv_factor,
       bom_eff_date,
       batch_no,
       dirty_flag,
       record_status_1,
       record_status_2,
       process_status,
       record_type,
       record_id_num,
       [User_ID]
FROM 	CVO_Control.dbo.iminvmast
where 	(record_type & 4096) > 0



GO
GRANT REFERENCES ON  [dbo].[iminvmast_bom_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[iminvmast_bom_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[iminvmast_bom_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[iminvmast_bom_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[iminvmast_bom_vw] TO [public]
GO

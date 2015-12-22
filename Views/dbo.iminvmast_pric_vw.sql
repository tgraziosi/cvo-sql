SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    create view 
[dbo].[iminvmast_pric_vw] 
    as
    SELECT company_code,
           part_no,
           uom,
           price_a,
           price_b,
           price_c,
           price_d,
           price_e,
           price_f,
           qty_a,
           qty_b,
           qty_c,
           qty_d,
           qty_e,
           qty_f,
           curr_key,
           promo_type,
           promo_rate,
           promo_date_expires,
           promo_date_entered,
           batch_no,
           dirty_flag,
           record_status_1,
           record_status_2,
           process_status,
           record_type,
           record_id_num,
           [User_ID]
FROM   CVO_Control.dbo.iminvmast
where   (record_type & 0x00000008) > 1



GO
GRANT REFERENCES ON  [dbo].[iminvmast_pric_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[iminvmast_pric_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[iminvmast_pric_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[iminvmast_pric_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[iminvmast_pric_vw] TO [public]
GO

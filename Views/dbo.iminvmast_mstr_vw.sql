SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[iminvmast_mstr_vw] as
SELECT  company_code,
        part_no,
        description,
        uom,
        lb_tracking,
        allow_fractions,
        serial_flag,
        cubic_feet,
        weight_ea,
        labor,
        category,
        type_code,
        im.status,
        comm_type,
        cycle_type,
        freight_class,
        note,
        cfg_flag,
        qc_flag,
        account,
        tax_code,
        taxable,
        upc_code,
        sku_code,
        inv_cost_method,
        vendor,
        buyer,
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
        promo_type,
        promo_rate,
        promo_date_expires,
        promo_date_entered,
        std_cost,
        utility_cost,
        curr_key,
        alt_uom,
        rpt_uom,
        batch_no,
        dirty_flag,
        record_status_1,
        record_status_2,
        process_status,
        record_type,
        record_id_num,
        [User_ID],
        [country_code],
        [cmdty_code],
        [height],
        [width],
        [length],
        [min_profit_perc],
        [abc_code],
        [abc_code_frozen_flag]
FROM    CVO_Control.dbo.iminvmast im
where   (record_type & 0x00000001) > 0



GO
GRANT REFERENCES ON  [dbo].[iminvmast_mstr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[iminvmast_mstr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[iminvmast_mstr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[iminvmast_mstr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[iminvmast_mstr_vw] TO [public]
GO

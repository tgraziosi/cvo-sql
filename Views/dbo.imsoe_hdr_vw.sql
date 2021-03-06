SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[imsoe_hdr_vw]
AS
SELECT  company_code,
        order_no,
        cust_code,
        ship_to,
        req_ship_date,
        sch_ship_date,
        date_shipped,
        date_entered,
        cust_po,
        who_entered,
        status,
        attention,
        phone,
        terms,
        routing,
        special_instr,
        invoice_date,
        invoice_no,
	invoice_edi,
        total_invoice,
        total_amt_order,
        salesperson,
        tax_id,
        tax_perc,
        fob,
        freight,
        printed,
        discount,
        cancel_date,
        no_cartons,
        ship_to_name,
        ship_to_add_1,
        ship_to_add_2,
        ship_to_add_3,
        ship_to_add_4,
        ship_to_add_5,
        ship_to_city,
        ship_to_state,
        ship_to_zip,
        ship_to_country,
        ship_to_region,
        pro_number,
        type,
        back_ord_flag,
        who_shipped,
        date_printed,
        date_transfered,
        cr_invoice_no,
        who_picked,
        note,
        void,
        void_who,
        void_date,
        changed,
        remit_key,
        forwarder_key,
        freight_to,
        freight_allow_type,
        location,
        total_tax,
        total_discount,
        f_note,
        post_edi_date,
        blanket,
        gross_sales,
        load_no,
        curr_key,
        curr_type,
        curr_factor,
        bill_to_key,
        oper_factor,
        tot_ord_tax,
        tot_ord_disc,
        tot_ord_freight,
        posting_code,
        rate_type_home,
        rate_type_oper,
        hold_reason,
        dest_zone_code,
        orig_no,
        orig_ext,
        tot_tax_incl,
        process_ctrl_num,
        batch_code,
        tot_ord_incl,

        batch_no,
        dirty_flag,
        record_status_1,
        record_status_2,
        process_status,
        record_type,
        record_id_num,
        [User_ID],
        [blanket_amt],
        [user_priority],
        [user_category],
        [from_date],
        [to_date],
        [consolidate_flag],
        [proc_inv_no],
        [sold_to_addr1],
        [sold_to_addr2],
        [sold_to_addr3],
        [sold_to_addr4],
        [sold_to_addr5],
        [sold_to_addr6],
        [user_code],
        [user_def_fld1],
        [user_def_fld2],
        [user_def_fld3],
        [user_def_fld4],
        [user_def_fld5],
        [user_def_fld6],
        [user_def_fld7],
        [user_def_fld8],
        [user_def_fld9],
        [user_def_fld10],
        [user_def_fld11],
        [user_def_fld12]
FROM    [CVO_Control]..[imsoe]
where   (record_type & 0x00000001 ) > 0



GO
GRANT REFERENCES ON  [dbo].[imsoe_hdr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imsoe_hdr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imsoe_hdr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imsoe_hdr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imsoe_hdr_vw] TO [public]
GO

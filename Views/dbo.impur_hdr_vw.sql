SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[impur_hdr_vw] as
select
	company_code,
	status,
	po_type,
	printed,
	vendor_no,
	date_of_order,
	date_order_due,
	ship_to_no,
	ship_name,
	ship_address1,
	ship_address2,
	ship_address3,
	ship_address4,
	ship_address5,
	ship_city,
	ship_state,
	ship_zip,
	ship_via,
	fob,
	tax_code,
	terms,
	attn,
	blanket,
	who_entered,
	total_amt_order,
	date_to_pay,
	discount,
	vend_inv_no,
	email,
	email_name,
	--note,
	po_key,
	po_ext,
	curr_key,
	curr_type,
	curr_factor,
	buyer,
	location,
	prod_no,
	oper_factor,
	hold_reason,
	phone,
	total_tax,
	rate_type_home,
	rate_type_oper,
	reference_code,
	posting_code,
        [User_ID],
        [user_code],
        [expedite_flag],
        [vend_order_no],
        [requested_by],
        [approved_by],
        [user_category],
        [blanket_flag],
        [date_blnk_from],
        [date_blnk_to],
        [amt_blnk_limit],
        batch_no,
        dirty_flag,
        record_status_1,
        record_status_2,
        process_status,
        record_type,
        record_id_num
FROM    CVO_Control.dbo.impur
where   (record_type & 0x00000001 ) > 0
GO
GRANT REFERENCES ON  [dbo].[impur_hdr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[impur_hdr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[impur_hdr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[impur_hdr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[impur_hdr_vw] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create VIEW [dbo].[imsoe_line_vw]
AS
SELECT
	company_code,
	order_no,
	line_no,
	line_location,
	part_no,
	description,
	ordered,
	shipped,
	uom,
	conv_factor,
	price,
	price_type,
	line_discount,
	line_status,
	lb_tracking,
	weight_ea,
	part_type,
	gl_rec_acct,
	taxable,
	line_total_tax,
	tax_code,
	cost,
	reference_code,
	contract,
	line_note,
	back_ord_flag,
	printed,
	time_entered,
	who_entered,

	batch_no,
	dirty_flag,
	record_status_1,
	record_status_2,
	process_status,
	record_type,
	record_id_num,
        [User_ID]
FROM [CVO_Control]..[imsoe]
WHERE  (record_type & 0x00000002) > 0



GO
GRANT REFERENCES ON  [dbo].[imsoe_line_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imsoe_line_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imsoe_line_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imsoe_line_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imsoe_line_vw] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[imsoe_shipr_vw]
as 	select
	company_code,
	cust_code,
	ship_to,
    ship_to_region,
	order_no,
	ext as order_ext,
	location,
	part_no,
    date_shipped,
	ordered,
	shipped,
	price,
	price_type,
	cost,
	sales_comm,
	cr_ordered,
	cr_shipped,
	salesperson,
	labor,
	direct_dolrs,
	ovhd_dolrs,
	util_dolrs,
	line_no,
	conv_factor,
	part_type,

	batch_no,
	dirty_flag,
	record_status_1,
	record_status_2,
	process_status,
	record_type,
	record_id_num,
        [User_ID]
from CVO_Control.dbo.imsoe
where (record_type & 0x00000010) > 0



GO
GRANT REFERENCES ON  [dbo].[imsoe_shipr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imsoe_shipr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imsoe_shipr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imsoe_shipr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imsoe_shipr_vw] TO [public]
GO

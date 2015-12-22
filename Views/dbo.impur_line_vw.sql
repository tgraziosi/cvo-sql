SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[impur_line_vw] as
select
	company_code,
	part_no,
	location,
	type,
	vend_sku,
	account_no,
	description,
	unit_cost,
	unit_measure as uom,
	line_note,
	rel_date,
	qty_ordered,
	qty_received,
	who_entered,
	status,
	conv_factor,
	lb_tracking,
	line,
	taxable,
	prev_qty,
	po_key,
	weight_ea,
	tax_code,
	curr_factor,
	oper_factor,
	total_tax,
	curr_cost,
	oper_cost,
	reference_code,
	project1,
	project2,
	project3,
        batch_no,
        receiving_loc, 
        shipto_code, 
        [shipto_name],    
        [addr1],
        [addr2],                     
        [addr3],          
        [addr4],
        [addr5], 
        [User_ID],
        dirty_flag,
        record_status_1,
        record_status_2,
        process_status,
        record_type,
        record_id_num
FROM    CVO_Control.dbo.impur
where   (record_type & 0x00000010 ) > 0
GO
GRANT REFERENCES ON  [dbo].[impur_line_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[impur_line_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[impur_line_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[impur_line_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[impur_line_vw] TO [public]
GO

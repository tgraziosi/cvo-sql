SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_dis_pick_tkt_data_sp] (
  @order_no int, 
  @order_ext int, 
  @data_type varchar(1),
  @User_ID varchar(50)
  )
AS

if (@data_type = 'H')
BEGIN
select  DISTINCT 
    location, location AS LOCATION_HDR, 
    ord_plus_ext = convert(varchar(8), a.order_no) 
    + '-' + convert(varchar(8), a.ext),  a.order_no, a.special_instr, a.note order_note,
    a.order_no AS DetailCriteria, a.ext, a.cust_po, cust_code, 
    date_entered order_date, sch_ship_date, a.routing carrier_desc, ship_to_name, 
    ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_city, 
    ship_to_state, ship_to_zip, ship_to_country, @User_ID User_id,
    c.customer_name, c.addr1, c.addr2, c.addr3, c.addr4, c.addr5, a.special_instr
	from orders a (NOLOCK), inv_master b (NOLOCK), arcust c (NOLOCK)
	where a.cust_code = c.customer_code
	and order_no = @order_no
	and ext = @order_ext
END

if (@data_type = 'D')
BEGIN
(SELECT NULL kit_id, NULL kit_caption, a.line_no, a.part_type, 
    a.uom, b.[description], a.ordered ord_qty, 
QTY_TO_PICK = CASE WHEN (a.ordered - a.shipped) < 0 THEN 0  ELSE (a.ordered - a.shipped) END, 
    a.part_no, b.note, a.note comment
FROM ord_list a, inv_master b
WHERE a.order_no = @order_no
and a.order_ext = @order_ext
and a.part_no = b.part_no
and a.part_type <> 'C'
UNION SELECT a.part_no kit_id,  ('** CUSTOM KIT **' + '    ' +  a.part_no + '    ' + b.[description]) kit_caption,
 a.line_no, c.part_type, c.uom, b.[description], a.ordered ord_qty, 
QTY_TO_PICK = CASE WHEN (c.ordered - c.shipped) < 0 THEN 0  ELSE (c.ordered - c.shipped) END, 
    a.kit_part_no, b.note, c.note comment
FROM tdc_ord_list_kit a, inv_master b, ord_list c
WHERE a.order_no = @order_no
and a.order_ext = @order_ext
and a.part_no = b.part_no
and a.order_no = c.order_no
and a.order_ext = c.order_ext
and a.line_no = c.line_no)
order by Line_no, a.part_no

END

GO
GRANT EXECUTE ON  [dbo].[tdc_get_dis_pick_tkt_data_sp] TO [public]
GO

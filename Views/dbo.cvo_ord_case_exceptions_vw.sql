SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[cvo_ord_case_exceptions_vw]
as

-- select * From cvo_ord_case_exceptions_vw

-- Frame Lines without cases

-- frame lines
select top (100) percent 'FrameNoCase' issue, frames.*
from 
(select top (100) percent  o.cust_code, o.ship_to, o.ship_To_name, o.order_no, o.ext, ol.line_no
, ol.part_no, ia.field_1 case_part,  ol.ordered - ol.shipped qty
 From ord_list ol (nolock)
inner join cvo_ord_list col (nolock) on col.order_no = ol.order_no and col.order_ext = ol.order_ext 
	and col.line_no = ol.line_no
inner join inv_master_add ia (nolock) on ia.part_no = ol.part_no
inner join inv_master i (nolock) on i.part_no = ol.part_no
inner join orders o (nolock) on o.order_no = ol.order_no and o.ext = ol.order_ext
where o.status < 'r' and i.type_code in ('frame','sun') 
	and o.type = 'i' 
	and isnull(col.add_case,'n') = 'y'

) frames
left outer join
-- case part
(select o.order_no, o.ext, ol.line_no, ol.part_no case_part, sum(ordered) qty
 From ord_list ol
inner join inv_master_add ia (nolock) on ia.part_no = ol.part_no
inner join inv_master i (nolock) on i.part_no = ol.part_no
inner join orders o (nolock) on o.order_no = ol.order_no and o.ext = ol.order_ext
where o.status < 'r' and i.type_code in ('case') and o.type = 'i' 
group by o.order_no, o.ext, ol.line_no, ol.part_no
) as cases on cases.case_part = frames.case_part 
	and cases.order_no = frames.order_no
	and cases.ext = frames.ext
where isnull(frames.case_part,'') <> isnull(cases.case_part,'')

-- Case lines with no Frames

union all

-- frame lines
select top (100) percent 'CaseNoFrame' issue, cases.*
from 
-- case part
(select top (100) percent o.cust_code, o.ship_to, o.ship_to_name, o.order_no, o.ext, ol.line_no
 , '' as part_no, ol.part_no case_part, sum(ordered) qty
 From ord_list ol (nolock)
inner join inv_master_add ia (nolock) on ia.part_no = ol.part_no
inner join inv_master i (nolock) on i.part_no = ol.part_no
inner join orders o (nolock) on o.order_no = ol.order_no and o.ext = ol.order_ext
where o.status < 'r' and i.type_code in ('case') and o.type = 'i' 
group by o.cust_code, o.ship_to, o.ship_to_name, o.order_no, o.ext, ol.line_no, ol.part_no
) as cases
left outer join
(select o.cust_code, o.ship_to, col.add_case, o.order_no, o.ext, ol.line_no, ol.part_no, ia.field_1 case_part
 From ord_list ol (nolock)
inner join cvo_ord_list col (nolock) on col.order_no = ol.order_no and col.order_ext = ol.order_ext 
	and col.line_no = ol.line_no
inner join inv_master_add ia (nolock) on ia.part_no = ol.part_no
inner join inv_master i (nolock) on i.part_no = ol.part_no
inner join orders o (nolock) on o.order_no = ol.order_no and o.ext = ol.order_ext
where o.status < 'r' and i.type_code in ('frame','sun') 
	and o.type = 'i' 
	and isnull(col.add_case,'n') = 'y'

) frames
 on cases.case_part = frames.case_part 
	and cases.order_no = frames.order_no
	and cases.ext = frames.ext
where isnull(frames.case_part,'') <> isnull(cases.case_part,'')
GO
GRANT REFERENCES ON  [dbo].[cvo_ord_case_exceptions_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_ord_case_exceptions_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_ord_case_exceptions_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_ord_case_exceptions_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_ord_case_exceptions_vw] TO [public]
GO

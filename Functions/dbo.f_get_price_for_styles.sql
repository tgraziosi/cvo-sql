SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- select * from f_get_price_for_styles ('bcgcolink5316')
-- tg - 2/27/2014 - used by cvo_inv_master_r2_vw to get style pricing.
-- tg - 100114 - redo to get correct pricing - use logic from frames data extract
-- select * from cvo_inv_master_r2_vw where model = 'glam'

CREATE FUNCTION [dbo].[f_get_price_for_styles] ()
RETURNS @rettab table (collection varchar(20), style varchar(30), part_no varchar(40),
                        frame_price float,
                        temple_price float,
                        front_price float,
                        frame_cost float, -- 060614
                        temple_cost float,
                        cable_cost float,
                        front_cost float)
AS
begin
    ;with cte as 
-- details
(
select i.web_saleable_Flag, case when i.type_code ='parts' then '' else i.type_code end as type_code, 
ia.category_3 part_type, i.category, ia.field_2 style, i.part_no,
ia.field_28 pom_date,
case when i.type_code in ('frame','sun') then ia.field_13 else '' end as hinge_type, 
case when i.type_code in ('frame','sun','chassis') then p.price_a else 0 end as frame_price,
case when i.type_code in ('frame','sun','chassis') then ila.std_cost else 0 end as frame_cost
,
cast(round(case when iia.category_3 = 'temple-l' 
	and iia.category_5 = ia.category_5 -- color
	then pp.price_a else 0 end,2) as decimal(8,2)) 
	as temple_price
, 
cast(round(case when iia.category_3 = 'front' 
	--and iia.category_5 = ia.category_5 -- color
	--and iia.field_17 = ia.field_17 -- eye size
	then pp.price_a else 0 end,2) as decimal(8,2)) 
	as Front_price
, 
cast(round(case when iia.category_3 = 'temple-l' and iia.part_no like '%ls%'
		--and iia.category_5 = ia.category_5 -- color
		then iil.std_cost else 0 end,2) as decimal(8,2))
		 as temple_cost
,	
cast(round(case when iia.category_3 = 'temple-l' and iia.part_no like '%lc%'
		--and iia.category_5 = ia.category_5 -- color
		then iil.std_cost else 0 end,2) as decimal(8,2))
		 as cable_cost
,
cast(round(case when iia.category_3 = 'front' 
		--and iia.category_5 = ia.category_5 -- color
		--and iia.field_17 = ia.field_17 -- eye_size
		then iil.std_cost else 0 end,2) as decimal(8,2))
		 as front_cost
	
   
from 
	-- assembly data
	inv_master i (nolock) 
	inner join inv_master_add ia (nolock) on ia.part_no = i.part_no
	inner join part_price p (nolock) on p.part_no = i.part_no
	inner join inv_list ila (nolock) on ila.part_no = i.part_no and ila.location = '001'
	-- get bom
	inner join what_part bom (nolock) on bom.asm_no = i.part_no
	-- component data
	inner join inv_list iil (nolock) on iil.part_no = bom.part_no and iil.location = '001'
	inner join inv_master ii (nolock) on ii.part_no = bom.part_no
	inner join inv_master_add iia (nolock) on iia.part_no = ii.part_no
	inner join part_price pp (nolock) on pp.part_no = ii.part_no
	
	where 1=1
	and i.void = 'N'
	AND I.TYPE_code in ('frame','sun')
	-- and exists ( select 1 from what_part where asm_no = i.part_no)
	and ii.void = 'n' 
	and ii.type_code in ('parts') 
	and bom.active = 'a'
)
-- select * from cte

-- summary
insert into @rettab
select cte.category, cte.style, cte.part_no, max(cte.frame_price) frame_price, max(cte.temple_price) temple_price, 
max(cte.front_price) front_price, max(cte.frame_cost) frame_cost, max(temple_cost) temple_cost,  
max(cable_cost) cable_cost, max(front_cost) front_cost

from cte
group by category, style, part_no
-- order by category, style, part_no
    
RETURN
END

GO

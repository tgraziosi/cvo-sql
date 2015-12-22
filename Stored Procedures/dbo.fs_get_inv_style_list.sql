SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_get_inv_style_list] 
	@base_part varchar(30), @attrib1_scale varchar(30), @attrib2_scale varchar(30)  as
begin

set nocount on

create table #grid(
	part_no varchar(50) null,
	size_1 varchar(15) not null,
	size_2 varchar(15) not null,
	valid int null,
	void int ,
	checked decimal(20,8),
	scale_name varchar(30) not null,
	scale2_name varchar(30) not null )

declare @msg varchar(255)

-- verify if scale ranges exist - if not - exit
if @attrib1_scale = 'NONE' and @attrib2_scale = 'NONE'
begin
	select @msg =  'Cannot create grid with both Scale Ranges set to NONE!'
 	RAISERROR ( @msg, 16, 1)
	return
end

if  not exists (select scale from inv_scale_vw where scale_code = @attrib1_scale) 
begin
	select @msg =  'Attribute 1 Scale is invalid! No rows exist for Attribute Scale ' + @attrib1_scale + ' in view, inv_scale_vw'
 	RAISERROR (@msg, 16, 1)
	return
end
if  not exists (select scale from inv_scale_vw2 where scale_code = @attrib2_scale)
begin
	select @msg =  'Attribute 2 Scale is invalid! No rows exist for Attribute Scale ' + @attrib2_scale + ' in view, inv_scale_vw'
 	RAISERROR ( @msg, 16, 1)
	return
end

-- insert into the base grid
insert into #grid ( part_no, size_1, size_2, valid, void, checked, scale_name, scale2_name ) 
select Case when inv_scale_vw2.scale_code = 'NONE' then @base_part + '-' + inv_scale_vw.scale  
 	 	when inv_scale_vw.scale_code  = 'NONE' then @base_part + '-' + inv_scale_vw2.scale
	 	else @base_part + '-' + inv_scale_vw.scale  + '-' + inv_scale_vw2.scale
	 	end, 
	 inv_scale_vw.scale, 
	 inv_scale_vw2.scale,
	 0, 0, 0.0, 
	 inv_scale_vw.scale_name, 
	 inv_scale_vw2.scale_name
from inv_scale_vw, inv_scale_vw2
where inv_scale_vw.scale_code = @attrib1_scale and inv_scale_vw2.scale_code = @attrib2_scale
and (inv_scale_vw2.scale_name <> 'NONE' or @attrib2_scale = 'NONE')
and (inv_scale_vw.scale_name <> 'NONE' or @attrib1_scale = 'NONE')
order by inv_scale_vw.sequence, inv_scale_vw2.sequence

-- set valid part flags. NOTE - a value of 1 means Yes, 0 means No
update #grid 
set 	valid = 1, 
	checked =  case when i.void = 'V' then 0.0  else 1.0 end,
	void    =  case when i.void = 'V' then 1    else 0 end
from #grid g, inv_master i (nolock)
where g.part_no = i.part_no

select part_no, size_1, size_2, valid, void , checked, scale_name ,scale2_name
from #grid
--order by part_no

end 
GO
GRANT EXECUTE ON  [dbo].[fs_get_inv_style_list] TO [public]
GO

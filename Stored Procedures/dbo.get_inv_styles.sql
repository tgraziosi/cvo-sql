SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[get_inv_styles] 
	@strsort varchar(50), -- search string (may be part of an item or description)
	@sort char(1), 		-- what we are searching by (either item or description)
	@void char(1), 		-- if we include voids in the return set
	@lastkey varchar(30), 	-- last selected item
	@iobs int,			-- if we include obsolete items or not
	@minstat char(1),		-- minimum part type to look in
	@maxstat char(1),		-- maximum part type to look in
	@styles_only int		-- look in styles only (inv_attrib_style_master)
	 
AS

set rowcount 100


if @styles_only = 1  -- this section will only return parts that have been used as a base part (ie the style)
begin
	if @sort='N' 
	begin

		select i.part_no, description, attrib1_scale_name as scale1 , attrib2_scale_name as scale2,
			case isnull(status,'')
		    		when 'A' then 'Active'
		    		when 'P' then 'Purchase'
		    		when 'M' then 'Make'
		    		when 'V' then 'Non Qty Bearing'
		    		when 'K' then 'Auto-Kit'
    				when 'H' then 'Make-Routed'
    				when 'Q' then 'Pur/Outsource'
    				else '' end as status	
		from inv_master i ( NOLOCK ), inv_attrib_style_master a (nolock)
		where ( i.part_no = a.base_part_no ) AND 
			( i.part_no >= @strsort OR @strsort is null)  and 
			( i.part_no >= @lastkey ) and
 			( void is NULL OR void like @void ) and
 			( status >= @minstat AND status <= @maxstat ) and
			( status <> 'R' and status <> 'C') AND 
 			( obsolete <= @iobs ) 
		order by i.part_no
	end  
	else
	begin -- @sort must = 'K' at this point...

		select i.part_no, description, attrib1_scale_name as scale1 , attrib2_scale_name as scale2,
			case isnull(status,'')
		    		when 'A' then 'Active'
		    		when 'P' then 'Purchase'
		    		when 'M' then 'Make'
		    		when 'V' then 'Non Qty Bearing'
		    		when 'K' then 'Auto-Kit'
    				when 'H' then 'Make-Routed'
    				when 'Q' then 'Pur/Outsource'
    				else '' end as status	
		from inv_master i ( NOLOCK ), inv_attrib_style_master a (nolock)
		where ( i.part_no = a.base_part_no ) AND 
			( i.description like @strsort OR @strsort is null ) AND
 			( i.part_no >= @lastkey ) and
 			( void is NULL OR void like @void ) and
 			( status >= @minstat AND status <= @maxstat ) and
			( status <> 'R' and status <> 'C') AND 
 			( obsolete <= @iobs ) 
		order by i.part_no

	end 
END
ELSE
BEGIN

	if @sort='N' 
	begin

		select i.part_no, description, attrib1_scale_name as scale1 , attrib2_scale_name as scale2,
			case isnull(status,'')
		    		when 'A' then 'Active'
		    		when 'P' then 'Purchase'
		    		when 'M' then 'Make'
		    		when 'V' then 'Non Qty Bearing'
		    		when 'K' then 'Auto-Kit'
    				when 'H' then 'Make-Routed'
    				when 'Q' then 'Pur/Outsource'
    				else '' end as status
		from inv_master i ( NOLOCK )
                left outer join inv_attrib_style_master a (nolock) on ( i.part_no = a.base_part_no ) 
		where ( i.part_no >= @strsort OR @strsort is null)  and 
			( i.part_no >= @lastkey ) and
 			( void is NULL OR void like @void ) and
 			( status >= @minstat AND status <= @maxstat ) and
			( status <> 'R' and status <> 'C') AND 
 			( obsolete <= @iobs ) 
		order by i.part_no

	end  
 	else
	begin -- @sort must = 'K' at this point...
			-- select @strsort = '%' + @strsort + '%'

		select i.part_no, description, attrib1_scale_name as scale1 , attrib2_scale_name as scale2,
			case isnull(status,'')
		    		when 'A' then 'Active'
		    		when 'P' then 'Purchase'
		    		when 'M' then 'Make'
		    		when 'V' then 'Non Qty Bearing'
		    		when 'K' then 'Auto-Kit'
    				when 'H' then 'Make-Routed'
    				when 'Q' then 'Pur/Outsource'
    				else '' end as status
	
		from inv_master i ( NOLOCK )
                left outer join inv_attrib_style_master a (nolock) on ( i.part_no = a.base_part_no )
		where ( i.description like @strsort OR @strsort is null ) AND
 			( i.part_no >= @lastkey ) and
 			( void is NULL OR void like @void ) and
 			( status >= @minstat AND status <= @maxstat ) and
			( status <> 'R' and status <> 'C') AND 
 			( obsolete <= @iobs )
		order by i.part_no

	end 
end

set rowcount 0




GO
GRANT EXECUTE ON  [dbo].[get_inv_styles] TO [public]
GO

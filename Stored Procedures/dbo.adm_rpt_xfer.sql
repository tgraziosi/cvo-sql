SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- entry screen with open orders only
-- date shipped r.date
-- xfer_no  x.xfer_no

-- mls 2/13/06 - SCR 35401 - included shipped xfers

create procedure [dbo].[adm_rpt_xfer] @order int = 0, 
@openxfers  int = 0 , 
@range varchar(8000) = ' 0=0' as
begin
declare @sql varchar(8000), @status char(1)

create table #rpt_xfer (
	xfer_no int NULL,
	from_loc varchar(10) NULL,
	to_loc varchar(10) NULL,
	req_ship_date datetime NULL,
	sch_ship_date datetime NULL,
	date_shipped datetime NULL,
	status char(1) NULL,
	l_line_no int NULL,
	l_part_no varchar(30) NULL,
	l_description varchar(255) NULL,
	l_ordered decimal(20,8) NULL,
	l_shipped decimal(20,8) NULL,
	l_uom char(2) NULL,
	l_from_bin varchar(12) NULL,
	l_to_bin varchar(12) NULL,
	l_lot_ser varchar(25) NULL,
	to_loc_name varchar(40) NULL,
	lo_name varchar(40) NULL,
	b_bin_no varchar(12) NULL,
	b_lot_ser varchar(25) NULL,
	b_qty decimal(20,8) NULL,
	lf_location varchar(10) NULL,
	lt_location varchar(10) NULL,
	s_status varchar(20) NULL
)

if @openxfers = 1
  select @range = replace(@range,'r.rdate','datediff(day,"01/01/1900",x.sch_ship_date) + 693596 '),
    @status = 'Q'
else
  select @range = replace(@range,'r.rdate','case when x.status >= "R" then datediff(day,"01/01/1900",x.date_shipped) + 693596  else datediff(day,"01/01/1900",x.sch_ship_date) + 693596  end '),
    @status = 'S'								-- mls SCR35401 2/13/06

select @range = replace(@range,'"','''')

select @sql = 
'insert #rpt_xfer
  SELECT distinct  x.xfer_no ,
           x.from_loc ,
           x.to_loc ,
           x.req_ship_date ,
           x.sch_ship_date ,
           x.date_shipped ,
           x.status ,
           xfer_list.line_no ,
           xfer_list.part_no ,
           xfer_list.description ,
           xfer_list.ordered ,
           case when x.status = ''S'' then isnull(xfer_list.qty_rcvd,xfer_list.shipped) else xfer_list.shipped end,
           xfer_list.uom ,
           xfer_list.from_bin ,
           xfer_list.to_bin ,
           xfer_list.lot_ser ,
           x.to_loc_name ,
           locations.name ,
           lot_bin_xfer.bin_no ,
           isnull(lot_bin_xfer.lot_ser,''<!NULL!>'') ,
           case when x.status = ''S'' then isnull(lot_bin_xfer.qty_received,isnull(lot_bin_xfer.qty,0)) 
              when x.status = ''N'' then xfer_list.ordered
              else isnull(lot_bin_xfer.qty,0) end,
			  locations.location,
			  l_to.location  l_to_location  ,
	   case x.status 
           when ''N'' then ''Open : New''
           when ''O'' then ''Open''
           when ''P'' then ''Open : Picked''
           when ''Q'' then ''Open : Printed''
           when ''R'' then ''Shipped''
           when ''S'' then ''Shipped : Received''
           when ''V'' then ''Void''
	   else x.status end
        FROM xfers_all x
	join xfer_list (nolock) on ( x.xfer_no = xfer_list.xfer_no )
       	join locations locations (nolock) on ( x.from_loc = locations.location )
        left outer join lot_bin_xfer (nolock) on ( xfer_list.xfer_no = lot_bin_xfer.tran_no) and
          ( xfer_list.line_no = lot_bin_xfer.line_no)
	join locations l_to (nolock) on ( x.to_loc = l_to.location )
	join region_vw rf (nolock) on locations.organization_id = rf.org_id
 	join region_vw rt (nolock) on l_to.organization_id = rt.org_id
        WHERE ( x.status <= ''' + @status  + ''' )  and ' + @range		-- mls SCR35401 2/13/06
exec (@sql)

select * from #rpt_xfer
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_xfer] TO [public]
GO

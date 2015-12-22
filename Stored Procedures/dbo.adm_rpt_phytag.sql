SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_phytag] @order int = 1, 
@batch_id varchar(16) = '', 
@range varchar(8000) = ' 0=0'
as
begin
select @range = replace(@range,'"','''')

  create table #rpt_phytag (
	location varchar(10) NULL,
	phy_no int NULL,
	part_no varchar(30) NULL,
	qty decimal(20,8) NULL,
	orig_qty decimal(20,8) NULL,
	description varchar(255) NULL,
	uom char(2) NULL,
	phy_batch int NULL,
	lot_ser varchar(25) NULL,
	date_expires datetime NULL,
	b_qty decimal(20,8) NULL,
	lb_tracking char(1) NULL,
	serial_flag int NULL,
	bin_no varchar(12) NULL,
	group_1 varchar(255) null,
	group_2 varchar(255) NULL,
	group_3 varchar(255) NULL,
	h_dec_separator char(1) NULL,
	h_thou_separator char(1) NULL,
	blind_ind int NULL,
	qty_precision int NULL,
	orig_qty_precision int NULL,
	b_qty_precision int NULL
)

if @batch_id != ''
begin
exec('insert #rpt_phytag
  SELECT distinct  physical.location ,
           physical.phy_no ,
           physical.part_no ,
           physical.qty ,
           physical.orig_qty ,
           inv_master.description ,
           inv_master.uom ,
           physical.phy_batch ,
           lot_bin_phy.lot_ser ,
           lot_bin_phy.date_expires ,
           lot_bin_phy.qty ,
           inv_master.lb_tracking ,
           inv_master.serial_flag ,
           lot_bin_phy.bin_no,
replicate ('' '',11 - datalength(convert(varchar(11),physical.phy_batch))) + convert(varchar(11),physical.phy_batch),
replicate ('' '',11 - datalength(convert(varchar(11),physical.phy_no))) + convert(varchar(11),physical.phy_no),
physical.part_no,
''.'',
'','',
isnull((select 0 from config(nolock) where upper(flag) = ''INV_PHY_BLIND'' and upper(left(value_str,1)) = ''N''),1),
datalength(rtrim(replace(cast(physical.qty as varchar(40)),''0'','' ''))) - charindex(''.'',cast(physical.qty as varchar(40))),
datalength(rtrim(replace(cast(physical.orig_qty as varchar(40)),''0'','' ''))) - charindex(''.'',cast(physical.orig_qty as varchar(40))),
isnull(datalength(rtrim(replace(cast(lot_bin_phy.qty as varchar(40)),''0'','' ''))) - charindex(''.'',cast( lot_bin_phy.qty as varchar(40))),0)

        FROM physical 
        join inv_master (nolock) on ( physical.part_no = inv_master.part_no )
        join phy_hdr (nolock) on   ( physical.phy_batch = phy_hdr.phy_batch )
        left outer join lot_bin_phy (nolock) on ( lot_bin_phy.phy_no = physical.phy_no) and
          ( lot_bin_phy.location = physical.location) and
          ( lot_bin_phy.part_no = physical.part_no) and
	 ( lot_bin_phy.phy_batch = physical.phy_batch) 
	join locations l (nolock) on   l.location = physical.location 
	join region_vw r (nolock) on   l.organization_id = r.org_id
        WHERE ( phy_hdr.status = ''N'') and phy_hdr.phy_batch = ''' + @batch_id + '''')
end
else
begin
exec('insert #rpt_phytag
  SELECT distinct  physical.location ,
           physical.phy_no ,
           physical.part_no ,
           physical.qty ,
           physical.orig_qty ,
           inv_master.description ,
           inv_master.uom ,
           physical.phy_batch ,
           lot_bin_phy.lot_ser ,
           lot_bin_phy.date_expires ,
           lot_bin_phy.qty ,
           inv_master.lb_tracking ,
           inv_master.serial_flag ,
           lot_bin_phy.bin_no,
replicate ('' '',11 - datalength(convert(varchar(11),physical.phy_batch))) + convert(varchar(11),physical.phy_batch),
replicate ('' '',11 - datalength(convert(varchar(11),physical.phy_no))) + convert(varchar(11),physical.phy_no),
physical.part_no,
''.'',
'','',
isnull((select 0 from config(nolock) where upper(flag) = ''INV_PHY_BLIND'' and upper(left(value_str,1)) = ''N''),1),
datalength(rtrim(replace(cast(physical.qty as varchar(40)),''0'','' ''))) - charindex(''.'',cast(physical.qty as varchar(40))),
datalength(rtrim(replace(cast(physical.orig_qty as varchar(40)),''0'','' ''))) - charindex(''.'',cast(physical.orig_qty as varchar(40))),
isnull(datalength(rtrim(replace(cast(lot_bin_phy.qty as varchar(40)),''0'','' ''))) - charindex(''.'',cast( lot_bin_phy.qty as varchar(40))),0)

        FROM physical 
        join inv_master (nolock) on ( physical.part_no = inv_master.part_no )
        join phy_hdr (nolock) on   ( physical.phy_batch = phy_hdr.phy_batch )
        left outer join lot_bin_phy (nolock) on ( lot_bin_phy.phy_no = physical.phy_no) and
          ( lot_bin_phy.location = physical.location) and
          ( lot_bin_phy.part_no = physical.part_no) and
	 ( lot_bin_phy.phy_batch = physical.phy_batch) 
	join locations l (nolock) on   l.location = physical.location 
	join region_vw r (nolock) on   l.organization_id = r.org_id
        WHERE ( phy_hdr.status = ''N'') and ' + @range)
end

select * from #rpt_phytag
order by group_1, group_2, group_3
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_phytag] TO [public]
GO

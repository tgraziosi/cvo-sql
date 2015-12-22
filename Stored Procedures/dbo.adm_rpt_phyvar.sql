SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_phyvar] @order int = 0, 
@range varchar(8000) = ' 0=0'
 as


BEGIN

select @range = replace (@range,'"','''')

  create table #rpt_phyvar (
	location varchar(10) NULL,
	part_no varchar(30) NULL,
	bin_no varchar(12) NULL,
	lot_ser varchar(25) NULL,
	qty decimal(20,8) NULL,
	orig_qty decimal(20,8) NULL,
	description varchar(255) NULL,
	phy_batch int NULL,
	phy_no int NULL,
	uom char(2) NULL,
	date_expires datetime NULL,
	lb_tracking char(1) NULL,
	serial_flag int NULL,
	group_1 varchar(255) null,
	group_2 varchar(255) NULL,
	group_3 varchar(255) NULL,
	h_dec_separator char(1) NULL,
	h_thou_separator char(1) NULL,
	qty_precision int NULL,
	orig_qty_precision int NULL
)

exec ('insert #rpt_phyvar
SELECT 	distinct p.location, 
		p.part_no, 
		lbp.bin_no, 
		lbp.lot_ser,
		case when lbp.part_no is NULL then p.qty else lbp.qty_physical end,	
		case when lbp.part_no is NULL then p.orig_qty else lbp.qty end,	
		i.description, 
		p.phy_batch, 
		p.phy_no,
		i.uom,
		lbp.date_expires,
		i.lb_tracking,	
		i.serial_flag,
replicate ('' '',11 - datalength(convert(varchar(11),p.phy_batch))) + convert(varchar(11),p.phy_batch),	
p.location, 
p.part_no, 
''.'',
'','',
0,0
FROM physical p
join inv_master i (nolock) on p.part_no = i.part_no 
left outer join lot_bin_phy lbp (nolock) on p.part_no = lbp.part_no and 
	p.phy_no = lbp.phy_no and 
	p.phy_batch = lbp.phy_batch and 
	p.location = lbp.location 
join locations l (nolock) on l.location = p.location 
join region_vw r (nolock) on l.organization_id = r.org_id 
WHERE 	p.qty <> p.orig_qty and ' + @range)

if not exists (select 1 from #rpt_phyvar)
begin
  insert #rpt_phyvar (phy_batch, phy_no, qty)
  select 0, -1, -1
end

update #rpt_phyvar
set qty_precision = 
datalength(rtrim(replace(cast(qty as varchar(40)),'0',' '))) - charindex('.',cast(qty as varchar(40))),
orig_qty_precision =
datalength(rtrim(replace(cast(orig_qty as varchar(40)),'0',' '))) - charindex('.',cast(orig_qty as varchar(40)))

select * from #rpt_phyvar
order by group_1, group_2, group_3

END

GO
GRANT EXECUTE ON  [dbo].[adm_rpt_phyvar] TO [public]
GO

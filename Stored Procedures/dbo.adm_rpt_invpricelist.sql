SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_invpricelist] 
@order int = 0, 
@expirationD_cutoff_char int = 0, 
@range varchar(8000) = ' l.location = "Dallas"' as
BEGIN
declare @range1 varchar(8000)

create table #rpt_invpricelist(
	part_no varchar(30) NULL,
	description varchar(255) NULL,
	category varchar(10) NULL,
	type_code varchar(10) NULL,
	status varchar(20) NULL,
	price_a decimal(20,8) NULL,
	price_b decimal(20,8) NULL,
	price_c decimal(20,8) NULL,
	void char(1) NULL,
	promo_type varchar(20) NULL,
	promo_rate decimal(20,8) NULL,
	promo_expires datetime NULL,
	promo_entered datetime NULL,
	account varchar(32) NULL,
	price_d decimal(20,8) NULL,
	price_e decimal(20,8) NULL,
	price_f decimal(20,8) NULL,

	qty_a decimal(20,8) NULL,
	qty_b decimal(20,8) NULL,
	qty_c decimal(20,8) NULL,
	qty_d decimal(20,8) NULL,
	qty_e decimal(20,8) NULL,
	qty_f decimal(20,8) NULL,
	curr_key varchar(20) NULL,
	group_1 varchar(255) null,
	group_2 varchar(255) NULL,
	group_3 int NULL,
	group_4 varchar(255) NULL,
	promo_date_cutoff varchar(20) NULL,
	org_level int NULL,
	loc_org_id varchar(30) NULL
)

declare @expirationD_cutoff datetime, @sql varchar(8000),
 @y int, @m int, @d int

if isnull(@expirationD_cutoff_char,0) = 0
  exec appdate_sp @expirationD_cutoff_char OUT

select @range1 = replace(@range,'"','''')

select @sql = 'insert #rpt_invpricelist
SELECT distinct inv_master.part_no , 
 inv_master.description , 
 inv_master.category , 
 inv_master.type_code , 
 inv_master.status , 
 part_price.price_a , 
 part_price.price_b , 
 part_price.price_c , 
	 inv_master.void , 
	Case When ( ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + ' <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596  ) and
			part_price.promo_type = ''D''
		then ''Discount, %'' 
	 When ( ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596 ) and
			part_price.promo_type = ''P''
		then ''PRICE'' 
	 When ( ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + ' <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596 ) and
			part_price.promo_type = ''N''
		then null 
	 Else null
	End , 
	Case When ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596
		then part_price.promo_rate 
	 Else null
	End ,
	Case When ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596
		then part_price.promo_date_expires 
	 Else null
	End ,

 	Case When ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596
		then part_price.promo_date_entered 
	 Else null
	End , 
 inv_master.account , 
 part_price.price_d , 
 part_price.price_e , 
 part_price.price_f , 
 part_price.qty_a , 
 part_price.qty_b , 
 part_price.qty_c, 
 part_price.qty_d, 
 part_price.qty_e, 
 part_price.qty_f,
part_price.curr_key,
part_price.curr_key,
inv_master.part_no,	
part_price.org_level,
part_price.loc_org_id,
''' + convert(varchar(10),@expirationD_cutoff_char) + ''',
part_price.org_level,
part_price.loc_org_id
 FROM inv_master (nolock), inv_list (nolock), locations l (nolock), region_vw r (nolock),
	part_price_vw part_price (nolock),
  adm_price_catalog c (nolock)
 WHERE ( isnull(inv_master.void,''N'') = ''N'' ) 			and 
	inv_master.part_no = inv_list.part_no and inv_list.location = l.location
  and l.organization_id = r.org_id and
		( inv_master.status != ''R'' ) and
		 inv_master.part_no = part_price.part_no and
     c.catalog_id = part_price.catalog_id and c.active_ind = 1 and c.type = 0 and part_price.active_ind = 1
    and part_price.org_level = 0'

exec (@sql + ' and ' + @range1) 		

select @range1 = replace(@range,'"','''')

select @sql = 'insert #rpt_invpricelist
SELECT distinct inv_master.part_no , 
 inv_master.description , 
 inv_master.category , 
 inv_master.type_code , 
 inv_master.status , 
 part_price.price_a , 
 part_price.price_b , 
 part_price.price_c , 
	 inv_master.void , 
	Case When ( ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + ' <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596  ) and
			part_price.promo_type = ''D''
		then ''Discount, %'' 
	 When ( ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596 ) and
			part_price.promo_type = ''P''
		then ''PRICE'' 
	 When ( ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + ' <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596 ) and
			part_price.promo_type = ''N''
		then null 
	 Else null
	End , 
	Case When ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596
		then part_price.promo_rate 
	 Else null
	End ,
	Case When ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596
		then part_price.promo_date_expires 
	 Else null
	End ,

 	Case When ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596
		then part_price.promo_date_entered 
	 Else null
	End , 
 inv_master.account , 
 part_price.price_d , 
 part_price.price_e , 
 part_price.price_f , 
 part_price.qty_a , 
 part_price.qty_b , 
 part_price.qty_c, 
 part_price.qty_d, 
 part_price.qty_e, 
 part_price.qty_f,
part_price.curr_key,
part_price.curr_key,
inv_master.part_no,	
part_price.org_level,
part_price.loc_org_id,
''' + convert(varchar(10),@expirationD_cutoff_char) + ''',
part_price.org_level,
part_price.loc_org_id
 FROM inv_master (nolock), 
	part_price_vw part_price (nolock),
  adm_price_catalog c (nolock),
   locations l (nolock), region_vw r (nolock)
 WHERE l.location = part_price.loc_org_id and 
   l.organization_id = r.org_id and
		( isnull(inv_master.void,''N'') = ''N'' ) 			and 
		( inv_master.status != ''R'' ) and
		 inv_master.part_no = part_price.part_no and
     c.catalog_id = part_price.catalog_id and c.active_ind = 1 and c.type = 0 and part_price.active_ind = 1
    and part_price.org_level = 2'

exec (@sql + ' and ' + @range1) 		

select @range1 = replace(@range1,'l.organization_id','part_price.loc_org_id')
select @range1 = replace(@range1,'"','''')

select @sql = 'insert #rpt_invpricelist
SELECT distinct inv_master.part_no , 
 inv_master.description , 
 inv_master.category , 
 inv_master.type_code , 
 inv_master.status , 
 part_price.price_a , 
 part_price.price_b , 
 part_price.price_c , 
	 inv_master.void , 
	Case When ( ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + ' <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596  ) and
			part_price.promo_type = ''D''
		then ''Discount, %'' 
	 When ( ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596 ) and
			part_price.promo_type = ''P''
		then ''PRICE'' 
	 When ( ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + ' <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596 ) and
			part_price.promo_type = ''N''
		then null 
	 Else null
	End , 
	Case When ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596
		then part_price.promo_rate 
	 Else null
	End ,
	Case When ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596
		then part_price.promo_date_expires 
	 Else null
	End ,

 	Case When ' + convert(varchar(10),isnull(@expirationD_cutoff_char,0)) + '  <= datediff(day,''01/01/1900'',part_price.promo_date_expires) + 693596
		then part_price.promo_date_entered 
	 Else null
	End , 
 inv_master.account , 
 part_price.price_d , 
 part_price.price_e , 
 part_price.price_f , 
 part_price.qty_a , 
 part_price.qty_b , 
 part_price.qty_c, 
 part_price.qty_d, 
 part_price.qty_e, 
 part_price.qty_f,
part_price.curr_key,
part_price.curr_key,
inv_master.part_no,	
part_price.org_level,
part_price.loc_org_id,
''' + convert(varchar(10),@expirationD_cutoff_char) + ''',
part_price.org_level,
part_price.loc_org_id
 FROM inv_master (nolock), 
	part_price_vw part_price (nolock),
  locations l (nolock),
  adm_price_catalog c (nolock),
   region_vw r (nolock)
 WHERE part_price.loc_org_id = r.org_id and
		( isnull(inv_master.void,''N'') = ''N'' ) 			and 
		( inv_master.status != ''R'' ) and
		 inv_master.part_no = part_price.part_no and
     c.catalog_id = part_price.catalog_id and c.active_ind = 1 and c.type = 0 and part_price.active_ind = 1
    and l.organization_id = part_price.loc_org_id
    and part_price.org_level = 1'

exec (@sql + ' and ' + @range1) 		

select r.*,
g.currency_mask,   g.curr_precision, g.rounding_factor, 
case when g.neg_num_format in (0,1,2,10,15) then 1 when g.neg_num_format in (6,7,9,14) then 2 
  when g.neg_num_format in (5,8,11,16) then 3 else 0 end,
case when g.neg_num_format in (2,3,6,9,10,13) then 1 when g.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,
g.symbol,
case when g.neg_num_format < 9 then '' when g.neg_num_format in (9,11,14,16) then 'b' else 'a' end,
'.',','
 from #rpt_invpricelist r
left outer join glcurr_vw g (nolock) on  r.curr_key = g.currency_code
order by group_1, group_2, group_3, group_4
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_invpricelist] TO [public]
GO

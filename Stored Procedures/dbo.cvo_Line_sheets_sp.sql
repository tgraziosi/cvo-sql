SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- exec cvo_line_sheets_sp 'op,bt,as'

CREATE procedure [dbo].[cvo_Line_sheets_sp] 
--@startdate datetime, 
--@enddate datetime,
@c varchar(1000) = null -- collection

as 

begin

set nocount on
 
-- for testing
 /*
declare
@startdate datetime, 
@enddate datetime,
@c varchar(1000) -- collection
set @startdate = '12/22/2014'
set @enddate = '12/31/2020'
set @c = null
 */


if(object_id('tempdb.dbo.#c') is not null)
drop table #c

CREATE TABLE #c (collection VARCHAR(10))

if @c is null
begin
 INSERT INTO #c (collection)
 SELECT distinct kys from category where void = 'n'
end
else
begin
 INSERT INTO #c (collection)
 SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@c)
end

-- load up not red POMs into table

if(object_id('tempdb.dbo.#pom') is not null)
drop table #pom

SELECT pts.id ,
       pts.asofdate ,
       pts.collection ,
       pts.style ,
       pts.color_desc ,
       pts.pom_date ,
       pts.qty_avl ,
       pts.in_stock ,
       pts.e12_wu ,
       pts.po_on_order ,
       pts.tl ,
       pts.Style_pom_status ,
       pts.Active ,
       pts.eff_date ,
       pts.obs_date 
INTO #pom
FROM dbo.cvo_pom_tl_status AS pts WHERE GETDATE() between eff_date AND obs_date

IF(object_id('tempdb.dbo.#line_sheet') is not null)
drop table #line_sheet

create table #line_sheet
(id int identity(1,1),
collection varchar(40),
style varchar(40),
eye_size float,
img_front varchar(255),
img_temple1 varchar(255),
img_temple2 varchar(255),
img_temple3 varchar(255),
img_temple4 varchar(255),
img_temple5 varchar(255),
img_temple6 varchar(255),
color_1 varchar(255),
color_2 varchar(255),
color_3 varchar(255),
color_4 varchar(255),
color_5 varchar(255),
color_6 varchar(255),
progressive_type varchar(255), -- progressive friendly
component_1 varchar(255), -- special comp 1
component_2 varchar(255), -- special comp 2
component_3 varchar(255), -- special comp 3
asterisk_1 varchar(255), -- asterisks 1
asterisk_2 varchar(255), -- asterisks 2
asterisk_3 varchar(255), -- asterisks 3
asterisk_4 varchar(255), -- asterisks 3
spare_temple_length varchar(255), -- spare temples lengths
temple_tip_material varchar(255) -- temple tip material
, source varchar(3) -- cmi or cvo
)

-- get styles in CMI within the release date range
-- 033115 - use RYG status instead for catalog list

insert into #line_sheet (collection, style, eye_size, source)
select distinct cmi.collection, model, eye_size
-- , dbo.f_cvo_get_pom_tl_status(cmi.collection, cmi.model,'', getdate())
,'cmi'
from cvo_cmi_catalog_view cmi
inner join #c c on c.collection = cmi.collection
-- where release_date between @startdate and @enddate
LEFT OUTER JOIN #pom ON #pom.collection = cmi.Collection AND #pom.style = cmi.model AND #pom.color_desc = cmi.ColorName
where 1=1
AND ISNULL(#pom.tl,'') NOT IN ('R')
-- and dbo.f_cvo_get_pom_tl_status(cmi.collection, cmi.model, cmi.ColorName, getdate()) NOT IN ('R')
and specialty_Fit not in ('retail','hvc')

-- get styles from Epicor DB

INSERT  INTO #line_sheet
        ( collection ,
          style ,
          eye_size ,
          source
        )
        SELECT DISTINCT
                i.category ,
                ia.field_2 ,
                ia.field_17 ,
                'cvo'
        FROM    inv_master i ( NOLOCK )
                INNER JOIN inv_master_add ia ( NOLOCK ) ON i.part_no = ia.part_no
                INNER JOIN #c c ON c.collection = i.category
				LEFT OUTER JOIN #pom ON #pom.collection = c.collection AND #pom.style = ia.field_2 AND #pom.color_desc = ia.field_3
        WHERE   i.void = 'n'
                AND i.type_code IN ( 'frame', 'sun' )
                AND ia.field_32 NOT IN ( 'retail', 'hvc' ) -- specialty fit
-- and ia.field_26 between @startdate and @enddate
                AND NOT EXISTS ( SELECT 1
                                 FROM   #line_sheet l
                                 WHERE  l.collection = i.category
                                        AND l.style = ia.field_2
                                        AND l.eye_size = ia.field_17
                                        AND l.source = 'cmi' )
				AND ISNULL(#pom.tl,'') NOT IN ('R')
                -- AND dbo.f_cvo_get_pom_tl_status(i.category, ia.field_2,ia.field_3, GETDATE()) NOT IN ('R' ) -- active and green
ORDER BY        i.category ,
                ia.field_2 ,
                ia.field_17;

-- select * From #line_sheet

-- drop table #temp
if(object_id('tempdb.dbo.#temp') is not null)
drop table #temp

create table #temp
(id int identity(1,1) ,
collection varchar(40),
style varchar(40),
-- eye_size float,
img_front varchar(255),
img_temple varchar(255),
prim_img varchar(1),
color varchar(255),
source varchar(3)
)

if(object_id('tempdb.dbo.#junk') is not null)
drop table #junk

create table #junk
(collection varchar(40),
style varchar(40),
-- eye_size float,
img_front varchar(255),
img_temple varchar(255),
prim_img varchar(1),
color varchar(255),
source varchar(3)
)

insert into #junk
select distinct cmi.collection, cmi.model, 
-- eye_size, 
case when isnull(cmi.img_34,'') <> '' then img_34 else '' /*isnull(cmi.img_front,'')*/ end, 
case when isnull(cmi.img_34,'') <> '' then img_34 else ''/*isnull(cmi.img_temple,'')*/ end, 
cmi.prim_img, isnull(cmi.colorname,'') colorname, 'cmi'
from cvo_cmi_catalog_view cmi 
inner join #line_sheet l on l.collection = cmi.collection and l.style = cmi.model
LEFT OUTER JOIN #pom ON #pom.collection = cmi.Collection AND #pom.style = cmi.model AND #pom.color_desc = cmi.ColorName
WHERE 1=1
-- AND dbo.f_cvo_get_pom_tl_status(cmi.collection, cmi.model,cmi.colorname, getdate()) NOT IN ('R')
AND ISNULL(#pom.tl,'') NOT IN ('R')

--inner join #c c on c.collection = cmi.collection
--where release_date between @startdate and @enddate

insert into #junk 
select distinct i.category , ia.field_2, 
-- ia.field_17, 
case when isnull(img_34,'') <> '' then img_34 else '' /*isnull(cia.img_front_hr,'')*/ end, 
case when isnull(img_34,'') <> '' then img_34 else '' /*isnull(CIA.img_temple_hr,'')*/ end, 
cia.prim_img, isnull(ia.field_3,''), 'cvo' 
from inv_master i (nolock) 
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
inner join #line_sheet l on l.collection = i.category and l.style = ia.field_2
-- inner join #c c on c.collection = i.category
left outer join cvo_inv_master_add cia (nolock) on i.part_no = cia.part_no
LEFT OUTER JOIN #pom ON #pom.collection = i.category AND #pom.style = ia.field_2 AND #pom.color_desc = ia.field_3
where i.void='n' and i.type_code in ('frame','sun')
-- and ia.field_26 between @startdate and @enddate
and not exists(select 1 from #junk l 
	where l.collection = i.category and l.style = ia.field_2 
	--and l.eye_size = ia.field_17 
	and l.source='cmi' and l.color = isnull(ia.field_3,l.color))
AND 1=1
-- and   dbo.f_cvo_get_pom_tl_status(i.category, ia.field_2, ia.field_3, getdate()) NOT IN ('R')
AND ISNULL(#pom.tl,'') NOT IN ('R')

-- select * from #temp

--insert into #temp
--select distinct * From #junk
--order by collection, style, color --, eye_size

insert into #temp
select collection, style, 
max(isnull(img_front,'')) img_front,
max(isnull(img_temple,'')) img_temple,
max(isnull(prim_img,0)) prim_img,
color,
source
from #junk
group by collection, style, color, source

/*
select * from #c
select * From #junk
select * from #TEMP
select collection, style, color_1, color_2, * from #LINE_SHEET
*/

if(object_id('tempdb.dbo.#junk') is not null) drop table #junk

-- end gathering data

declare @last_id int, @counter int, @style varchar(40), 
	@img_front varchar(255), @seq_no int, @eye_size float,
	@collection varchar(40), @img_temple varchar(255), 
	@color varchar(255), @feature varchar(255), @source varchar(3)
	, @color_count int

select  @last_id = min(id) from #temp 

select  @style = style, 
	    @collection = collection,
		@color = color,
        @img_temple = isnull(img_temple,''), 
        @img_front = case when prim_img = 1 then isnull(img_front,'') end
        from  #temp where id = @last_id
		-- and source = 'cvo'
select @counter = 1, @color_count = count(distinct color) from #temp where style=@style and collection=@collection

while @last_id is not null
begin -- go thru each color and mark color and image
	
	-- select @last_id, @counter, @color_count, @style, @collection

    while @counter <= @color_count 
    begin
	    if @counter = 1
         update l set l.img_temple1 = @img_temple, l.color_1 = @color 
        from #line_sheet l where l.collection = @collection and l.style = @style 
        if @counter = 2
         update l set l.img_temple2 = @img_temple, l.color_2 = @color 
        from #line_sheet l where l.collection = @collection and l.style = @style 
        if @counter = 3
         update l set l.img_temple3 = @img_temple, l.color_3 = @color 
        from #line_sheet l where l.collection = @collection and l.style = @style 
        if @counter = 4
         update l set l.img_temple4 = @img_temple, l.color_4 = @color 
        from #line_sheet l where l.collection = @collection and l.style = @style 
        if @counter = 5
         update l set l.img_temple5 = @img_temple, l.color_5 = @color
        from #line_sheet l where l.collection = @collection and l.style = @style 
        if @counter = 6
         update l set l.img_temple6 = @img_temple, l.color_6 = @color
         from #line_sheet l where l.collection = @collection and l.style = @style 
         
		if @counter < @color_count -- keep going with more colors
			begin
				select @counter = @counter + 1,
					@last_id = min(id) from #temp where id > @last_id and style = @style
				select  @style = style,
				@collection = collection,
				@color = color,
				@img_temple = img_temple, 
				@img_front = case when prim_img = 1 then img_front end
				from  #temp where id = @last_id
			end
		else 
		  break 
		
	  end -- style loop
		
	  select @last_id = min(id) from #temp where id > @last_id --and style <> @style
	  select  @style = style, 
			@collection = collection,
			@color = color,
			@img_temple = img_temple, 
			@img_front = case when prim_img = 1 then img_front end
			from  #temp where id = @last_id
			-- and source = 'cvo'
	  select @counter = 1, @color_count = count(distinct color) 
			from #temp where style=@style and collection=@collection
				
end -- collections loop
   
-- select collection, style, color_1, color_2, * from #LINE_SHEET   
-- select * From #line_sheet

-- get features and lay out horizontally

if (object_id('tempdb.dbo.#f') is not null) drop table #f
	create table #f
	( collection varchar(40),
	  style varchar(40),
	  seq_no int,
	  feature_desc varchar(255),
	  feature_group varchar(40)
	  )

 	 select @last_id = min(id)   from #line_sheet
	 select @style = style, @collection = collection, @eye_size = eye_size
		from #line_sheet where id = @last_id and source = 'cvo'
	
while @last_id is not null
begin

	truncate table #f
	set @counter = 0
	insert into #f select cf.collection, cf.style, cf.seq_no, 
		f.feature_desc, f.feature_group
     from cvo_inv_features cf inner join cvo_features f 
     on cf.feature_id = f.feature_id
     where cf.collection = @collection and cf.style = @style  
		and isnull(f.feature_desc,'') <> ''
     group by cf.collection, cf.style, cf.seq_no , f.feature_desc , f.feature_group

		-- do Special Components

    select @seq_no = min(seq_no) from #f where #f.collection = @collection and #f.style = @style
			and #f.feature_group = 'special components'
	select @counter = 1
	while @seq_no is not null and @counter <=3
	begin
		  update l set 
			l.component_1 = case when @counter = 1 and l.component_1 is null
			then #f.feature_desc else l.component_1 end,
			l.component_2 = case when @counter = 2 and l.component_2 is null
			then #f.feature_desc else l.component_2 end,
			l.component_3 = case when @counter = 3 and l.component_3 is null
			then #f.feature_desc else l.component_3 end
		  	from #f inner join #line_sheet l 
			on #f.collection = l.collection and #f.style = l.style
			where #f.seq_no = @seq_no
			
		 select @counter = @counter + 1
		 select @seq_no = min(seq_no) from #f where seq_no > @seq_no 
				and #f.collection = @collection and #f.style = @style
				and #f.feature_group = 'special components'
	end
	---- get asterisks
 --   select @seq_no = min(seq_no) from #f where #f.collection = @collection and #f.style = @style
	--		and #f.feature_group = 'asterisks'
	--select @counter = 1
	--while @seq_no is not null and @counter <=3
	--begin
	--	  update l set 
	--		l.asterisk_1 = case when @counter = 1 and l.asterisk_1 is null
	--		then #f.feature_desc else l.asterisk_1 end,
	--		l.asterisk_2 = case when @counter = 2 and l.asterisk_2 is null
	--		then #f.feature_desc else l.asterisk_2 end,
	--		l.asterisk_3 = case when @counter = 3 and l.asterisk_3 is null
	--		then #f.feature_desc else l.asterisk_3 end
	--	  	from #f inner join #line_sheet l 
	--		on #f.collection = l.collection and #f.style = l.style
	--		where #f.seq_no = @seq_no
	--		and #f.feature_group = 'asterisks'
			
	--	 select @counter = @counter + 1
	--	 select @seq_no = min(seq_no) from #f where seq_no > @seq_no 
	--			and #f.collection = @collection and #f.style = @style
	--			and #f.feature_group = 'asterisks'
	--end
		-- get asterisks
    select @seq_no = min(seq_no) from #f where #f.collection = @collection and #f.style = @style
			and #f.feature_group = 'asterisks'
	select @counter = 1
	while @seq_no is not null and @counter <=4
	begin
		  update l set 
			l.asterisk_1 = case when @counter = 1 and l.asterisk_1 is null
			then #f.feature_desc else l.asterisk_1 end,
			l.asterisk_2 = case when @counter = 2 and l.asterisk_2 is null
			then #f.feature_desc else l.asterisk_2 end,
			l.asterisk_3 = case when @counter = 3 and l.asterisk_3 IS null
			then #f.feature_desc else l.asterisk_3 END,
			l.asterisk_4 = case when @counter = 4 and l.asterisk_4 is null
			then #f.feature_desc else l.asterisk_4 END
			from #f inner join #line_sheet l 
			on #f.collection = l.collection and #f.style = l.style
			where #f.seq_no = @seq_no
			and #f.feature_group = 'asterisks'
			
		 select @counter = @counter + 1
		 select @seq_no = min(seq_no) from #f where seq_no > @seq_no 
				and #f.collection = @collection and #f.style = @style
				and #f.feature_group = 'asterisks'
	END
    
	-- get progressive type
	update l set l.progressive_type =  #f.feature_desc
		  	from #f inner join #line_sheet l 
			on #f.collection = l.collection and #f.style = l.style
			and #f.feature_group = 'progressive type'
	-- extra temple lengths
	update l set l.progressive_type =  #f.feature_desc
		  	from #f inner join #line_sheet l 
			on #f.collection = l.collection and #f.style = l.style
			and #f.feature_group = 'extra temple lengths'


	select  @last_id = min(id) from #line_sheet where id > @last_id
    select  @style = style, @collection = collection from #line_sheet where id = @last_id
	
end -- collection style

update l set l.img_front = t.img_front
        from #line_sheet l inner join #temp t on l.collection = t.collection and l.style = t.style
        where t.prim_img=1 and t.img_front <> ''
    
-- get pricing

	if(object_id('tempdb.dbo.#pp') is not null) drop table #pp

    ;with cte as 
-- details
(
select i.web_saleable_Flag, case when i.type_code ='parts' then '' else i.type_code end as type_code, ia.category_3 part_type, i.category, ia.field_2 style, i.part_no,
ia.field_28 pom_date,
case when i.type_code in ('frame','sun') then ia.field_13 else '' end as hinge_type, 
case when i.type_code in ('frame','sun','chassis') then pp.price_a else 0 end as frame_price,
case when ia.category_3 like 'temple%' then pp.price_a else 0 end as temple_price,
case when ia.category_3 like 'front' then pp.price_a else 0 end as front_price
From inv_master i inner join inv_master_add ia on i.part_no = ia.part_no
inner join part_price pp on pp.part_no = i.part_no
where 1=1
and i.type_code in ('frame','sun','parts')
and ia.category_3 in ('','temple-r','front','temple-l','chassis')
and i.void = 'n'
)
-- summary
select max(web_saleable_flag) ws_flag, max(type_code) type_code, cte.category, cte.style, cte.pom_date, max(hinge_type) hinge_type,max(frame_price) frame_price, max(temple_price) temple_price, max(front_price) front_price
into #pp
from cte
group by category, style, pom_date
order by category, type_code, style, pom_date   
    
    -- truncate table #line_sheet
    -- select * From #line_sheet

	-- select * from #pp where style = 'chantal'

-- final select 

select distinct -- get cmi stuff 
    ISNULL(i.variant_release_date,ISNULL(i.release_date,'')) release_date,
	case when isnull(i.print_flag,'') = '' then 'Unknown' ELSE i.print_flag end as  print_flag,
	i.web_saleable_flag,
	null as pom_date,
	'' as item_code,
	isnull(i.collection,'') collection,
	lower(c.description) as CollectionName,
	replace(lower(i.model),' ii',' II') as model, 
	isnull(l.img_front,'') img_front,
	isnull(l.img_temple1,'') img_temple1,
	isnull(l.img_temple2,'') img_temple2,
	isnull(l.img_temple3,'') img_temple3,
	isnull(l.img_temple4,'') img_temple4,
	isnull(l.img_temple5,'') img_temple5,
	isnull(l.img_temple6,'') img_temple6,
	case when isnull(i.specialty_fit,'') in ('Regular Fit','None') then ''
		 when isnull(i.specialty_fit,'') like '%Global%' then 'global_logo_cmyk.eps'
		 when isnull(i.specialty_fit,'') like '%Petite%' then 'PetiteFitlogo.eps'
		 when isnull(i.specialty_fit,'') like '%XL%' then 'XLFIT_cmyk_redgray.eps'
		 when isnull(i.specialty_fit,'') like '%style%' then 'stylenfit_k_nooutline.eps'
		 else isnull(i.specialty_fit,'') end as img_specialtyfit,
	future_releasedate = 
		case when isnull(i.variant_release_date,getdate()) > getdate() then
			case when (isnull(i.var_asterisk_1,'') like ('%new%size%') 
					or isnull(i.var_asterisk_2,'') like ('%new%size%') 
					or isnull(i.dim_asterisk_1,'') like ('%new%size%') 
					or isnull(i.dim_asterisk_2,'') like ('%new%size%') ) then
					'NewSizeAvailable'+datename(month,isnull(dateadd(m,1,i.variant_release_date),getdate()))+'.eps'
				 when  (isnull(i.var_asterisk_1,'') like ('%new%color%') 
					or  isnull(i.var_asterisk_2,'') like ('%new%color%') 
					or  isnull(i.dim_asterisk_1,'') like ('%new%color%') 
					or  isnull(i.dim_asterisk_2,'') like ('%new%color%') ) then
					'NewColorAvailable'+datename(month,isnull(dateadd(m,1,i.variant_release_date),getdate()))+'.eps'
				else
				'Available'+datename(month,isnull(dateadd(m,1,i.variant_release_date),getdate()))+'.eps'
				end
		else '' end,
	-- cast(i.release_date as varchar(12)) as future_releasedate,
	i.RES_type,
	i.PrimaryDemographic,
	i.target_age,
	i.eye_shape,
	lower(isnull(l.color_1,'')) color_a,
	lower(isnull(l.color_2,'')) color_b,
	lower(isnull(l.color_3,'')) color_c,
	lower(isnull(l.color_4,'')) color_d,
	lower(isnull(l.color_5,'')) color_e,
	lower(isnull(l.color_6,'')) color_f,

	cast(isnull(i.eye_size,0) as int) as eye_size,
	cast(isnull(i.a_size,0) as decimal(20,1)) as a_size,
	cast(isnull(i.b_size,0) as decimal(20,1)) as b_size,
	cast(isnull(i.ed_size,0) as decimal(20,1)) as ed_size,
	cast(isnull(i.dbl_size,0) as int) as dbl_size,
	cast(cast(isnull(i.temple_size,0) as int) as varchar(3))+'mm' as temple_size,
	-- no longer used -- 11/25/2014 cast(i.overall_temple_length as varchar(3))+'mm' as overall_temple_length,
	isnull(i.frame_category,'') frame_category,
	isnull(i.front_material,'') front_material,
	isnull(i.temple_material,'') temple_material,
	isnull(i.nose_pads,'') nose_pads,
	case when i.hinge_type = 'null' then '' else isnull(i.hinge_type,'') end as hinge_type,
	isnull(i.suns_only,'') suns_only,
	isnull(i.lens_base,'') lens_base,
	replace(isnull(i.specialty_fit,''),'Regular Fit','') specialty_fit,
	isnull((select top 1 description from gl_country c where c.country_code =  i.country_origin),'') as Country_of_Origin,
	isnull(i.case_part,'') case_part,
	isnull(i.frame_category,'') as rimless_style,
	isnull(i.Front_price,0.00) as Front_price,
	isnull(i.temple_price,0.00) as temple_price,
	isnull(i.wholesale_price,0.00) as  Frame_price,
	isnull(i.retail_price,0.00)  as sugg_retail_price,
	isnull(i.progressive_type,'') as progressive_type,
	isnull(i.component_1,'') as component_1,
	isnull(i.component_2,'') as component_2,
	isnull(i.component_3,'') as component_3,
	isnull(i.var_asterisk_1,'') as asterisk_1,
	isnull(i.var_asterisk_2,'') as asterisk_2,
	isnull(i.dim_asterisk_1,'') as asterisk_3,
	isnull(i.dim_asterisk_2,'') as asterisk_4,
	isnull(i.spare_temple_length,'') spare_temple_length,
	isnull(i.temple_tip_material,'') as temple_tip_material,
	PaginationKey = CASE WHEN i.Collection IN ('OP','IZOD','BT','SM') THEN 
						CASE WHEN i.PrimaryDemographic IN ('women','men')
						 THEN 'Adult'
						ELSE 'Kids' END
					ELSE i.RES_type end
	, l.source

from cvo_cmi_catalog_view i (nolock)
inner join #c on #c.collection = i.collection
inner join #line_sheet l on l.collection = i.collection and l.style = i.model and l.eye_size = i.eye_size
inner join category C (nolock) on c.kys = i.collection
and l.source = 'cmi'
-- and i.release_date between @startdate and @enddate


union all

select distinct  -- from Epicor Database
    isnull(ia.field_26,'') as release_date,
	'Unknown' as print_flag,
	--i.upc_code,
	i.web_saleable_flag,
	ia.field_28 pom_date,
	--i.part_no, 
	isnull(cia.item_code,'') item_code, 
	i.category Collection,
	lower(isnull(c.description,'')) as CollectionName,  -- EL added 10/14/2013
	replace(lower(ia.field_2),' ii',' II') as model, 
	isnull(ltrim(rtrim(l.img_front)),'') img_front,
	isnull(ltrim(rtrim(l.img_temple1)),'') img_temple1,
	isnull(ltrim(rtrim(l.img_temple2)),'') img_temple2,
	isnull(ltrim(rtrim(l.img_temple3)),'') img_temple3,
	isnull(ltrim(rtrim(l.img_temple4)),'') img_temple4,
	isnull(ltrim(rtrim(l.img_temple5)),'') img_temple5,
	isnull(ltrim(rtrim(l.img_temple6)),'') img_temple6,
	case when isnull(ia.field_32,'') in ('Regular Fit','None') then ''
		 when isnull(ia.field_32,'') like '%Global%' then 'global_logo_cmyk.eps'
		 when isnull(ia.field_32,'') like '%Petite%' then 'PetiteFitlogo.eps'
		 when isnull(ia.field_32,'') like '%XL%' then 'XLFIT_cmyk_redgray.eps'
		 when isnull(ia.field_32,'') like '%stylen%' then 'stylenfit_k_nooutline.eps'
		 else isnull(ia.field_32,'') end as img_specialtyfit,
	-- isnull(ltrim(rtrim(cia.img_specialtyFit)),'') img_specialtyfit,
	future_releasedate = 
		case when ia.field_26 > getdate() then
		'Available'+datename(month,ia.field_26)+'.eps'
		else '' end,
	-- isnull(ltrim(rtrim(cia.future_releasedate)),'') future_releasedate,
	-- cia.prim_img,  removed 040814
	i.type_code as RES_type,
	--lower(CASE when ia.category_2 = 'unknown' then '' 
	-- when ia.category_2 = 'Male-Child' and i.category in ('izod','izx') then '(boys)'
	-- when ia.category_2 = 'Female-Child' and i.category in ('jmc') then '(girls)'
	-- when ia.category_2 like '%child%' and i.category in ('op') then '(kids)'
	-- else isnull(ia.category_2,'') end) as PrimaryDemographic,
	lower((SELECT TOP (1) description from cvo_gender where kys = ia.category_2)) PrimaryDemographic,
	lower(case when ia.category_4 = 'UNKNOWN' THEN '' ELSE isnull(ia.category_4,'') END) as target_age,
	lower(case when cia.eye_shape = 'unknown' then '' else isnull(cia.eye_shape,'') end) as eye_shape,
	lower(isnull(l.color_1,'')) color_a,
	lower(isnull(l.color_2,'')) color_b,
	lower(isnull(l.color_3,'')) color_c,
	lower(isnull(l.color_4,'')) color_d,
	lower(isnull(l.color_5,'')) color_e,
	lower(isnull(l.color_6,'')) color_f,
	cast(isnull(l.eye_size,0) as int) as eye_size,
	cast(isnull(ia.field_19,0) as decimal(20,1)) as a_size,
	cast(isnull(ia.field_20,0) as decimal(20,1)) as b_size,
	cast(isnull(ia.field_21,0) as decimal(20,1)) as ed_size,
	-- cast(isnull(cia.dbl_size,0) as int) as dbl_size,
	cast(isnull(ia.field_6,0) as int) as dbl_size,
	cast(isnull(ia.field_8,0) as varchar(3))+'mm' as temple_size,
	-- lower(case when ia.field_9 = 'unknown' then '' else cast(isnull(ia.field_9,'') as varchar(3))+'mm' end) as overall_temple_length,
	lower(case when ia.field_11 = 'unknown' then '' 
		  else isnull((SELECT TOP 1 description from cvo_frame_type where kys = ia.field_11),'') end) as frame_category,
	lower(case when ia.field_10 = 'unknown' then '' 
		else isnull((select TOP 1 description from cvo_frame_matl where kys = ia.field_10),'') end) as front_material,
	lower(case when ia.field_12 = 'unknown' then '' 
		else isnull((select TOP 1 description from cvo_temple_matl where kys = ia.field_12),'') end) as temple_material,
	lower(case when ia.field_7 = 'unknown' then '' 
		else isnull((select TOP 1 description from cvo_nose_pad where kys = ia.field_7),'') end) as nose_pads,
	lower(case when ia.field_13 = 'unknown' then '' 
		else isnull((select TOP 1 description from cvo_temple_hindge where kys = ia.field_13),'') end)  as hinge_type,
	lower(case when ia.field_24 = 'unknown' then '' 
		else isnull((SELECT TOP (1) description from cvo_sun_lens_material where kys = ia.field_24),'') end) as suns_only,
	lower(case when ia.field_25 = 'unknown' then '' 
		else isnull((SELECT TOP(1) description from cvo_sun_lens_type where kys = ia.field_25),'') end) as lens_base,
	lower(isnull((SELECT TOP(1) description from cvo_specialty_Fit where kys = isnull(ia.field_32,'')),'')) as specialty_fit,
	isnull((SELECT TOP (1) description from gl_country c where c.country_code =  i.country_code),'') as Country_of_Origin,
	case when isnull((select top 1 cast(long_descr as varchar(60)) from inv_master_add where part_no = ia.field_1),'') <> '' then (select top 1 cast(long_descr as varchar(60)) from inv_master_add where part_no = ia.field_1)
	else lower(isnull((select top 1 description from inv_master where part_no = ia.field_1),''))end as case_part,
	lower(case when ia.field_11 = 'unknown' then '' 
		else isnull((select TOP (1) description from cvo_frame_type where kys = ia.field_11),'') end) as rimless_style,
	round(isnull(#pp.front_price,0),2) Front_price,
	round(isnull(#pp.temple_price,0),2) temple_price,
	round(isnull(#pp.frame_price,0),2) as Frame_price,
	isnull(cia.sugg_retail_price,0) sugg_retail_price,
	isnull(l.progressive_type,'') progressive_type,
	isnull(l.component_1,'') component_1,
	isnull(l.component_2,'') component_2,
	isnull(l.component_3,'') component_3,
	isnull(l.asterisk_1,'') asterisk_1,
	isnull(l.asterisk_2,'') asterisk_2,
	isnull(l.asterisk_3,'') asterisk_3,
	isnull(l.asterisk_4,'') asterisk_4,
	isnull(l.spare_temple_length,'') spare_temple_length,
	isnull(l.temple_tip_material,'') temple_tip_material,
	PaginationKey = CASE WHEN i.category IN ('OP','IZOD','BT','SM') THEN 
						CASE WHEN (SELECT TOP (1) description from cvo_gender where kys = ia.category_2) IN ('women','men')
						 THEN 'Adult'
						ELSE 'Kids' END
					ELSE i.type_code end
	, l.source

-- into #final
from inv_master i (nolock)
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
inner join #line_sheet l on l.collection = i.category and l.style = ia.field_2 and l.eye_size = ia.field_17
-- inner join #c on #c.collection = i.category
left outer join cvo_inv_master_add cia (nolock) on i.part_no = cia.part_no
left outer join #pp (nolock) on #pp.category = i.category and #pp.style = ia.field_2
left outer join category C (nolock) on c.kys = i.category
where i.void='n' and i.type_code in ('frame','sun')
-- and ia.field_26 between @startdate and @enddate
-- order by lower(c.description), i.type_code, replace(lower(ia.field_2),' ii',' II')
and l.source = 'cvo'

   
END






GO

GRANT EXECUTE ON  [dbo].[cvo_Line_sheets_sp] TO [public]
GO

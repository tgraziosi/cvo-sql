SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- November 2014 - update mfg and category1 and 2
-- =============================================
-- Author:		tgraziosi
-- Create date: 11/10/2014
-- Description:	Handshake Inventory Data #8
-- exec hs_inventory8_sp
-- SELECT * FROM dbo.cvo_hs_inventory_8 where shelfqty = 2000  where MASTERSKU like 'IZ600%'
-- DROP TABLE dbo.cvo_hs_inventory_8
-- 		
-- 072814 - tag - 1) add special values, 2) performance updates
-- 082214 - add obsolete date for spv list
-- 12/15/2014 - change category to be one per mastersku.  mark disco'd sku's
-- 3/2/2015 -- change apr list to look at table instead of inv_master_add
-- 5/8/2015 - hide obsolete POP
-- 6/27/2015 - tweaks for bts program 
-- 8/26/2015 - tweaks for CH SellDown - put on their own category:1, and inventory qty > 10
-- add sun lens color for REVO
-- 100715 -- change revo mastersku from 8 characters to 6
-- 122315 - add support  for Red Raven - as of 12/29
-- 041416 - VEE support
-- 052616 - show CH inventory again
-- 6/9/2016 for kit items to fake inventory # later. show real inventory for REVO
--
-- =============================================

CREATE PROCEDURE [dbo].[HS_Inventory8_sp] 
AS
BEGIN

	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

-- EXPORT FOR HANDSHAKE

declare @today datetime, @location varchar(10), @CH DATETIME
set @today = dateadd(dd, datediff(dd,0,getdate()), 0)
set @location = '001'
SET @CH = '9/1/2015' -- START OF CH SELL-DOWN PERIOD


IF(OBJECT_ID('tempdb.dbo.#EOS') is not null)  drop table #EOS
CREATE TABLE #EOS
(
Col int,
Prog varchar (3),
Brand	varchar(4),
Style	varchar(60),
part_no	varchar(30),
pom_date	datetime,
Gender	varchar(30),
Avail	decimal(10,2),
ReserveQty	decimal(10,2),
TrueAvail_2 decimal(10,2),
TrueAvail varchar(20),
)
INSERT INTO #EOS EXEC CVO_EOS_SP
-- 8/26/2015
DELETE FROM #eos WHERE brand = 'ch' AND @today >= @CH
-- SELECT * FROM #EOS where part_no like 'izCL%'  


-- make a list of Costco sku's from history
IF(OBJECT_ID('tempdb.dbo.#cc') is not null)  
drop table #cc

select i.part_no 
into #cc
from inv_master i 
where exists (select 1 from cvo_sbm_details sbm (nolock) where i.part_no = sbm.part_no and sbm.customer='045217')

-- select * from #cc


IF(OBJECT_ID('tempdb.dbo.#Data1') is not null) drop table #Data1
select i.part_no as sku, 

--convert(varchar(150),
--case when type_code in ('sun','frame') and len(t1.part_no)=11 then left(t1.part_no,4)
--	when type_code in ('sun','frame') and len(t1.part_no)=14 then left(t1.part_no,7)
--	when type_code in ('sun','frame') and len(t1.part_no)=13 then left(t1.part_no,6)
--	when type_code in ('sun','frame') and len(t1.part_no)=12 then left(t1.part_no,5) else '' END 
--	) as mastersku,

convert(varchar(150),
		CASE WHEN i.category = 'revo' THEN RTRIM(LEFT(i.part_no,6))
			 WHEN i.type_code in ('sun','frame') then left(i.part_no, LEN(i.PART_NO)-7)
		else '' END 
	   ) as mastersku,

CASE WHEN i.category ='revo' AND i.type_code IN ('other','pop') THEN CONVERT(VARCHAR(150), i.description) 
	ELSE CONVERT(varchar(150),(CAT.Description + ' ' + FIELD_2)) END AS name, 

convert(decimal(10,2),price_a) as unitPrice, 
1 as minQty, 
1 as multQty,  
CASE WHEN i.TYPE_CODE IN ('other','POP') THEN 'POP' ELSE 'CLEARVISION'  end as manufacturer,
upc_code as barcode, 

CASE WHEN i.category ='revo' AND i.type_code IN ('other','pop') THEN CONVERT(VARCHAR(150), i.description) 
	ELSE CONVERT(varchar(150),(CAT.Description + ' ' + FIELD_2)) END AS longDesc, 

variantdescription = case when i.type_code in ('other','pop') then i.description 
		WHEN i.type_code = 'sun' THEN
			convert(varchar(150),(CAT.Description + ' ' + FIELD_2 + ' ' + FIELD_3 + ' ' 
			+ (ISNULL(CAST(str(FIELD_17, 2, 0) AS VARCHAR(2)),'') 
			+ '/' + ISNULL(CAST(field_6 AS VARCHAR(2)),'') 
			+ '/' + ISNULL(CAST(field_8 AS VARCHAR(3)),'') ) 
			+ ' ' + ISNULL(field_23,'') -- sun lens color - 1/11/16
			)) 
		else
		convert(varchar(150),(CAT.Description + ' ' + FIELD_2 + ' ' + FIELD_3 + ' ' 
		+ (ISNULL(CAST(str(FIELD_17, 2, 0) AS VARCHAR(2)),'') + '/' + ISNULL(CAST(field_6 AS VARCHAR(2)),'') 
		+ '/' + ISNULL(CAST(field_8 AS VARCHAR(3)),'') ) )) 
		end,
 '' as imageURLs, 
[category:1] = CASE 
	 WHEN I.part_no = 'OPZSUNSKIT' THEN 'SUN'
	 WHEN i.TYPE_CODE IN ('OTHER','POP') THEN 'POP'
	 -- 1/11/2016
	 -- WHEN i.category = 'CH' AND ia.FIELD_32 = 'LastChance' THEN 'CHLastChance'
	 WHEN i.category = 'CH' AND @TODAY >= @CH THEN 'COLE HAAN' -- 05/26 - CHANGE FROM CH RETURNS TO COLE HAAN FOR LAST, LAST, CHANCE BUYS
	 WHEN ISNULL(FIELD_28,@TODAY) >= @today THEN I.TYPE_CODE
	 WHEN EXISTS (SELECT 1 FROM #EOS WHERE #EOS.PART_NO = I.PART_NO) THEN 'SUN SPECIALS'
	 -- 12/12/14 - sunps takes precedence
	 WHEN i.TYPE_CODE = 'SUN' AND ISNULL(FIELD_28,@TODAY) < @today and isnull(field_36,'') <> 'sunps' THEN 'EORS'
	 WHEN dbo.f_cvo_get_part_tl_status (I.part_no,@today) = 'R'
		  and datediff(m,isnull(field_28,@today),@today) < 9  THEN 'RED'
	 WHEN datediff(m,isnull(field_28,@today),@today) >= 24  THEN 'EOR' 
	 WHEN datediff(m,isnull(field_28,@today),@today) >= 9 THEN 'QOP'

	 ELSE I.TYPE_CODE END,
[CATEGORY:2] = case when i.category in ('izod','izx') then 'IZOD' 
					-- WHEN ia.field_32 = 'lastchance' THEN '' 
ELSE CAT.DESCRIPTION END,
ISNULL(FIELD_3,'') AS Color,
-- sun lens color for REVO
CASE WHEN i.type_code = 'sun' AND i.category = 'revo' THEN REPLACE(ISNULL(field_23,'NoLens'),' ','') ELSE -- use lens color as dimension for revo
(ISNULL(CAST(str(FIELD_17, 2, 0) AS VARCHAR(2)),'') + '/' + ISNULL(CAST(field_6 AS VARCHAR(2)),'') + '/' + ISNULL(CAST(field_8 AS VARCHAR(3)),'') ) END 
AS Size,
'|' as [|],
I.CATEGORY AS COLL, IA.field_2 as Model, 
field_28 as POMDate,
field_26 as ReleaseDate,
dbo.f_cvo_get_part_tl_status (I.part_no,@today)  as Status,
-- 6/26/2015 tweak for BTS 2015
CASE WHEN CATEGORY_2 LIKE '%CHILD%' AND i.category <> 'dd' /*AND FIELD_2 NOT IN ('843','844')*/  THEN 'KIDS' 
	 /*WHEN category_2 NOT LIKE '%child%' AND i.category IN('jc','op') THEN 'Tween'*/
	 ELSE '' END GENDER, 
case when field_32 = 'none' /*OR ia.field_2 IN ('gelato','popsicle','sherbet')*/ then '' else isnull(FIELD_32,'') end as SpecialtyFit,
case when (#apr.sku is not null) then 'Y' else ''  end as APR,
CASE WHEN i.category = 'ch' THEN ''
	 WHEN  FIELD_26 > DATEADD(MONTH,-6,@today) THEN 'New' 
	 ELSE '' END AS New,
case WHEN FIELD_36='SUNPS' THEN 'SUNPS' ELSE '' END as SUNPS,
case when #cc.part_no is null then '' else 'CC' end as CostCo,
case when isnull(field_28,@today) < @today then 'POM' else '' end as POM,
-- 6/9/2016 for kit items to fake inventory # later
CASE WHEN ISNULL(field_30,'') ='Y' THEN 'Kit' ELSE '' END AS Kit,
shelfqty = 0,
ISNULL(invupd.shelfqty,'999') ShelfQty2,
cia.nextpoduedate
, cia.NextPOOnOrder
, isnull(drp.e12_wu,0) drp_usg
, isnull(cia.qty_avl,0) qty_avl
, New_shelfqty = case when isnull(cia.qty_avl,0) <= isnull(drp.e12_wu,0) then 0 else isnull(cia.qty_avl,0) end

INTO #Data1
FROM inv_master (NOLOCK) I
JOIN inv_master_add (NOLOCK) IA on IA.part_no=I.part_no
JOIN CATEGORY (NOLOCK) CAT ON I.category=CAT.kys
JOIN part_price (NOLOCK) PP on I.part_no=PP.part_no
-- left outer join #eos on #eos.part_no = t1.part_no
left outer join CVO_ITEM_AVAIL_VW  (nolock) cia on cia.location=@location AND cia.part_no = i.part_no 
left outer join CVO_HS_INVENTORY_QTYUPD invupd (nolock) on i.part_no=invupd.sku
left outer join #cc on #cc.part_no = I.part_no
-- 030215 -- get apr info from table
left outer join cvo_apr_tbl #apr on #apr.sku = i.part_no 
					 and @today between #apr.eff_date and #apr.obs_date -- 3/2/2015 tag
-- 032615 use drp 4 week usage as safety stock
left outer join dpr_report drp (nolock) on drp.part_no = i.part_no and drp.location = @location

WHERE i.VOID <> 'V' AND category not in ('CORP','FP','BT')
  AND (ISNULL(FIELD_32,'') NOT IN ('HVC','RETAIL','COSTCO','SpecialOrd') -- 5/12/16 -- added special order for revo custom
  -- 4/26/2016 don't need anymore
--      OR (category IN ('RR') AND ia.field_2 NOT IN ('Rutgers','Vanderbilt','Wildcat Peak') AND GETDATE() >='12/29/2015')
--	  ) 
--  4/26/2016 oh yes we do need this
      OR (category IN ('RR') AND GETDATE() >='12/29/2015')
	  ) 
  
  AND (i.TYPE_CODE IN ('SUN','FRAME') OR isnull(field_36,'') = 'HSPOP')
  -- 6/29/2015 - set to 1 day.  was 11.  have no idea why
  AND (field_26 <= DATEADD(D,1,@today) OR  #apr.sku is not null OR (field_26 = '4/26/2016' AND category <> 'AS')) -- vee 2016
  
-- select * From #data1 where sku = 'bcviabla5515'


create index idx_data1 on #data1 ( sku )

CREATE NONCLUSTERED INDEX [idx_new_mastersku]
ON [dbo].[#Data1] ([New]) INCLUDE ([mastersku])


UPDATE  #Data1 SET NAME='IZOD CLEAR DISPLAY FRAME KIT'
		, LongDesc='IZOD CLEAR DISPLAY FRAME KIT'
		, [CATEGORY:1]= 'FRAME', MANUFACTURER= 'CLEARVISION' 
	    WHERE sku = 'IZCLDISKITA'


-- 06/26/2015
UPDATE  #Data1 SET [CATEGORY:1]= 'FRAME', MANUFACTURER= 'CLEARVISION' 
		, longdesc = variantdescription, name = variantdescription, size = ''--, model = 'READER'
	    WHERE sku in ('ETREADER','izztr90kit','bczdisplaykit','izodinter')

UPDATE  #Data1 SET longDesc = REPLACE (longDesc,'PERFORMX ','IZOD PERFORMX ') 
			, name = REPLACE (name,'PERFORMX ','IZOD PERFORMX ') 
			, VariantDescription = REPLACE (VariantDescription,'PERFORMX ','IZOD PERFORMX ') 
-- 1/2/2015 - tag - for durahinge
update  #data1 set longdesc = replace (longdesc, 'durahinge durahinge','DURAHINGE')
			, name = replace (name, 'durahinge durahinge','DURAHINGE')
			, variantdescription = replace (variantdescription, 'durahinge durahinge','DURAHINGE')

UPDATE  #Data1 SET longDesc = REPLACE (longDesc,'"','') 
			, name = REPLACE (name,'"','') 
			, VariantDescription = REPLACE (VariantDescription,'"','') 
    
-- PULL ALL SPECS for STYLE together
  IF(OBJECT_ID('tempdb.dbo.#Spec') is not null) drop table #Spec
  select distinct Mastersku, Num, Spec into #Spec from (
  select mastersku, 1 as Num, Gender as Spec from #Data1 where Gender <> ''
  UNION ALL
  select mastersku, 2 as Num, SpecialtyFit from #Data1 where SpecialtyFit <> ''
  UNION ALL
  select mastersku, 3 as Num, case when APR ='Y' then 'APR' else '' end from #Data1 where APR <> '' and sunps <>'sunps'
  UNION ALL
  select mastersku, 4 as Num, New from #Data1 where New <> ''
  union all -- 072814 - add special values list
  select distinct #data1.mastersku, 5 as num, 'SPV' 
		from #data1 join cvo_spv_tbl on #data1.sku = cvo_spv_tbl.sku 
		where @today between cvo_spv_tbl.eff_date and isnull(cvo_spv_tbl.obs_date,@today)
		and cvo_spv_tbl.mastersku is not null
		-- 02/27/2015 - if it's already qop it can't be a spv too
		and [category:1] <> 'QOP'

  UNION ALL
  select mastersku, 5 as Num, SunPs from #Data1 where SunPS <> ''
  --UNION ALL
  --SELECT mastersku, 6 AS num, '1.1' FROM #data1 WHERE ReleaseDate = '11/2/2015' AND COLL = 'AS'
  --UNION ALL
  --select mastersku, 6 as Num, '*D*' from #Data1 where POM <> ''
  )tmp

-- --   select * from #Spec
IF(OBJECT_ID('tempdb.dbo.#Spec1') is not null)
drop table dbo.#Spec1
      ;WITH C AS 
            ( SELECT mastersku, Num, Spec FROM #Spec )
            select Distinct mastersku,
             STUFF ( ( SELECT ' ' + Spec
             FROM #Spec WHERE mastersku = C.mastersku
             FOR XML PATH ('') ), 1, 1, ''  ) AS NEW
      INTO #Spec1 FROM C

create index idx_spec on #spec ( mastersku )
create index idx_spec1 on #spec1 ( mastersku )

-- -- 
delete from #SPEC where mastersku=''
--  select * from #Spec1 where mastersku=''
delete from #SPEC1 where mastersku=''      
    
-- UPDATES
update #Data1 set mastersku = 'BCGLIL' where sku like 'bcglil%' 
update #Data1 set mastersku = 'BCANGS' where sku like 'bcANG_______S' 

--2/25/2016
UPDATE #data1 SET mastersku = mastersku+'X' WHERE mastersku IN ('RE4064','RE4066') AND POMDate <= '1/1/2010'

UPDATE  #Data1 SET NAME='OCEAN PACIFIC SUNS KIT'
		, LongDesc='OCEAN PACIFIC SUNS KIT'
		, [CATEGORY:1]= 'SUN', MANUFACTURER= 'CLEARVISION' 
	    WHERE sku = 'OPZSUNSKIT'
-- select * from #Data1

IF(OBJECT_ID('#Final') is not null)    drop table #Final

select sku, 
case when manufacturer ='POP' then ''  
	 else mastersku end as mastersku,  
--ISNULL((select name + ' (' + New + case when pomdate is not null then ' *D)' else ' )' end from #Spec1 t2 
--	 where t1.mastersku=t2.mastersku),name)  AS name, 
ISNULL((select name + ' (' + New + ')' from #Spec1 t2 where t1.mastersku=t2.mastersku),name)  AS name, 
unitPrice, minQty, multQty, 
Manufacturer,  
barcode, 
--ISNULL((select longDesc + ' (' + New + case when pomdate is not null then ' *D)' else ' )' end  from #Spec1 t2 
--	where t1.mastersku=t2.mastersku),longDesc) AS  longDesc,
ISNULL((select longdesc + ' (' + New + ')'  from #Spec1 t2 where t1.mastersku=t2.mastersku),longdesc)  AS longdesc
, VariantDescription = isnull((select variantdescription + ' (*D)' 
		  from inv_master_add ia where ia.part_no = t1.sku 
			and isnull(ia.field_28,getdate()) < getdate()),VariantDescription) 
		  
, imageURLs,
--  updated to add EOS to category:1  EL 062514
[category:1], 
[category:2], 
Color,
-- Lens_color,
Size, 
[|], 
COLL, Model, POMDate, ReleaseDate, Status, GENDER, SpecialtyFit, APR, New, SUNPS, CostCo
-- , ShelfQty
, ShelfQty = 
-- 2/4/16 - add izod interchangeable fudge qty for 2/23 release
	CASE WHEN t1.coll = 'izod' AND t1.Model IN ('6001','6002','6003','6004') THEN t1.qty_avl + ISNULL(t1.NextPOOnOrder, 0)
		 -- 5/26/16 - SHOW ch QTYS FOR LAST, LAST CHANCE BUYS -- WHEN T1.coll = 'CH' then 0
		 WHEN SKU = 'IZODINTER' THEN 2000 -- ISNULL(T1.QTY_AVL,0) + ISNULL(t1.NextPOOnOrder,0)
		 WHEN Kit = 'Kit' THEN 2000 -- 6/9/2016 - dummy up inventory for all promo kits
		 WHEN t1.apr = 'y' or t1.sunps = 'sunps' /*OR t1.[CATEGORY:2] = 'revo'*/ THEN 2000 -- APR and sunps and revo
		 when t1.[category:1] in ('spv','qop','eor') then isnull(t1.qty_avl,0)
		 
	ELSE case when t1.qty_avl < t1.drp_usg then 0 else isnull(t1.qty_avl,0) end
	END
, NextPODueDate
, 0 as hide

INTO #Final
 from #Data1 t1
 Order by coll, model
 
update #final set Hide = 
			   case when manufacturer = 'POP' then
				 case when isnull(pomdate,@today) < @today then 1 else 0 end
			   WHEN ShelfQty <= 0 and [category:1] in ('EOR','EORS') THEN 1
			   else 0 END

update #final set Hide = case when COLL = 'revo' AND isnull(pomdate,@today) = '01/01/2010' then 1
							  WHEN coll = 'revo' AND model IN ('Straightshot','Bearing','Heading') THEN 1 -- 2/10/2016
							  -- unhide for 4/26 release WHEN mastersku IN ('iz2014','iz2015','iz2016','iz2017') THEN 1
							  WHEN MASTERSKU IN ('IZ6001','IZ6002','IZ6003','IZ6004') AND @today < '5/16/2016' THEN 1
							  WHEN mastersku IN ('iz2026','iz2027') THEN 1 -- new iz t&C kit
							   else 0 end

-- SELECT * FROM dbo.cvo_hs_inventory_8 AS chi WHERE chi.mastersku LIKE 'iz600%'
			   
-- 8/21/2015 - hide these until JB says to release

--UPDATE #final SET Hide = 1
--	WHERE ReleaseDate BETWEEN '8/25/2015' AND '8/27/2015' 
--	AND coll IN ('bcbg','izod','et')
--	-- - 10/20/2015 -  AND Model IN ('audra','gloria','harper','marlowe','2008','2009','hopeful','loved','survivor','thrive')
--	AND Model IN ('audra','gloria','harper','marlowe','2008','2009')


DELETE FROM #final 
	WHERE RIGHT(sku,2) = 'F1' AND [CATEGORY:2] = 'revo'



-- DELETE FROM #final WHERE [category:2] = 'revo' AND Model NOT IN ('windspeed','huddie')

--IF(OBJECT_ID('tempdb.dbo.#FINAL2') is not null) drop table dbo.#FINAL2
--select * CAST((case when manufacturer = 'POP' THEN 0
--	WHEN ShelfQty <=0 and [category:1] in ('EOR','EORS') THEN 1
--	ELSE 0 END) as INT) HIDE
--INTO #FINAL2 FROM #FINAL  t1

--   select * from #final2 where 
-- FINAL

IF(OBJECT_ID('dbo.cvo_hs_inventory_8') is not null)
	BEGIN    
		TRUNCATE table cvo_hs_inventory_8
	END
    ELSE
    BEGIN
		CREATE TABLE [dbo].[cvo_hs_inventory_8](
			[sku] [varchar](30) NOT NULL,
			[mastersku] [varchar](150) NULL,
		[name] [nvarchar](max) NULL,
		[unitPrice] [decimal](10, 2) NULL,
		[minQty] [int] NOT NULL,
		[multQty] [int] NOT NULL,
		[Manufacturer] [varchar](11) NOT NULL,
		[barcode] [varchar](20) NULL,
		[longdesc] [nvarchar](max) NULL,
		[VariantDescription] [varchar](260) NULL,
		[imageURLs] [varchar](1) NOT NULL,
		[category:1] [varchar](12) NULL,
		[category:2] [varchar](40) NULL,
		[Color] [varchar](40) NOT NULL,
		--[Lens_color] VARCHAR(40) NOT NULL,
		[Size] [varchar](9) NOT NULL,
		[|] [varchar](1) NOT NULL,
		[COLL] [varchar](10) NULL,
		[Model] [varchar](40) NULL,
		[POMDate] [datetime] NULL,
		[ReleaseDate] [datetime] NULL,
		[Status] [varchar](1) NULL,
		[GENDER] [varchar](5) NOT NULL,
		[SpecialtyFit] [varchar](40) NOT NULL,
		[APR] [varchar](1) NOT NULL,
		[New] [varchar](3) NOT NULL,
		[SUNPS] [varchar](5) NOT NULL,
		[CostCo] [varchar](2) NOT NULL,
		[ShelfQty] [decimal](38, 8) NOT NULL,
		[NextPODueDate] [datetime] NULL,
		[hide] [int] NOT NULL,
		[MasterHIDE] [int] NOT NULL
		) ON [PRIMARY] 
		
		CREATE index idx_inv7 on cvo_hs_inventory_8 ( manufacturer, mastersku, sku )

		CREATE NONCLUSTERED INDEX [idx_hs_inv_part_no] ON [dbo].[cvo_hs_inventory_8]
		([sku] ASC)
		INCLUDE ([mastersku]) 
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, 
		DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


end

INSERT into dbo.cvo_hs_inventory_8 
select t1.sku ,
       t1.mastersku ,
       t1.name ,
       t1.unitPrice ,
       t1.minQty ,
       t1.multQty ,
       t1.manufacturer ,
       t1.barcode ,
       t1.longdesc ,
       t1.VariantDescription ,
       t1.imageURLs ,
       t1.[category:1] ,
       t1.[CATEGORY:2] ,
       t1.Color ,
	   -- t1.lens_color,
       t1.Size ,
       t1.[|] ,
       t1.COLL ,
       t1.Model ,
       t1.POMDate ,
       t1.ReleaseDate ,
       t1.Status ,
       t1.GENDER ,
       t1.SpecialtyFit ,
       t1.APR ,
       t1.New ,
       t1.SUNPS ,
       t1.CostCo ,
       t1.ShelfQty ,
       t1.NextPODueDate ,
       t1.hide, 
case when (select count(*) from #FINAL t2 where t1.mastersku=t2.mastersku) 
		= (select sum(HIDE) from #FINAL t2 where t1.mastersku=t2.mastersku group by mastersku) 
		THEN 1 else 0 END AS MasterHIDE

from #FINAL t1



DELETE FROM cvo_hs_inventory_8 
	where sku like 'izc%TEMPKIT'
UPDATE cvo_hs_inventory_8 set MASTERSKU='MESHE' 
	where mastersku='MESHEB'
UPDATE cvo_hs_inventory_8 set SIZE='' 
	WHERE MANUFACTURER ='pop' or SKU = 'IZCLDISKITA' 

update cvo_hs_inventory_8 set sku = upper(sku), mastersku = upper(mastersku)
		, VariantDescription = REPLACE(VariantDescription,'//',''), size = REPLACE(size,'//','')

-- mixed categories

-- select distinct [category:1] from cvo_hs_inventory_8
IF(OBJECT_ID('tempdb.dbo.#cats') is not null) drop table dbo.#cats
create table #cats
(
crank int,
category varchar(15)
)
INSERT INTO #CATS VALUES(1,'COLE HAAN')
insert into #cats values(2,'FRAME')
insert into #cats values(3,'SUN')
insert into #cats values(4,'SUN SPECIALS')
insert into #cats values(5,'EORS')
insert into #cats values(6,'RED')
insert into #cats values(7,'QOP')
insert into #cats values(8,'EOR')
insert into #cats values(99,'POP')


;with cte as 
(
select i8.mastersku, min(#cats.crank) newcat From cvo_hs_inventory_8 i8 
LEFT OUTER JOIN #CATS ON #cats.category = i8.[category:1]
where i8.mastersku in 
(
select mastersku from cvo_hs_inventory_8
where [category:1] <> 'pop' AND mastersku <> ''
group by mastersku
having count(distinct [category:1])>1
)
group by i8.mastersku
-- order by i8.mastersku
)
update i set i.[category:1] = (select top 1 category from #cats where crank = cte.newcat)  
-- select cte.mastersku, cte.newcat, (select category from #cats where crank = cte.newcat)  
from cte
inner join cvo_hs_inventory_8 i on i.mastersku = cte.mastersku

/*
SELECT 
sku, mastersku , name, unitprice, minqty, multqty, manufacturer,
barcode, longdesc, variantdescription, imageurls,
[category:1],
[category:2], color, size [|], coll, model, pomdate, releasedate, status, gender,
specialtyfit, apr, new, sunps, costco, shelfqty, nextpoduedate, hide, masterhide
FROM  cvo_hs_inventory_8  ORDER BY sku
*/
 
/*
SELECT * FROM cvo_hs_inventory_8 t1  --select 9163-9208
JOIN CVO_HS_INVENTORY_QTYUPD t2 on t1.sku=t2.sku where t1.sku like 'izc%'

SELECT * FROM cvo_hs_inventory_8 t1  where [category:2] in ('revo')
*/
-- EXEC HS_Inventory8_sp

--UPDATE ia SET category_2 = 'Female-adult'
---- SELECT category_2, * 
--FROM inv_master_add ia WHERE field_2 = 'hermosa beach'
--AND category_2 <> 'Female-adult'

UPDATE  dbo.cvo_hs_inventory_8 SET NAME='OCEAN PACIFIC SUNS KIT'
		, LongDesc='OCEAN PACIFIC SUNS KIT'
		, [CATEGORY:1]= 'SUN', MANUFACTURER= 'CLEARVISION' 
	    WHERE sku = 'OPZSUNSKIT'
-- select * from #Data1


UPDATE dbo.cvo_hs_inventory_8  SET [category:1] = 'LAST CHANCE' 
	WHERE [category:1] = 'COLE HAAN' AND ShelfQty > 0


END

--SELECT distinct manufacturer, [category:1] FROM #data1 ORDER BY manufacturer, [category:1]

--SELECT distinct manufacturer, [category:1] FROM #final ORDER BY manufacturer, [category:1]


--SELECT distinct manufacturer, [category:1] FROM dbo.cvo_hs_inventory_8 ORDER BY manufacturer, [category:1]

-- select mastersku, variantdescription, [category:1], shelfqty, hide From cvo_hs_inventory_8 where [category:1] in ('cole haan','last chance')












GO

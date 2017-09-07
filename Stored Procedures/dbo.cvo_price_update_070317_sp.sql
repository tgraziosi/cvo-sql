SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[cvo_price_update_070317_sp]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		-- update prices from temp table

		-- =concatenate("insert into #new_price values('brand','model','front','temple','list','eff')")

		-- if(object_id('tempdb.dbo.#new_price') is not null) drop table #new_price

		create table #new_price
		(brand varchar(20),
		model varchar(20),
		front_price decimal(20,8),
		temple_price decimal(20,8),
		list_price decimal(20,8),
		eff_date datetime)

		TRUNCATE TABLE #new_price

		INSERT INTO #new_price VALUES ( 'RR', 'CASTLE PEAK', 20.00, 11.75, 39.99, '7/3/2017' )
INSERT INTO #new_price VALUES ( 'RR', 'DIAMOND PEAK', 20.00, 11.75, 39.99, '7/3/2017' )
INSERT INTO #new_price VALUES ( 'RR', 'DICKENSON', 20.00, 11.75, 39.99, '7/3/2017' )
INSERT INTO #new_price VALUES ( 'RR', 'EAGLE PEAK', 20.00, 11.75, 39.99, '7/3/2017' ) 
INSERT INTO #new_price VALUES ( 'RR', 'GRANITE PEAK', 20.00, 11.75, 39.99, '7/3/2017' ) 
INSERT INTO #new_price VALUES ( 'RR', 'KENT', 20.00, 11.75, 39.99, '7/3/2017' )
INSERT INTO #new_price VALUES ( 'RR', 'KINGS PEAK', 20.00, 11.75, 39.99, '7/3/2017' ) 
INSERT INTO #new_price VALUES ( 'RR', 'LOOK-OUT PEAK', 20.00, 11.75, 39.99, '7/3/2017' ) 
INSERT INTO #new_price VALUES ( 'RR', 'PIKES PEAK', 20.00, 11.75, 39.99, '7/3/2017' )
INSERT INTO #new_price VALUES ( 'RR', 'PRINCETON', 20.00, 11.75, 39.99, '7/3/2017' ) 
INSERT INTO #new_price VALUES ( 'RR', 'QUAIL PEAK', 20.00, 11.75, 39.99, '7/3/2017' ) 
INSERT INTO #new_price VALUES ( 'RR', 'ROCKY PEAK', 20.00, 11.75, 39.99, '7/3/2017' ) 
INSERT INTO #new_price VALUES ( 'RR', 'RUTGERS', 20.00, 11.75, 39.99, '7/3/2017' )
INSERT INTO #new_price VALUES ( 'RR', 'SPLIT PEAK', 20.00, 11.75, 39.99, '7/3/2017' ) 
INSERT INTO #new_price VALUES ( 'RR', 'TARLETON', 20.00, 11.75, 39.99, '7/3/2017' )
INSERT INTO #new_price VALUES ( 'RR', 'VANDERBILT', 20.00, 11.75, 39.99, '7/3/2017' ) 
INSERT INTO #new_price VALUES ( 'RR', 'VILLANOVA', 20.00, 11.75, 39.99, '7/3/2017' ) 
INSERT INTO #new_price VALUES ( 'RR', 'WAGNER', 20.00, 11.75, 39.99, '7/3/2017' )
INSERT INTO #new_price VALUES ( 'RR', 'WILDCAT PEAK', 20.00, 11.75, 39.99, '7/3/2017' )
INSERT INTO #new_price VALUES ( 'RR', 'YOUNGSTOWN', 20.00, 11.75, 39.99, '7/3/2017' )


SELECT * FROM #new_price AS np

		--select distinct np.brand ,
  --                      np.model ,
  --                      np.front_price ,
  --                      np.temple_price ,
  --                      np.list_price ,
  --                      np.eff_date,
		--				i.part_no
		--FROM
		--#new_price np
		--LEFT OUTER JOIN cvo_inv_master_r2_vw i ON i.Collection = np.brand AND i.model = np.model
		--WHERE np.eff_date = '01/25/2016'

		--where type_code in ('frame','sun','parts','bruit') 
		--and ia.category_3 in ('','front','temple-l','temple-r','cable-r','cable-l')
		--and i.void = 'n'

		--select * From #new_price np where not exists (select 1 from inv_master_add ia where ia.field_2 = np.model)
		-- end part 1

		-- start part  2 - updates 

		--if(object_id('dbo.part_price_bkup_070317') is not null) drop table part_price_bkup_070317
		--select * into part_price_bkup_022017 from part_price


		-- 11 sec
		update p set price_a = np.front_price
		-- select i.category brand, ia.field_2 model, i.part_no, i.type_code, ia.category_3 part_type, ia.field_26 release_date, ia.field_28 pom_date, p.price_a, np.*
		from inv_master i 
		inner join inv_master_add ia on ia.part_no = i.part_no
		inner join part_price p on p.part_no = i.part_no
		inner join #new_price np on np.brand = i.category and np.model = ia.field_2
		where type_code in ('frame','sun','parts','bruit') 
		and ia.category_3 in ('','front','temple-l','temple-r','cable-r','cable-l')
		and i.void = 'n'
		and np.eff_date = np.eff_date
		and ia.category_3 in ('front') 
		AND p.price_a <> np.front_price
		-- AND ia.field_26 >= np.eff_date

		-- frames/suns and bruits
		-- 8 sec
		 update p set price_a = np.list_price
		-- select i.category brand, ia.field_2 model, i.part_no, i.type_code, ia.category_3 part_type, ia.field_26 release_date, ia.field_28 pom_date, p.price_a, np.*
		from inv_master i 
		inner join inv_master_add ia on ia.part_no = i.part_no
		inner join part_price p on p.part_no = i.part_no
		inner join #new_price np on np.brand = i.category and np.model = ia.field_2
		where type_code in ('frame','sun','parts','bruit') 
		and ia.category_3 in ('','front','temple-l','temple-r','cable-r','cable-l')
		and i.void = 'n'
		-- and ia.field_26 >= np.eff_date
		and ia.category_3 in ('','bruit') 
		AND p.price_a <> np.list_price

				-- temples 
		-- 14 sec
		update p set price_a = np.temple_price
		-- select i.category brand, ia.field_2 model, i.part_no, i.type_code, ia.category_3 part_type, ia.field_26 release_date, ia.field_28 pom_date, p.price_a, np.*
		from inv_master i 
		inner join inv_master_add ia on ia.part_no = i.part_no
		inner join part_price p on p.part_no = i.part_no
		inner join #new_price np on np.brand = i.category and np.model = ia.field_2
		where type_code in ('frame','sun','parts','bruit') 
		and ia.category_3 in ('','front','temple-l','temple-r','cable-r','cable-l')
		and i.void = 'n'
		-- and ia.field_26 >= np.eff_date
		and ia.category_3 in ('temple-l','temple-r','cable-r','cable-l')
		and p.price_a <> np.temple_price

		

		-- UPDATE CMI

		update CMI SET cmi.front_price = np.front_price, cmi.temple_price = np.temple_price,	cmi.wholesale_price = np.list_price
		-- SELECT * 
		from #new_price np 
		inner join cvo_cmi_models cmi on cmi.brand = np.brand and cmi.model_name = np.model
		where np.eff_date = np.eff_date
		AND (cmi.front_price <> np.front_price OR cmi.temple_price <> np.temple_price OR cmi.wholesale_price <> np.list_price)


END
GO

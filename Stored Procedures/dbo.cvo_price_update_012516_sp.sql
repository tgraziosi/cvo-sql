SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[cvo_price_update_012516_sp]
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


insert into #new_price values('BCBG','BLAIRE','47.5','25.5','94.99','1/25/2016')
insert into #new_price values('BCBG','FIORELLA','47.5','25.5','94.99','1/25/2016')
insert into #new_price values('BCBG','G-ADISSON','32.5','18','64.99','1/25/2016')
insert into #new_price values('BCBG','G-FRANCA','32.5','18','64.99','1/25/2016')
insert into #new_price values('BCBG','KATIA','47.5','25','94.99','1/25/2016')
insert into #new_price values('BCBG','LANNA','30','16.75','59.99','1/25/2016')
insert into #new_price values('BCBG','MARTA','47.5','25','94.99','1/25/2016')
insert into #new_price values('BCBG','RAFFAELLA','47.5','25.5','94.99','1/25/2016')
insert into #new_price values('BCBG','ROMINA','47.5','25','94.99','1/25/2016')
insert into #new_price values('BCBG','Seductive','35','18.75','69.99','1/25/2016')
insert into #new_price values('cvo','ADAM II','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('cvo','ALEXIS','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','ALYSSA II','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','ANDY','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','BERNICE','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('cvo','BRIAN II','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','Bronwyn','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('cvo','CLINT','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','CORA','25','14.25','49.99','1/25/2016')
insert into #new_price values('cvo','Cressida','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('cvo','DARCY','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('cvo','DARLA','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','DAVID II','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','EMMA','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','HAROLD','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','JACQUELINE II','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('cvo','JENA','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','JUDY','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('cvo','Mandy','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','MARJORIE','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','Meryl','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','NATHAN','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','Norman','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','PETITE 28','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','PETITE 29','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('cvo','ROSALIND','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('cvo','SANDRA','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('cvo','VINCE','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','Walter A','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','Walter N','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('cvo','XL8','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('DD','BUTTERCUP','25','14.25','49.99','1/25/2016')
insert into #new_price values('DD','HALF PINT','25','14.25','49.99','1/25/2016')
insert into #new_price values('DD','HOT SHOT','25','14.25','49.99','1/25/2016')
insert into #new_price values('DD','LIL BEAN','25','14.25','49.99','1/25/2016')
insert into #new_price values('DD','MUNCHKIN','25','14.25','49.99','1/25/2016')
insert into #new_price values('DD','SPROUT','25','14.25','49.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 1','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 2','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 3','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 4','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 6','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 7','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 8','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 9','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 10','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 11','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 12','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 13','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 14','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 41','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 42','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 43','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 44','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 45','26','14.75','51.99','1/25/2016')
insert into #new_price values('DH','DURAHINGE 46','26','14.75','51.99','1/25/2016')
insert into #new_price values('ET','ALORA','27.5','15.5','54.99','1/25/2016')
insert into #new_price values('ET','ANDALUSIA','30','16.75','59.99','1/25/2016')
insert into #new_price values('ET','KATORI','30','16.75','59.99','1/25/2016')
insert into #new_price values('ET','LONDON','30','16.25','59.99','1/25/2016')
insert into #new_price values('ET','SAO PAULO','35','19.25','69.99','1/25/2016')
insert into #new_price values('ET','SHANGHAI','27.5','15.5','54.99','1/25/2016')
insert into #new_price values('ET','SYDNEY','27.5','15.5','54.99','1/25/2016')
insert into #new_price values('ET','TIRANA','27.5','15.5','54.99','1/25/2016')
insert into #new_price values('ET','TOKI','27.5','15.5','54.99','1/25/2016')
insert into #new_price values('ET','TUSCANY','30','16.75','59.99','1/25/2016')
insert into #new_price values('IZOD','437','33','17.75','65.99','1/25/2016')
insert into #new_price values('IZOD','438','33','17.75','65.99','1/25/2016')
insert into #new_price values('IZOD','439','33','17.75','65.99','1/25/2016')
insert into #new_price values('IZOD','440','33','17.75','65.99','1/25/2016')
insert into #new_price values('IZOD','2000','30','16.75','59.99','1/25/2016')
insert into #new_price values('IZX','501','30','16.25','59.99','1/25/2016')
insert into #new_price values('IZX','531','30','16.25','59.99','1/25/2016')
insert into #new_price values('JMC','033','26.5','15','52.99','1/25/2016')
insert into #new_price values('JMC','049','31.5','17.5','62.99','1/25/2016')
insert into #new_price values('JMC','51','31.5','17.5','62.99','1/25/2016')
insert into #new_price values('JMC','52','26.5','15','52.99','1/25/2016')
insert into #new_price values('JMC','55','31.5','17.5','62.99','1/25/2016')
insert into #new_price values('JMC','4005','31.5','17.5','62.99','1/25/2016')
insert into #new_price values('JMC','4006','26.5','15','52.99','1/25/2016')
insert into #new_price values('JMC','4009','31.5','17.5','62.99','1/25/2016')
insert into #new_price values('JMC','4011','31.5','17.5','62.99','1/25/2016')
insert into #new_price values('JC','ASTORIA','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('JC','BAXTER PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','BELFAIR PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','BLUESTONE PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','CARLEY PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','CASCADE PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','CATALINA PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','CHELSEA','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','CLEVELAND','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('JC','DARIEN','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','FINLEY PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','FOREST PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','HAMPTON','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('JC','LEWISVILLE','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('JC','LIBERTY PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','LINCOLN','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','MILLER PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','MISSOURI','23.5','13.5','46.99','1/25/2016')
insert into #new_price values('JC','RICKWOOD PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','TAHOE PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','TROY','21.50','12.5','42.99','1/25/2016')
insert into #new_price values('JC','WEBSTER PARK','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','WESTFIELD','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('JC','YUMA','21.5','12.5','42.99','1/25/2016')
insert into #new_price values('ME','IN THE FRAY','29','16.25','57.99','1/25/2016')
insert into #new_price values('ME','SOCIAL','29','16.25','57.99','1/25/2016')
insert into #new_price values('OP','BROOKS BEACH','26','14.75','51.99','1/25/2016')
insert into #new_price values('OP','GELATO','26','14.75','51.99','1/25/2016')
insert into #new_price values('OP','POPSICLE','26','14.75','51.99','1/25/2016')
insert into #new_price values('OP','SHERBET','26','14.75','51.99','1/25/2016')
insert into #new_price values('OP','ULUA BEACH','26','14.75','51.99','1/25/2016')
insert into #new_price values('PT','310','31','17.25','61.99','1/25/2016')
insert into #new_price values('PT','313','34','18.75','67.99','1/25/2016')
insert into #new_price values('PT','W10','34','18.75','67.99','1/25/2016')
insert into #new_price values('PT','W11','34','18.75','67.99','1/25/2016')
insert into #new_price values('PT','W12','34','18.75','67.99','1/25/2016')
insert into #new_price values('PT','W13','34','18.75','67.99','1/25/2016')
insert into #new_price values('PT','W14','34','18.75','67.99','1/25/2016')
insert into #new_price values('PT','W15','34','18.75','67.99','1/25/2016')
insert into #new_price values('PT','2','35','19.25','69.99','1/25/2016')
insert into #new_price values('PT','3','35','19.25','69.99','1/25/2016')
insert into #new_price values('PT','4','35','18.75','69.99','1/25/2016')
insert into #new_price values('BCBG','Alessia','30','16.75','59.99','1/14/2016')
insert into #new_price values('BCBG','Justine','38.5','21','74.99','1/14/2016')
insert into #new_price values('BCBG','Kasia','40','21.75','79.99','1/14/2016')
insert into #new_price values('BCBG','Nola','37.5','20.5','74.99','1/14/2016')
insert into #new_price values('BCBG','Rosette','47.5','25','94.99','1/14/2016')
insert into #new_price values('BCBG','Shauna','47.5','25','94.99','1/14/2016')
insert into #new_price values('BCBG','Silvia','35','19.25','69.99','1/14/2016')
insert into #new_price values('CVo','Aiden','21.5','12.5','42.99','1/14/2016')
insert into #new_price values('CVo','Brice','23.5','13.5','46.99','1/14/2016')
insert into #new_price values('cvo','Darrel','21.5','12.5','42.99','1/14/2016')
insert into #new_price values('cvo','Hunter','21.5','12.5','42.99','1/14/2016')
insert into #new_price values('cvo','Jacob','23.5','13.5','46.99','1/14/2016')
insert into #new_price values('cvo','Kaylee','21.5','12.5','42.99','1/14/2016')
insert into #new_price values('cvo','Maggie','21.5','12.5','42.99','1/14/2016')
insert into #new_price values('cvo','Miguel','23.5','13.5','46.99','1/14/2016')
insert into #new_price values('cvo','Nico','21.5','12.5','42.99','1/14/2016')
insert into #new_price values('cvo','Quinn','23.5','13.5','46.99','1/14/2016')
insert into #new_price values('cvo','Timothy','21.5','12.5','42.99','1/14/2016')
insert into #new_price values('ET','Abisko','35','19.25','69.99','1/14/2016')
insert into #new_price values('ET','Alessandria','35','19.25','69.99','1/14/2016')
insert into #new_price values('ET','Bari','32.5','18','64.99','1/14/2016')
insert into #new_price values('ET','Kavala','30','16.75','59.99','1/14/2016')
insert into #new_price values('ET','Liguria','27.5','15.5','54.99','1/14/2016')
insert into #new_price values('ET','Lombardia','35','19.25','69.99','1/14/2016')
insert into #new_price values('ET','Navari','27.5','15.5','54.99','1/14/2016')
insert into #new_price values('ET','Rafina','32.5','18','64.99','1/14/2016')
insert into #new_price values('ET','Sicilia','32.5','18','64.99','1/14/2016')
insert into #new_price values('IZOD','2016','28','15.75','55.99','1/14/2016')
insert into #new_price values('IZOD','2018','30','16.75','59.99','1/14/2016')
insert into #new_price values('IZOD','2019','30','16.75','59.99','1/14/2016')
insert into #new_price values('JC','Casper','23.5','13.5','46.99','1/14/2016')
insert into #new_price values('JC','Garner Park','21.5','12.5','42.99','1/14/2016')
insert into #new_price values('JC','Mayer Park','23.5','13.5','46.99','1/14/2016')
insert into #new_price values('JC','Nashville','23.5','13.5','46.99','1/14/2016')
insert into #new_price values('JC','Tampa','23.5','13.5','46.99','1/14/2016')
insert into #new_price values('JC','Watertown','23.5','13.5','46.99','1/14/2016')
insert into #new_price values('JC','Westlake Park','21.5','12.5','42.99','1/14/2016')
insert into #new_price values('JMC','4017','31.5','17.5','62.99','1/14/2016')
insert into #new_price values('JMC','4019','26.5','15','52.99','1/14/2016')
insert into #new_price values('OP','SMOOTHIE','26','14.75','51.99','1/14/2016')
insert into #new_price values('OP','SUNDAE','26','14.75','51.99','1/14/2016')
insert into #new_price values('PT','W16','34','18.75','67.99','1/14/2016')

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

		if(object_id('dbo.part_price_bkup_012516') is not null) drop table part_price_bkup_012516
		select * into part_price_bkup_012516 from part_price

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
		and np.eff_date = '01/25/2016'
		and ia.category_3 in ('front') and p.price_a <> np.front_price

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
		and np.eff_date = '01/25/2016'
		and ia.category_3 in ('','bruit') and p.price_a <> np.list_price

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
		and np.eff_date = '01/25/2016'
		and ia.category_3 in ('temple-l','temple-r','cable-r','cable-l') and p.price_a <> np.temple_price

		

		-- UPDATE CMI

		update CMI SET cmi.front_price = np.front_price, 
						cmi.temple_price = np.temple_price, 
						cmi.wholesale_price = np.list_price
		-- select * 
		from #new_price np 
		inner join cvo_cmi_models cmi on cmi.brand = np.brand and cmi.model_name = np.model
		where np.eff_date = '1/25/2016'



END
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[cvo_price_update_021919_sp]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		-- update prices from temp table

		-- =concatenate("insert into #new_price values('brand','model','front','temple','list','eff')")
        -- =CONCATENATE("insert into #new_price values('",A148,"','",C148,"','",ROUND(H148,2),"','",ROUND(I148,2),"','",ROUND(J148,2),"','02/19/2019')")
        
		-- if(object_id('tempdb.dbo.#new_price') is not null) drop table #new_price

		create table #new_price
		(brand varchar(20),
		model varchar(20),
		front_price decimal(20,8),
		temple_price decimal(20,8),
		list_price decimal(20,8),
		eff_date datetime)

		TRUNCATE TABLE #new_price


insert into #new_price values('BCBG','AGATHA','31.5','17','62.99','02/19/2019')
insert into #new_price values('BCBG','AINSLEY','36.5','20','72.99','02/19/2019')
insert into #new_price values('BCBG','AISHA','36.5','19.5','72.99','02/19/2019')
insert into #new_price values('BCBG','ASHLYN','39.5','21.5','78.99','02/19/2019')
insert into #new_price values('BCBG','AUGUSTINA','36.5','19.5','72.99','02/19/2019')
insert into #new_price values('BCBG','AVRIL','36.5','19.5','72.99','02/19/2019')
insert into #new_price values('BCBG','BEATRIZ','36.5','20','72.99','02/19/2019')
insert into #new_price values('BCBG','BLAKELY','36.5','19.5','72.99','02/19/2019')
insert into #new_price values('BCBG','BRYNN','39.5','21.5','78.99','02/19/2019')
insert into #new_price values('BCBG','CAMDEN','39.5','21.5','78.99','02/19/2019')
insert into #new_price values('BCBG','CLEO','39.5','21.5','78.99','02/19/2019')
insert into #new_price values('BCBG','DARBY','34','18.75','67.99','02/19/2019')
insert into #new_price values('BCBG','DARIA','36.5','20','72.99','02/19/2019')
insert into #new_price values('BCBG','DOREENA','31.5','17','62.99','02/19/2019')
insert into #new_price values('BCBG','ELODIE','31.5','17','62.99','02/19/2019')
insert into #new_price values('BCBG','ESMERALDA','39.5','21','78.99','02/19/2019')
insert into #new_price values('BCBG','Evie','31.5','17','62.99','02/19/2019')
insert into #new_price values('BCBG','EXHILARATE','0','0','74.99','02/19/2019')
insert into #new_price values('BCBG','G-AISHA','36.5','19.5','72.99','02/19/2019')
insert into #new_price values('BCBG','G-LILAH','36.5','20','72.99','02/19/2019')
insert into #new_price values('BCBG','GREER','34','18.75','67.99','02/19/2019')
insert into #new_price values('BCBG','IONA','31.5','17','62.99','02/19/2019')
insert into #new_price values('BCBG','ISADORA','39.5','21.5','78.99','02/19/2019')
insert into #new_price values('BCBG','ISLA','36.5','20','72.99','02/19/2019')
insert into #new_price values('BCBG','ISLA','36.5','20','72.99','02/19/2019')
insert into #new_price values('BCBG','JUSTINE','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('BCBG','JUSTINE','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('BCBG','JUSTINE','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('BCBG','JUSTINE','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('BCBG','KAIA','34','18.75','67.99','02/19/2019')
insert into #new_price values('BCBG','KENDRA','36.5','19.5','72.99','02/19/2019')
insert into #new_price values('BCBG','KINSLEY','36.5','19.5','72.99','02/19/2019')
insert into #new_price values('BCBG','LAUREN','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('BCBG','LILAH','36.5','20','72.99','02/19/2019')
insert into #new_price values('BCBG','LIZZIE','36.5','20','72.99','02/19/2019')
insert into #new_price values('BCBG','MAJESTIC','0','0','74.99','02/19/2019')
insert into #new_price values('BCBG','MARTINA','34','18.75','67.99','02/19/2019')
insert into #new_price values('BCBG','MEERA','39.5','21','78.99','02/19/2019')
insert into #new_price values('BCBG','NAHLA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('BCBG','NIKKA','34','18.75','67.99','02/19/2019')
insert into #new_price values('BCBG','ORALIE','31.5','17','62.99','02/19/2019')
insert into #new_price values('BCBG','PAISLEY','34','18.25','67.99','02/19/2019')
insert into #new_price values('BCBG','PEYTON','39.5','21','78.99','02/19/2019')
insert into #new_price values('BCBG','RILEY','34','18.75','67.99','02/19/2019')
insert into #new_price values('BCBG','SAGE','41.5','22.5','82.99','02/19/2019')
insert into #new_price values('BCBG','SAGE','41.5','22.5','82.99','02/19/2019')
insert into #new_price values('BCBG','THEA','31.5','17','62.99','02/19/2019')
insert into #new_price values('BCBG','THEA','31.5','17','62.99','02/19/2019')
insert into #new_price values('BCBG','WENDA','39.5','21','78.99','02/19/2019')
insert into #new_price values('BCBG','WESLEE','39.5','21','78.99','02/19/2019')

insert into #new_price values('CVO','ALBANY','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','ALBERTA PARK','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','ALEXIS','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','ALICE','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','ARABELLA','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','AZALEA','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','BATTERY PARK','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','BENNETT PARK','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','BINGHAMTON','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','BLANCHE','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','BRICE','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','CADENCE','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','CENTERPORT','23','12.75','45.99','02/19/2019')
insert into #new_price values('CVO','CENTRAL PARK','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','CRESTWOOD','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','D 21','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','D 22','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','D 23','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','D 24','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','DAKOTA','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','DARLENE','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','DARREL','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','DAVENPORT','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','DELILAH','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','ELIZA','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','ELLIOT','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','ELMHURST PARK','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','ELMHURST PARK','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','ERIN','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','FINCH PARK','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','G-TREMONT PARK','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','HARRISBURG','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','HARTFORD','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','HAZEL','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','HECKSCHER PARK','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','HECKSCHER PARK','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','ITHACA','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','JODY','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','JUNE','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','KISSENA PARK','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','LEONORA','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','LEONORA','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','LEXIE','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','M 3020','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','M 3021','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','M 3022','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','M 3023','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','M 3024','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','M 3025','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','M 3026','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','M 3027','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','M 3028','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','M 3029','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','MORGAN','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','NELLIE','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','NOELLE','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','OAK PARK','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','OSCAR','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','PETITE 34','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','PIER PARK','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','PRESCOTT','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','PRUDENCE','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','SANTA MONICA','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','SANTA MONICA','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','SEBASTIAN','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','SERENA','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','T 5609','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','T 5610','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','T 5611','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','TREMONT PARK','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','WASHINGTON PARK','23','13.25','45.99','02/19/2019')
insert into #new_price values('DD','BROWNIE','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','BUTTERCUP','25','14.25','49.99','02/19/2019')
insert into #new_price values('DD','BUTTERCUP','25','14.25','49.99','02/19/2019')
insert into #new_price values('DD','CAKE POP','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','CHOCO CHIP','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','Cookie Dough','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','Cupcake','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','CUTIE PIE','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','Gummy Bear','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','Gummy Bear','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','MUD SLIDE','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','RAINBOW COOKIE','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','ROCKY ROAD','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','SMORES','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','SPRINKLES','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('DD','Tutti Frutti','16.5','9.5','32.99','02/19/2019')
insert into #new_price values('ET','ALBURY','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','AMALFI','34','18.75','67.99','02/19/2019')
insert into #new_price values('ET','ANTALYA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','BAVARIA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','BERLIN','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','BUSAN','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','CANCUN','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','CHANIA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','EDINBERG','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','HAVANA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','HAVANA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','JAIPUR','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','KAZAN','29','16.25','57.99','02/19/2019')
insert into #new_price values('ET','LAMIA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','LEIDEN','29','16.25','57.99','02/19/2019')
insert into #new_price values('ET','LUCERNE','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','LECCE','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','MACAU','34','18.75','67.99','02/19/2019')
insert into #new_price values('ET','MARSEILLE','34','18.75','67.99','02/19/2019')
insert into #new_price values('ET','MONTERREY','29','16.25','57.99','02/19/2019')
insert into #new_price values('ET','PADUA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','PARMA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','PATNA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','PERTH','34','18.75','67.99','02/19/2019')
insert into #new_price values('ET','PORTO','34','18.75','67.99','02/19/2019')
insert into #new_price values('ET','PROCIDA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','PYLOS','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('ET','SHIMA','34','18.75','67.99','02/19/2019')
insert into #new_price values('ET','TAIPEI','29','16.25','57.99','02/19/2019')
insert into #new_price values('ET','TAVIRA','29','16.25','57.99','02/19/2019')
insert into #new_price values('IZOD','2009','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2009','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2014','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('IZOD','2014','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('IZOD','2032','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2034','29.5','16','58.99','02/19/2019')
insert into #new_price values('IZOD','2034','29.5','16','58.99','02/19/2019')
insert into #new_price values('IZOD','2035','29.5','16','58.99','02/19/2019')
insert into #new_price values('IZOD','2037','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('IZOD','2038','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2039','34.5','19','68.99','02/19/2019')
insert into #new_price values('IZOD','2040','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2041','34.5','18.5','68.99','02/19/2019')
insert into #new_price values('IZOD','2042','34.5','18.5','68.99','02/19/2019')
insert into #new_price values('IZOD','2043','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2044','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2045','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2046','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2047','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2048','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2049','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('IZOD','2049','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('IZOD','2049','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('IZOD','2050','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2051','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2052','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2052','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2053','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2054','29.5','16','58.99','02/19/2019')
insert into #new_price values('IZOD','2055','29.5','16','58.99','02/19/2019')
insert into #new_price values('IZOD','2056','29.5','16','58.99','02/19/2019')
insert into #new_price values('IZOD','2058','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2059','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2060','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2062','34.5','19','68.99','02/19/2019')
insert into #new_price values('IZOD','2063','34.5','19','68.99','02/19/2019')
insert into #new_price values('IZOD','2064','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2064','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2065','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2065','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2066','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2067','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2067','31.5','17','62.99','02/19/2019')
insert into #new_price values('IZOD','2068','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2069','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','2070','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('IZOD','2071','29.5','16','58.99','02/19/2019')
insert into #new_price values('IZOD','2071','29.5','16','58.99','02/19/2019')
insert into #new_price values('IZOD','2072','29.5','16','58.99','02/19/2019')
insert into #new_price values('IZOD','G-2040','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('IZOD','G-2049','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('IZOD','G-2050','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('JMC','4018','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4019','28.5','16','56.99','02/19/2019')
insert into #new_price values('JMC','4021','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4031','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4032','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4035','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4036','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4037','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4038','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4039','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4040','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4041','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4045','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4046','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4048','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4050','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4051','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4052','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4053','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4054','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4055','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4056','28.5','16','56.99','02/19/2019')
insert into #new_price values('JMC','4300','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4301','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4302','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4302','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4302','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('JMC','4303','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4304','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4304','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','4305','31','17.25','61.99','02/19/2019')
insert into #new_price values('JMC','G-4051','33.5','18.5','66.99','02/19/2019')
insert into #new_price values('OP','817','25','14.25','49.99','02/19/2019')
insert into #new_price values('OP','817','25','14.25','49.99','02/19/2019')
insert into #new_price values('OP','817','25','14.25','49.99','02/19/2019')
insert into #new_price values('OP','817','25','14.25','49.99','02/19/2019')
insert into #new_price values('OP','817','25','14.25','49.99','02/19/2019')
insert into #new_price values('OP','847','25','14.25','49.99','02/19/2019')
insert into #new_price values('OP','851','25','14.25','49.99','02/19/2019')
insert into #new_price values('OP','853','27','14.75','53.99','02/19/2019')
insert into #new_price values('OP','854','27','14.75','53.99','02/19/2019')
insert into #new_price values('OP','855','27','14.75','53.99','02/19/2019')
insert into #new_price values('OP','857','27','14.75','53.99','02/19/2019')
insert into #new_price values('OP','858','27','14.75','53.99','02/19/2019')
insert into #new_price values('OP','859','27','14.75','53.99','02/19/2019')
insert into #new_price values('OP','860','27','14.75','53.99','02/19/2019')
insert into #new_price values('OP','861','27','14.75','53.99','02/19/2019')
insert into #new_price values('OP','862','27','14.75','53.99','02/19/2019')
insert into #new_price values('OP','ALOHA','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','BALOS BEACH','28','15.75','55.99','02/19/2019')
insert into #new_price values('OP','BEACH BREAK','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','BLACK BEACH','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','BLASTED','10','6.25','19.99','02/19/2019')
insert into #new_price values('OP','BROSKIE','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','BROULEE BEACH','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','BUNDORAN BEACH','28','15.75','55.99','02/19/2019')
insert into #new_price values('OP','CALI','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','CLUTCH','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','DEL SOL','28','15.25','55.99','02/19/2019')
insert into #new_price values('OP','FAR OUT','10','6.25','19.99','02/19/2019')
insert into #new_price values('OP','FROST','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','G-859','27','14.75','53.99','02/19/2019')
insert into #new_price values('OP','G-860','27','14.75','53.99','02/19/2019')
insert into #new_price values('OP','GLIDE','10','6.25','19.99','02/19/2019')
insert into #new_price values('OP','HOWLEE','10','6.25','19.99','02/19/2019')
insert into #new_price values('OP','INFUSION','10','6.25','19.99','02/19/2019')
insert into #new_price values('OP','INTO THE BLUE','28','15.25','55.99','02/19/2019')
insert into #new_price values('OP','MAHANGA BEACH','28','15.75','55.99','02/19/2019')
insert into #new_price values('OP','MAS OLAS','28','15.25','55.99','02/19/2019')
insert into #new_price values('OP','MAZO BEACH','28','15.75','55.99','02/19/2019')
insert into #new_price values('OP','MISSION BEACH','28','15.75','55.99','02/19/2019')
insert into #new_price values('OP','NORTH BEACH','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','NOTORIOUS','10','6.25','19.99','02/19/2019')
insert into #new_price values('OP','ORANGE BEACH','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','ORETI BEACH','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','PARTY WAVE','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','PEARL','10','6.25','19.99','02/19/2019')
insert into #new_price values('OP','PILOT','10','6.25','19.99','02/19/2019')
insert into #new_price values('OP','PINKY BEACH','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','PLAYA GRANDE','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','PLAYA HERMOSA','28','15.75','55.99','02/19/2019')
insert into #new_price values('OP','REEF','28','15.75','55.99','02/19/2019')
insert into #new_price values('OP','RINCON BEACH','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','RIPPIN','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','SEA BREEZE','10','6.25','19.99','02/19/2019')
insert into #new_price values('OP','SOL CATCHER','28','15.75','55.99','02/19/2019')
insert into #new_price values('OP','SUNBAKE','10','6.25','19.99','02/19/2019')
insert into #new_price values('OP','SURFRIDER BEACH','28','15.75','55.99','02/19/2019')
insert into #new_price values('OP','SURFSIDE','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','SWELL','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('OP','ULUA BEACH','28','15.75','55.99','02/19/2019')
insert into #new_price values('OP','VENUS BEACH','28','15.75','55.99','02/19/2019')
insert into #new_price values('OP','WIPE OUT','29.5','16.5','58.99','02/19/2019')
insert into #new_price values('SM','ACTIIVE','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','ARTFULLL','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','ARTFULLL','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','BESTTTY','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','BLONDDY','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','BONIITA','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','BRIDGIIT','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','BROOKLYNN','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','CANDIID','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','COMMANDERR','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','CRUSSHING','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','DAAPPER','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','DAAPPER','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','DIXIIE','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','DRAMATTIC','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','DREAMMY','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','DULCCE','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','DYNAMMIC','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','ECCENTRK','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','ECCENTRK','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','FANCII','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','FANTASSIA','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','FLAIRR','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','GAMMBLE','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','G-ARTFULLL','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','G-BONIITA','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','G-KIMMIE','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','G-KWILTT','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','GLIITSY','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','GRAAHAM','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','GRACIIOUS','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','G-SHADDDOW','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','KAARMA','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','KANDII','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','KARLEE','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','KHAOSS','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','KIMMIE','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','KRIISTA','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','KWILTT','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','LINEAAR','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','LIVVY','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','LOVVE','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','LUMMBER','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','PATCHEDD','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','PIIONEER','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','RAASCAL','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','RANDO','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','REVEALLED','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','ROXANNNE','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','RUSSTY','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','SAASHA','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','SANDEE','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','SHADDDOW','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','SHANNIA','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','SKOLLAR','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','SLIICK','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','STAYCEE','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','SWAAAGGER','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','TIIMBERR','31.5','17.5','62.99','02/19/2019')
insert into #new_price values('SM','TROOPAH','28.5','16','56.99','02/19/2019')
insert into #new_price values('SM','TWIRLSS','31.5','17','62.99','02/19/2019')
insert into #new_price values('SM','WITTIE','31.5','17','62.99','02/19/2019')

insert into #new_price values('CVO','T 5001','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','T 5004','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','T 5604','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','T 5605','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','T 5608','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','ADAM III','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','BAY PARK','23','12.75','45.99','02/19/2019')
insert into #new_price values('SM','CARNIIVAL','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','CLINT II','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','D 10','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','D 15','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','D 17','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','D 20','26.5','15','52.99','02/19/2019')
insert into #new_price values('CVO','D 54','26.5','15','52.99','02/19/2019')
insert into #new_price values('SM','FUNFFETTI','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','G-TWIINKLE','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','HAROLD II','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','MEDFORD','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','NATHAN II','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','NORMAN II','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','PROSPECT PARK','23','13.25','45.99','02/19/2019')
insert into #new_price values('CVO','SEDONA','25','14.25','49.99','02/19/2019')
insert into #new_price values('SM','SPPLASHED','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','VINCE II','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','WALTER A II','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','WALTER N II','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','WATERTOWN','25','14.25','49.99','02/19/2019')
insert into #new_price values('CVO','WILSHIRE PARK','25','14.25','49.99','02/19/2019')

insert into #new_price values('BCBG','BEXLEY','36.50','20.00','72.99','02/19/2019')
insert into #new_price values('BCBG','MAEVE','36.50','20.00','72.99','02/19/2019')

--SELECT r2.Collection, n.brand, n.* 
--FROM cvo_inv_master_r2_vw r2 join #new_price n on  r2.model = n.model
--WHERE r2.Collection <> n.brand


-- WHERE model = 'spplashed'

SELECT DISTINCT np.*
INTO #t 
FROM #new_price AS np

TRUNCATE TABLE #new_price
INSERT INTO #new_price
SELECT * FROM #t AS t

DROP TABLE #t

--SELECT np.brand,
--       np.model,
--       np.front_price,
--       np.temple_price,
--       np.list_price,
--       np.eff_date,
--       t.collection, t.model
--       FROM #new_price AS np
--LEFT OUTER JOIN dbo.cvo_inv_master_r2_tbl AS t ON t.collection = np.brand AND t.model = np.model
--WHERE t.model IS null



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


		if(object_id('dbo.part_price_bkup_021919') is not null) drop table part_price_bkup_021919
		select * into part_price_bkup_021919 from part_price


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
        AND np.front_price <> 0
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
        AND np.list_price <> 0

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
        AND np.temple_price <> 0

		

		---- UPDATE CMI

		--update CMI SET cmi.front_price = np.front_price, cmi.temple_price = np.temple_price,	cmi.wholesale_price = np.list_price
		---- SELECT * 
		--from #new_price np 
		--inner join cvo_cmi_models cmi on cmi.brand = np.brand and cmi.model_name = np.model
		--where np.eff_date = np.eff_date
		--AND (cmi.front_price <> np.front_price OR cmi.temple_price <> np.temple_price OR cmi.wholesale_price <> np.list_price)


END



GO

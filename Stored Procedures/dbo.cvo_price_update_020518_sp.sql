SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[cvo_price_update_020518_sp]
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
INSERT INTO #new_price Values ( 'AS', 'AMAZING', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'AS', 'BRAVE', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'AS', 'CHARMING', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'AS', 'CLEVER', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'AS', 'CONFIDENT', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'AS', 'COURAGEOUS', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'AS', 'GENEROUS', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'AS', 'HONEST', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'AS', 'JOYOUS', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'AS', 'KIND', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'AS', 'PASSIONATE', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'AS', 'SASSY', 45.00, 23.75, 89.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'AGATHA', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'AISHA', 35.50, 19.00, 70.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'AMAZE', 33.50, 18.00, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'ASHLYN', 38.50, 21.00, 76.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'BOLD', 33.50, 18.00, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'BRUNA', 40.50, 22.00, 80.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'BRYNN', 38.50, 21.00, 76.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'DOREENA', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'Evie', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'GREER', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'ISADORA', 38.50, 21.00, 76.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'JAMILAH', 48.00, 25.25, 95.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'JAYA', 48.00, 25.25, 95.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'JUSTINE', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'KENDRA', 35.50, 19.00, 70.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'KINSLEY', 35.50, 19.00, 70.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'LAINIE ', 35.50, 19.50, 70.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'LAUREN', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'LILAH', 35.50, 19.50, 70.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'LIZZIE', 35.50, 19.50, 70.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'MATILDA', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'MEERA', 38.50, 20.50, 76.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'MICAH', 38.50, 20.50, 76.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'NAHLA', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'NIKKA', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'ORALIE', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'PAISLEY', 33.00, 17.75, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'PANDORA ', 33.00, 17.75, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'QUINCY', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'RACY', 36.00, 19.25, 71.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'RILEY', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'SAGE', 40.50, 22.00, 80.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'SLOANE', 40.50, 22.00, 80.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'TENLEY', 38.50, 20.50, 76.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'THEA', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'TOVAH', 35.50, 19.50, 70.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'WENDA', 38.50, 20.50, 76.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'WESLEE', 38.50, 20.50, 76.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'WILEY', 38.50, 20.50, 76.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'BCBG', 'WILLOW', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'ADAM II', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'AGNES', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'ALBANY', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'ALEXIS', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'ANDY', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'AZALEA', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'BATTERY PARK', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'BINGHAMTON', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'BLANCHE', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'BRICE', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'CADENCE', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'CENTRAL PARK', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'CLINT', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'DAKOTA', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'DARREL', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'DAVENPORT', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'DELILAH', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'ELLIOT', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'ELWOOD PARK', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'FAYE', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'GLENDA', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'HAROLD', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'HAZEL', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'JODY', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'KISSENA PARK', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'LEXIE', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'MIGUEL', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'MORGAN', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'NATHAN', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'NOELLE', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'Norman', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'OSCAR', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'PETITE 34', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'PIER PARK', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'POPPY', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'PRESCOTT', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'SEBASTIAN', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'SERENA', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'TIMOTHY', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'TREMONT PARK', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'VINCE', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'Walter Aviator', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'Walter Naviator', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'CVO', 'WASHINGTON PARK', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'DH', 'DURAHINGE 10', 25.00, 13.75, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'DH', 'DURAHINGE 15', 25.00, 14.25, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'DH', 'DURAHINGE 17', 25.00, 14.25, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'DH', 'DURAHINGE 18', 25.00, 14.25, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'DH', 'DURAHINGE 20', 25.00, 14.25, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'DH', 'DURAHINGE 54', 25.00, 14.25, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'ALBURY', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'AMALFI', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'AMSTERDAM', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'BAVARIA', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'EDINBERG', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'ELENI', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'ESSEN', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'HALLE', 28.00, 15.75, 55.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'IBIZA', 33.00, 17.75, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'KAZAN', 28.00, 15.75, 55.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'LAMIA', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'LECCE', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'LIGURIA', 28.00, 15.75, 55.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'LISBON', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'LUANDA', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'MANCHESTER', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'MARSEILLE', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'MOROCCO', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'MUMBAI', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'NEWCASTLE', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'OSAKA', 28.00, 15.75, 55.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'PADUA', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'PARIS', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'PARMA', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'PATNA', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'PERTH', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'PROCIDA', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'PYLOS', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'QUEBEC', 28.00, 15.75, 55.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'RAFINA', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'RAVENNA', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'Sao Paulo', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'SHIMA', 33.00, 18.25, 65.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'SOCHI', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'TAIPEI', 28.00, 15.75, 55.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'TAVIRA', 28.00, 15.75, 55.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'ET', 'TERESINA', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2008', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2009', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2014', 28.50, 16.00, 56.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2018', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2019', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2020', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2021', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2022', 33.50, 18.00, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2023', 33.50, 18.00, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2024', 33.50, 18.00, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2025', 33.50, 18.00, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2026', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2027', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2028', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2029', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2030', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2031', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2032', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2033', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2034', 28.50, 15.50, 56.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2035', 28.50, 15.50, 56.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2036', 28.50, 16.00, 56.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2037', 28.50, 16.00, 56.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2038', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2039', 33.50, 18.50, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2040', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2041', 33.50, 18.50, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2042', 33.50, 18.00, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2043', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2044', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2045', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2049', 28.50, 16.00, 56.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2050', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2051', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2052', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2053', 30.50, 17.00, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2054', 28.50, 15.50, 56.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2055', 28.50, 15.50, 56.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2056', 28.50, 15.50, 56.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2057', 28.50, 15.50, 56.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2058', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2059', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2060', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2061', 30.50, 16.50, 60.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2804', 24.00, 13.25, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '2805', 24.00, 13.25, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '3500', 27.50, 15.00, 54.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '6001', 33.50, 18.00, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '6002', 33.50, 18.00, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '6003', 33.50, 18.00, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'IZOD', '6004', 33.50, 18.00, 66.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'BAY PARK', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'BELVEDERE PARK', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'CASCADE PARK', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'CASPER', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'MEDFORD', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'Nashville', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'PROSPECT PARK', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'ROCKFORD', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'ROSEBURG', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'SEDONA', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'Watertown', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JC', 'WILSHIRE PARK', 22.00, 12.75, 43.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '021', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '045', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '055', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '056', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4012', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4016', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4018', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4019', 27.00, 15.25, 53.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4020', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4021', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4022', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4023', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4024', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4025', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4026', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4027', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4028', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4029', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4030', 27.00, 15.25, 53.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4031', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4032', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4033', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4034', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4035', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4036', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4037', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4038', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4039', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4040', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4041', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4042', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4043', 27.00, 15.25, 53.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4044', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4045', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4046', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4047', 29.50, 16.50, 58.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4048', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4049', 27.00, 15.25, 53.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4050', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'JMC', '4051', 32.00, 17.75, 63.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', '817', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', '843', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', '844', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', '847', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', '848', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', '851', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', '853', 26.00, 14.25, 51.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', '854', 26.00, 14.25, 51.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', '855', 26.00, 14.25, 51.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', '856', 26.00, 14.25, 51.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'BALOS BEACH', 26.50, 15.00, 52.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'BEACH BREAK', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'BLACK BEACH', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'BROSKIE', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'BROULEE BEACH', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'BUNDORAN BEACH', 26.50, 15.00, 52.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'CALI', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'CLUTCH', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'FROST', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'G-817', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'G-844', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'G-847', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'MISSION BEACH', 26.50, 15.00, 52.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'NORTH BEACH', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'ORANGE BEACH', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'ORETI BEACH', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'P CAPTURE', 29.00, 15.75, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'P EXPOSURE', 29.00, 15.75, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'P FLASH', 29.00, 15.75, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'P FOCUS', 29.00, 15.75, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'P MICRO', 29.00, 15.75, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'P RESOLUTION', 29.00, 15.75, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'PARTY WAVE', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'PIPA BEACH', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'PLAYA GRANDE', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'PLAYA HERMOSA', 26.50, 15.00, 52.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'REEF', 26.50, 15.00, 52.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'RINCON BEACH', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'RIPPIN', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'SURFRIDER BEACH', 26.50, 15.00, 52.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'SWELL', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'TAMARINDO BEACH', 29.00, 16.25, 57.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'ULUA BEACH', 26.50, 15.00, 52.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'OP', 'VENUS BEACH', 26.50, 15.00, 52.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'PT', '5001', 25.00, 13.75, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'PT', '5004', 25.00, 13.75, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'PT', '5604', 25.00, 13.75, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'PT', '5605', 25.00, 13.75, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'PT', '5607', 25.00, 13.75, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'PT', '5608', 25.00, 13.75, 49.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'SM', 'FUNFFETTI', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'SM', 'G-TWIINKLE', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'SM', 'LOVVE', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'SM', 'RAASCAL', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'SM', 'SANDEE', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'SM', 'SKOLLAR', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'SM', 'SPLAATTERR', 24.00, 13.75, 47.99, '2/5/2018' ) 
INSERT INTO #new_price Values ( 'SM', 'SPPLASHED', 24.00, 13.75, 47.99, '2/5/2018' )

-- SELECT * FROM cvo_inv_master_r2_vw WHERE model = 'spplashed'

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

		if(object_id('dbo.part_price_bkup_020518') is not null) drop table part_price_bkup_070317
		select * into part_price_bkup_020518 from part_price


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

		

		---- UPDATE CMI

		--update CMI SET cmi.front_price = np.front_price, cmi.temple_price = np.temple_price,	cmi.wholesale_price = np.list_price
		---- SELECT * 
		--from #new_price np 
		--inner join cvo_cmi_models cmi on cmi.brand = np.brand and cmi.model_name = np.model
		--where np.eff_date = np.eff_date
		--AND (cmi.front_price <> np.front_price OR cmi.temple_price <> np.temple_price OR cmi.wholesale_price <> np.list_price)


END
GO
GRANT EXECUTE ON  [dbo].[cvo_price_update_020518_sp] TO [public]
GO

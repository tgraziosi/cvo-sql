
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Create Data for Frames Data SmartSubmit Template ver. 8/11/2009
-- Author: Tine Graziosi for ClearVision 
-- 2/4/2013
-- exec cvo_frames_data_extract_sp '01/05/2015'
-- 4/2015 - update for CMI
-- 10/15 - update to pull from epicor if not in cmi - (revo support)
-- =============================================
-- select distinct field_26 from inv_master_add order by field_26 desc
-- grant execute on cvo_frames_data_extract_sp to public
-- updated 05/23/2014 - tag - added brand parameter.  
--		To report on a brand, select the brand and 1/1/1900 as the release date

CREATE PROCEDURE [dbo].[cvo_Frames_Data_Extract_sp] 
@ReleaseDate datetime,
@Brand varchar(1000) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	CREATE TABLE #brand ([brand] VARCHAR(10))
	if @brand is null
	begin
		insert into #brand ([brand])
		select distinct kys from category where isnull(void,'n') = 'n' 
	end
	else
	begin
		INSERT INTO #brand ([brand])
		SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@brand)
	end

	select 
	TOP 100 percent
	--A
	i.upc_code as UPC,
	--B
	i.part_no as Frame_SKU,
	--C
	ia.field_2 as Frame_Name,
	--D
	Designer_collection = 
	case i.type_code 
	  when 'frame' then
		case i.category  -- Brand
			when 'AS' then 'Aspire Collection' -- 040915
			when 'bcbg' then 'BCBG Max Azria Collection'
			when 'CVO' then 'ClearVision Collection'
			when 'CH' then 'ColeHaan Collection'
			when 'DD' then 'dilli dalli'
			when 'DH' then 'Durahinge Collection' -- 040915
			when 'DI' then 'digit. collection'
			when 'ET' then 'Ellen Tracy Collection'
			when 'IZOD' then 
				case when ia.category_2 like '%child%' then -- gender
					'Izod Boy''s Collection'
				else 'Izod Collection' end
			when 'IZX' then 
				case when ia.category_2 like '%child%' then
					'Izod PerformX Boy''s Collection'
				else 'Izod PerformX Collection' end
			when 'JMC' then 
				case when ia.category_2 like '%child%' then
					'Jessica Girls Collection'
				else 'Jessica Collection' end
			when 'JC' then 'Junction City Collection'
			when 'ME' then 'Mark Ecko Collection'
			when 'OP' then 
				case when ia.category_2 like '%child%' then
					'Op-Ocean Pacific Kids Collection'
				else 'Op-Ocean Pacific Collection' end
			when 'PT' then 'Puriti Collection' -- 2/2014
			when 'RR' then 'Red Raven'	-- 040915
			else '** Undefined **' end
			
	  when 'sun' then
		case i.category
			when 'AS' then 'Aspire Sunglass Collection'
			when 'bcbg' then 'BCBG Max Azria Sunglass Collection'
			when 'CH' then 'Cole Haan Sunglass Collection'
			when 'ET' then 'ET Sunglass Collection'
			when 'IZX' then 'Izod PerformX Sunglass Collection'
			when 'IZOD' then 'Izod Sunglass Collection'
			when 'JMC' then 'Jessica Sunglass Collection'
			when 'ME' then 'Marc Ecko Sunglass Collection'
			when 'OP' then 'Op-Ocean Pacific Sunglass Collection'
			when 'PT' then 'Puriti Sunglass Collection'
			WHEN 'REVO' THEN 'REVO Sunglass Collection'
			else '** Undefined **' end
	  end,
	-- E 
	Brand_id = 
	case i.category 
		when 'AS' then '8311'  -- 040915
		when 'bcbg' then '6799'
		when 'CVO' then 
			case when ia.field_10 like 'Metal%' then '6432'
				else '875' end
		when 'CH' then '7112'
		when 'DD' then '7853'
		when 'DH' then '8314'  -- 040915
		when 'DI' then '7696'
		when 'ET' then '6921'
		when 'IZOD' then '6436'
		when 'IZX' then '6436'
		when 'JMC' then '6437'
		when 'JC' then '7370'
		when 'KO' then '7269'
		when 'ME' then '7697'
		when 'OP' then '6439'
		when 'PT' then '6435' -- 02/2014
		when 'RR' then '8212' -- 05/27/2014
		WHEN 'REVO' THEN '8353' -- 10/16/2015
	else '** Undefined **' end,
	--  F
	Status = 'A',
	-- G
	Product_Group_type = 
	case when i.type_code = 'sun' then 'Sunglasses' -- Sunglasses
		 when ia.category_2 like '%child%' then 'Children''s' -- Childrens
		 when ia.field_11 like '%rimless%' then 'Rimless' -- Rimless
		 when ia.field_11 like '%combo%' then 'Combinations'
		 when ia.field_10 like '%metal%' then 'Metal' -- Metal
		 when ia.field_10 like '%plastic%' then 'Plastic' 
		 else '** Undefined **' end,
	-- i.cmdty_code as Product_Group_Type,
	-- H
	Frame_Color_Group = 
	case -- ia.category_5 
		ISNULL(cmi.colorgroupcode, ia.category_5)
		when 'bla' then 'Black' -- Black
		when 'BLU' then 'Blue' -- Blue
		when 'BRN' then 'Brown' -- Brown,
		when 'GLD' then 'Gold' -- Gold,
		when 'GRN' then 'Green' -- Green,
		when 'GRY' then 'Grey' -- Grey,
		when 'GUN' then 'Gunmetal' -- Gunmetal,
		when 'MUL' then 'Multicolor' -- Multicolor,
		when 'ORA' then 'Orange' -- Orange,
		when 'PNK' THEN 'Rose' -- Rose ?? there is no pink
		when 'pur' then 'Purple' -- Purple
		when 'red' then 'Red' -- Red
		when 'sil' then 'Silver' -- Silver
		when 'tor' then 'Tortoise' -- Tortoise
		when 'whi' then 'White' -- White
		else '***' end,
	--ia.category_5 as Frame_Color_Group,
	-- I
	-- ia.field_3 as Frame_Color_Description,
	ISNULL(cmi.colorname, ia.field_3) Frame_Color_Description,
	-- J
	' ' as Frame_color_code,
	-- K
	' ' as Lens_color_code,
	-- L
	' ' as LENS_COLOR_DESCRIPTION,
	-- M
	-- cast(ia.field_17 as int) as Eye_Size,
	cast(ISNULL(cmi.eye_size,ia.field_17) as int) as Eye_Size,
	-- N
	--cast(ia.field_19 as int) as A,
	' ' as A,
	-- cast(cmi.a_size as int) as A,
	-- O
	--cast(ia.field_20 as int) as B,
	' ' as B,
	-- cast(cmi.b_size as int) as B,
	-- P
	--cast(ia.field_21 as int) as ED,
	' ' as ED,
	-- cast(cmi.ed_size as int) as ED, 
	-- Q
	' ' as ED_Angle,
	-- R
	-- ia.field_8 as Temple_length,
	ISNULL(cmi.temple_size, ia.field_8) as Temple_length,
	-- S
	-- ia.field_6 as Bridge_Size,
	ISNULL(cmi.dbl_size, ia.field_6) as Bridge_Size,
	-- T
	-- cmi.dbl_size as DBL,
	'' as DBL,
	-- U
	'' as Circumference,
	-- V
	Gender = 
	case when ia.category_2 like '%female%' then 'Female' -- Female
		 when ia.category_2 like '%male%' then 'Male' 
		 when ia.category_2 like '%unisex%' then 'Unisex'
		 else '***' end,
	-- W
	Age_type = 
	case when ia.category_2 like '%adult%' then 'Adult'
		when ia.category_2 like '%child%' then 'Child'
		else '***' end,
	-- X
	Material_type = 
	case when ia.field_10 like '%titanium%' then 'Titanium'
		when ia.field_10 like '%metal%' then 'Metal'
		when ia.field_10 like '%plastic%' then 'Plastic'
		else '***' end,
	-- Y
	' ' as Material_description,
	-- Z
	' ' as Precious_Metal_type,
	-- AA
	' ' as Precious_Metal_description,
	-- AB
	Country_of_Origin = 
	case i.country_code
		when 'ca' then 'Canada' -- Canada
		when 'CH' then 'Switzerland' -- Switzerland
		when 'CN' then 'China' -- China
		when 'de' then 'Germany' -- Germany
		when 'fr' then 'France' -- France
		when 'IL' then 'Israel' -- Israel
		when 'it' then 'Italy' -- Italy
		when 'JP' then 'Japan' -- Japan
		when 'kp' then 'Korea' -- Korea
		when 'KR' then 'Korea' -- Korea
		when 'us' then 'USA' -- USA
		WHEN 'MU' THEN 'Mauritius'
		else '***' end,
	-- AC
	Temple_type = 
	case when ia.field_13 like '%skull%' then 'Skull' 
		when ia.field_13 like '%cable%' then 'Cable'
		else 'Skull' end, -- Skull
	-- AD
	' ' as Temple_Description,
	-- AE
	Bridge_type = 
		case when ia.field_10 like '%metal%' then 'Adjustable nose pads' -- adjustable nose pads
			when ia.field_10 like '%plastic%' then 'Universal' -- Universal
		else 'Universal' end,
	-- AF
	' ' as Bridge_Description,
	-- AG
	--'' as Sunglass_Lens_type,
	Sunglass_Lens_type = 
	case when i.type_code = 'sun' then
	case when ia.field_24 like '%polycarb%' then 'Polycarbonate'
		when ia.field_24 like '%CR39%' then 'CR-39'
		else '????' end
	else '' end,
	--AH
	-- '' as Sun_lens_description,
	Sun_lens_description = 
	case when i.type_code = 'sun' 
		then isnull(ia.field_23,'????')
		else '' end,
	--AI
	' ' as Trim_type,
	-- AJ 
	' ' as Trim_description,
	-- ak
	' ' as clip_sun_glass_type,
	--AL
	' ' Clip_sunglass_description,
	-- am
	' ' as sideshields_type,
	-- AN
	' ' as Side_Shields_Description,
	-- AO
	Case_type = 
	case i.category 
		when 'cvo' then ''
		when 'jmc' then 'Soft case included.' -- soft case included
		else 'Hard case included.' end, -- hard case included
	--AP
	' ' as Case_Type_Description,
	--AQ
	--'' as Hinge_Type, -- field_13
	Hinge_type = 
	case 
		when ia.field_13 like '%spring%' then 'Spring Hinge'
		when ia.field_13 like '%standard%' then 'Regular Hinge'
		else 'Regular Hinge' end,
	--AR
	-- Rim_Type = isnull(cmi.frame_category,''), --Rim_Type = '',
	-- case ia.field_11 
	--	when '3-pc' then '3-piece compression'
	--	when 'Full' then 'Full Rim'
	--	when 'Semi-rimless' then 'Semi-Rimless'
	--	else '????' end,
	Rim_Type = 
		case isnull(cmi.frame_category,' ')
			when 'Full Acetate' then 'full rim'
			when 'Full plastic' then 'full rim'
			when 'Full metal' then 'full rim'
			when 'Plastic combo' then 'full rim'
			when 'Acetate combo' then 'full rim'
			when 'metal combo' then 'full rim'
			when '3-piece rimless' then '3-piece'
			when 'rimless' then '3-piece'
			when 'rimless combo' then '3-piece'
			when 'demi-rimless' then 'semi-rimless'
			when 'semi-rimless combo' then 'semi-rimless'
			when 'half-eye' then 'semi-rimless'
			else isnull(cmi.frame_category,'????')
			end,
	--AS
	Frame_Shape = 
		case isnull(cmi.eye_shape,ISNULL(ci.eye_shape,'????'))
		when 'almond' then 'Modified Oval'
		when 'butterfly' then 'Rectangle'
		when 'modified rectange' then 'Rectangle'
		when 'modified wayfarer' then 'Rectangle'
		when 'pillowed rectangle' then 'Rectangle'
		when 'wayfarer' then 'Rectangle'
		when 'diamond' then 'Geometric'
		when 'ELLPTICAL' then 'Geometric'
		when 'P3' then 'Modified Round'
		when 'Modifed square' then 'Square'
		else isnull(cmi.eye_shape,ISNULL(ci.eye_shape,'????'))
		end,
	-- '????' as Frame_Shape,
	--AT
	datepart(m,ia.field_26) as Month_Introduced,
	--AU
	datepart(yy,ia.field_26) as Year_Introduced,
	--AV
	cast(round(p.price_a,2) as decimal(8,2))  as Complete_Price,
	--AW
	cast(round( isnull( (select pp.price_a from inv_master_add ic (nolock)
	inner join part_price pp (nolock) on ic.part_no = pp.part_no
	inner join what_part bom (nolock) on ic.part_no = bom.part_no
	where ic.category_3 = 'front' and bom.asm_no = i.part_no), 0),2) as decimal(8,2)) as Front_price,
	--AX
	'0' as Temple_pair_price,
	--isnull( (select sum(pp.price_a) from inv_master_add ic (nolock)
	--inner join part_price pp (nolock) on ic.part_no = pp.part_no
	--inner join what_part bom (nolock) on ic.part_no = bom.part_no
	--where ic.category_3 like 'temple%' and bom.asm_no = i.part_no), 0) as Temple_Pair_price,

	--AY
	cast(round(isnull( (select sum(pp.price_a) from inv_master_add ic (nolock)
	inner join part_price pp (nolock) on ic.part_no = pp.part_no
	inner join what_part bom (nolock) on ic.part_no = bom.part_no
	where ic.category_3 = 'temple-L' and bom.asm_no = i.part_no), 0),2) as decimal(8,2)) as Temple_price,
	--AZ
	' ' as Price_Description,
	--BA
	'' as Features,
	--BB
	'' as Frame_PD_type,
	--BC
	'' as Frame_pd_description,
	--BD
	'' as lens_vision_type,
	--BE
	'' as lens_vision_description,
	--BF
	'' as pattern_name,
	--BG
	'' as rx_type,
	--BH
	'' as rx_description,
	--BI
	'' as warranty_type,
	--BJ
	'' as Warranty_description


	from #brand b 
	inner join inv_master i (nolock) on b.brand = i.category
	inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
	inner join cvo_inv_master_r2_vw ci (nolock) on ci.part_no = i.part_no
	left outer join cvo_cmi_catalog_view cmi (nolock) on cmi.collection = ci.collection
		and cmi.model = ci.model and cmi.colorname = ci.colorname and cmi.eye_size = ci.eye_size
		inner join part_price p (nolock) on p.part_no = i.part_no

	where i.void = 'N'
	AND I.TYPE_code in ('frame','sun')
	and (ia.field_26 = @ReleaseDate or @releasedate = '1/1/1900')
	order by i.part_no


END



GO

GRANT EXECUTE ON  [dbo].[cvo_Frames_Data_Extract_sp] TO [public]
GO

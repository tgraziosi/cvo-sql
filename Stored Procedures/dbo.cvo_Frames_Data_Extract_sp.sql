SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Create Data for Frames Data SmartSubmit Template ver. 8/11/2009
-- Author: Tine Graziosi for ClearVision 
-- 2/4/2013
-- exec cvo_frames_data_extract_sp '1/1/1900', 'bcbg'
-- 4/2015 - update for CMI
-- 10/15 - update to pull from epicor if not in cmi - (revo support)
-- =============================================
-- select distinct field_26 from inv_master_add order by field_26 desc
-- grant execute on cvo_frames_data_extract_sp to public
-- updated 05/23/2014 - tag - added brand parameter.  
--		To report on a brand, select the brand and 1/1/1900 as the release date

CREATE PROCEDURE [dbo].[cvo_Frames_Data_Extract_sp]
    @ReleaseDate DATETIME ,
    @Brand VARCHAR(5000) = NULL
AS
    BEGIN
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.
        SET NOCOUNT ON;
        SET ANSI_WARNINGS OFF;

        --DECLARE @RELEASEDATE DATETIME, @BRAND VARCHAR(1000)
        --SELECT @RELEASEDATE = '1/1/1900', @BRAND = 'bcbg'

        IF ( OBJECT_ID('tempdb.dbo.#framesdatalist') IS NOT NULL )
            DROP TABLE #framesdatalist;

        CREATE TABLE #framesdatalist
            (
                UPC VARCHAR(13) ,
                Frame_SKU VARCHAR(30) ,
                Frame_Name VARCHAR(40) ,
                Designer_collection VARCHAR(36) ,
                Brand_id VARCHAR(20) ,
                Status VARCHAR(1) ,
                Product_Group_type VARCHAR(13) ,
                Frame_Color_Group VARCHAR(10) ,
                Frame_Color_Description VARCHAR(40) ,
                Frame_color_code VARCHAR(1) ,
                Lens_color_code VARCHAR(1) ,
                LENS_COLOR_DESCRIPTION VARCHAR(1) ,
                Eye_Size VARCHAR(5) ,
                A INT ,
                B INT ,
                ED INT ,
                ED_Angle VARCHAR(1) ,
                Temple_length VARCHAR(10) ,
                Bridge_Size VARCHAR(10) ,
                DBL DECIMAL(18, 0) ,
                STS VARCHAR(1) ,
                Circumference VARCHAR(1) ,
                Gender VARCHAR(6) ,
                Age_type VARCHAR(5) ,
                Material_type VARCHAR(8) ,
                Material_description VARCHAR(1) ,
                Precious_Metal_type VARCHAR(1) ,
                Precious_Metal_description VARCHAR(1) ,
                Country_of_Origin VARCHAR(11) ,
                Temple_type VARCHAR(5) ,
                Temple_Description VARCHAR(1) ,
                Bridge_type VARCHAR(20) ,
                Bridge_Description VARCHAR(1) ,
                Sunglass_Lens_type VARCHAR(20) ,
                Sun_lens_description VARCHAR(20) ,
                Trim_type VARCHAR(1) ,
                Trim_description VARCHAR(1) ,
                clip_sun_glass_type VARCHAR(1) ,
                Clip_sunglass_description VARCHAR(1) ,
                sideshields_type VARCHAR(1) ,
                Side_Shields_Description VARCHAR(1) ,
                EdgeType VARCHAR(1) ,
                Case_type VARCHAR(19) ,
                Case_Type_Description VARCHAR(1) ,
                Hinge_type VARCHAR(13) ,
                Rim_Type VARCHAR(255) ,
                Frame_Shape VARCHAR(40) ,
                Month_Introduced INT ,
                Year_Introduced INT ,
                Complete_Price DECIMAL(8, 2) ,
                Front_price DECIMAL(8, 2) ,
                Temple_pair_price VARCHAR(1) ,
                Temple_price DECIMAL(8, 2) ,
                Price_Description VARCHAR(1) ,
                Features VARCHAR(1) ,
                Frame_PD_type VARCHAR(1) ,
                Frame_pd_description VARCHAR(1) ,
                lens_vision_type VARCHAR(1) ,
                lens_vision_description VARCHAR(1) ,
                pattern_name VARCHAR(1) ,
                rx_type VARCHAR(1) ,
                rx_description VARCHAR(1) ,
                warranty_type VARCHAR(1) ,
                Warranty_description VARCHAR(1) ,
                Radii VARCHAR(1)
            );

        IF ( OBJECT_ID('tempdb.dbo.#brand') IS NOT NULL )
            DROP TABLE #brand;

        CREATE TABLE #brand
            (
                brand VARCHAR(10)
            );
        IF @Brand IS NULL
            BEGIN
                INSERT INTO #brand ( brand )
                            SELECT DISTINCT kys
                            FROM   category
                            WHERE  ISNULL(void, 'n') = 'n';
            END;
        ELSE
            BEGIN
                INSERT INTO #brand ( brand )
                            SELECT ListItem
                            FROM   dbo.f_comma_list_to_table(@Brand);
            END;

        -- INSERT INTO #framesdatalist
        SELECT
            -- TOP 100 percent
            --A
                 CAST(ISNULL(i.upc_code, '') AS VARCHAR(13)) AS UPC ,
                                     --B
                 CAST(i.part_no AS VARCHAR(30)) AS Frame_SKU ,
                                     --C
                 ia.field_2 AS Frame_Name ,
                                     --D
                 Designer_collection = CASE i.type_code
                                            WHEN 'frame' THEN
                                                CASE i.category -- Brand
                                                     WHEN 'AS' THEN
                                                         'Aspire Collection'       -- 040915
                                                     WHEN 'bcbg' THEN
                                                         'BCBG Max Azria Collection'
                                                     WHEN 'CVO' THEN
                                                         'ClearVision' + 
														 ISNULL((SELECT TOP 1 ' '+attribute attrib
															 FROM dbo.cvo_part_attributes AS pa WHERE pa.part_no = i.part_no 
															 and pa.attribute IN ('tech','next','classic')),'') + ' Collection'
                                                     WHEN 'CH' THEN
                                                         'ColeHaan Collection'
                                                     WHEN 'DD' THEN 'dilli dalli'
                                                     WHEN 'DH' THEN
                                                         'Durahinge Collection'    -- 040915
                                                     WHEN 'DI' THEN
                                                         'digit. collection'
                                                     WHEN 'ET' THEN
                                                         'Ellen Tracy Collection'
                                                     WHEN 'IZOD' THEN
                                                         CASE WHEN ISNULL(
                                                                       ia.category_2 ,
                                                                       '') LIKE '%child%' THEN -- gender
                                                                  'Izod Boy''s Collection'
                                                              ELSE
                                                                  'Izod Collection'
                                                         END
                                                     WHEN 'IZX' THEN
                                                         CASE WHEN ISNULL(
                                                                       ia.category_2 ,
                                                                       '') LIKE '%child%' THEN
                                                                  'Izod PerformX Boy''s Collection'
                                                              ELSE
                                                                  'Izod PerformX Collection'
                                                         END
                                                     WHEN 'JMC' THEN
                                                         CASE WHEN ISNULL(
                                                                       ia.category_2 ,
                                                                       '') LIKE '%child%' THEN
                                                                  'Jessica Girls Collection'
                                                              ELSE
                                                                  'Jessica Collection'
                                                         END
                                                     WHEN 'JC' THEN
                                                         'Junction City Collection'
                                                     WHEN 'ME' THEN
                                                         'Mark Ecko Collection'
                                                     WHEN 'OP' THEN
                                                         CASE WHEN ISNULL(
                                                                       ia.category_2 ,
                                                                       '') LIKE '%child%' THEN
                                                                  'Op-Ocean Pacific Kids Collection'
                                                              ELSE
                                                                  'Op-Ocean Pacific Collection'
                                                         END
                                                     WHEN 'PT' THEN
                                                         'Puriti Collection'       -- 2/2014
                                                     WHEN 'RR' THEN 'Red Raven'    -- 040915
                                                     WHEN 'SM' THEN 'Steve Madden' -- 120216
                                                     ELSE '**Undefined**'
                                                END

                                            WHEN 'sun' THEN
                                                CASE ISNULL(i.category, '')
                                                     WHEN 'AS' THEN
                                                         'Aspire Sunglass Collection'
                                                     WHEN 'bcbg' THEN
                                                         'BCBG Max Azria Sunglass Collection'
                                                     WHEN 'CH' THEN
                                                         'Cole Haan Sunglass Collection'
                                                     WHEN 'ET' THEN
                                                         'ET Sunglass Collection'
                                                     WHEN 'IZX' THEN
                                                         'Izod PerformX Sunglass Collection'
                                                     WHEN 'IZOD' THEN
                                                         'Izod Sunglass Collection'
                                                     WHEN 'JMC' THEN
                                                         'Jessica Sunglass Collection'
                                                     WHEN 'ME' THEN
                                                         'Marc Ecko Sunglass Collection'
                                                     WHEN 'OP' THEN
                                                         'Op-Ocean Pacific Sunglass Collection'
                                                     WHEN 'PT' THEN
                                                         'Puriti Sunglass Collection'
                                                     WHEN 'REVO' THEN
                                                         'REVO Sunglass Collection'
                                                     WHEN 'SM' THEN 'Steve Madden'
                                                     ELSE '**Undefined**'
                                                END
                                       END ,
                                     -- E 
                 Brand_id = CAST(CASE ISNULL(i.category, '')
                                      WHEN 'AS' THEN '8311'   -- 040915
                                      WHEN 'bcbg' THEN '6799'
                                      WHEN 'CVO' THEN
                                          CASE WHEN ia.field_10 LIKE 'Metal%' THEN
                                                   '6432'
                                               ELSE '875'
                                          END
                                      WHEN 'CH' THEN '7112'
                                      WHEN 'DD' THEN '7853'
                                      WHEN 'DH' THEN '8314'   -- 040915
                                      WHEN 'DI' THEN '7696'
                                      WHEN 'ET' THEN '6921'
                                      WHEN 'IZOD' THEN '6436'
                                      WHEN 'IZX' THEN '6436'
                                      WHEN 'JMC' THEN '6437'
                                      WHEN 'JC' THEN '7370'
                                      WHEN 'KO' THEN '7269'
                                      WHEN 'ME' THEN '7697'
                                      WHEN 'OP' THEN '6439'
                                      WHEN 'PT' THEN '6435'   -- 02/2014
                                      WHEN 'RR' THEN '8212'   -- 05/27/2014
                                      WHEN 'REVO' THEN '8353' -- 10/16/2015
                                      WHEN 'SM' THEN '8506'   -- 120216
                                      ELSE '**Undefined**'
                                 END AS VARCHAR(20)) ,
                                     --  F
                 Status = 'A' ,
                                     -- G
                 Product_Group_type = CASE WHEN i.type_code = 'sun' THEN
                                               'Sunglasses'  -- Sunglasses
                                           WHEN ISNULL(ia.category_2, '') LIKE '%child%' THEN
                                               'Children''s' -- Childrens
                                           WHEN ISNULL(ia.field_11, '') LIKE '%rimless%' THEN
                                               'Rimless'     -- Rimless
                                           WHEN ISNULL(ia.field_11, '') LIKE '%combo%' THEN
                                               'Combinations'
                                           WHEN ISNULL(ia.field_10, '') LIKE '%metal%' THEN
                                               'Metal'       -- Metal
                                           WHEN ISNULL(ia.field_10, '') LIKE '%plastic%' THEN
                                               'Plastic'
                                           WHEN ISNULL(ia.field_10, '') LIKE '%TR-90%' THEN
                                               'Plastic'
                                           ELSE '**Undefined**'
                                      END ,
                                     -- i.cmdty_code as Product_Group_Type,
                                     -- H
                 Frame_Color_Group = CASE -- ia.category_5 
                 ISNULL(cmi.ColorGroupCode, ISNULL(ia.category_5, ''))
                 WHEN 'bla' THEN 'Black'      -- Black
                 WHEN 'BLU' THEN 'Blue'       -- Blue
                 WHEN 'BRN' THEN 'Brown'      -- Brown,
                 WHEN 'GLD' THEN 'Gold'       -- Gold,
                 WHEN 'GRN' THEN 'Green'      -- Green,
                 WHEN 'GRY' THEN 'Grey'       -- Grey,
                 WHEN 'GUN' THEN 'Gunmetal'   -- Gunmetal,
                 WHEN 'MUL' THEN 'Multicolor' -- Multicolor,
                 WHEN 'ORA' THEN 'Orange'     -- Orange,
                 WHEN 'PNK' THEN 'Rose'       -- Rose ?? there is no pink
                 WHEN 'pur' THEN 'Purple'     -- Purple
                 WHEN 'red' THEN 'Red'        -- Red
                 WHEN 'sil' THEN 'Silver'     -- Silver
                 WHEN 'tor' THEN 'Tortoise'   -- Tortoise
                 WHEN 'whi' THEN 'White'      -- White
                 ELSE '***'
                                     END ,
                                     --ia.category_5 as Frame_Color_Group,
                                     -- I
                                     -- ia.field_3 as Frame_Color_Description,
                 ISNULL(cmi.ColorName, ISNULL(ia.field_3, '')) Frame_Color_Description ,
                                     -- J
                 ' ' AS Frame_color_code ,
                                     -- K
                 ' ' AS Lens_color_code ,
                                     -- L
                 ' ' AS LENS_COLOR_DESCRIPTION ,
                                     -- M
                                     -- cast(ia.field_17 as int) as Eye_Size,
                 CAST(cast(ISNULL(cmi.eye_size, ISNULL(ia.field_17, 0.0)) AS FLOAT) AS VARCHAR(5)) AS Eye_Size ,
                                     -- N
                                     --cast(ia.field_19 as int) as A,
                                     --0 as A,
                 CAST(CAST(ISNULL(cmi.a_size, ISNULL(ia.field_19, 0.0)) AS FLOAT) AS INT) AS A ,
                                     -- O
                                     --cast(ia.field_20 as int) as B,
                                     --0 as B,
                 CAST(CAST(ISNULL(cmi.b_size, ISNULL(ia.field_20, 0.0)) AS FLOAT) AS INT) AS B ,
                                     -- P
                                     --cast(ia.field_21 as int) as ED,
                                     --0 as ED,
                 CAST(CAST(ISNULL(cmi.ed_size, ISNULL(ia.field_21, 0)) AS FLOAT) AS INT) AS ED ,
                                     -- Q
                 ' ' AS ED_Angle ,
                                     -- R
                                     -- ia.field_8 as Temple_length,
                 Temple_length = CAST(ISNULL(
                                          CAST(cmi.temple_size AS int), ISNULL(ia.field_8, '')) AS VARCHAR(10)) ,
                                     --	Temple_length = CAST( ISNULL((CASE WHEN ISNULL(CMI.temple_SIZE,0) = 0 THEN ISNULL(IA.FIELD_8,'') END), '')  AS VARCHAR(10)),
                                     -- S
                                     -- ia.field_6 as Bridge_Size,
                 CAST(CAST(ISNULL(cmi.dbl_size, ISNULL(ia.field_6, '')) AS FLOAT) AS VARCHAR(10)) AS Bridge_Size ,
                                     -- T
                 CAST(CAST(ISNULL(cmi.dbl_size, ISNULL(ia.field_6, 0)) AS FLOAT)  AS DECIMAL) AS DBL ,
                                     -- '' as DBL,
                 ' ' AS STS ,        --120216 - for proofing version
                                     -- U
                 '' AS Circumference ,
                                     -- V
                 Gender = CASE WHEN ia.category_2 LIKE '%female%' THEN 'Female' -- Female
                               WHEN ia.category_2 LIKE '%male%' THEN 'Male'
                               WHEN ia.category_2 LIKE '%unisex%' THEN 'Unisex'
                               ELSE '***'
                          END ,
                                     -- W
                 Age_type = CASE WHEN ia.category_2 LIKE '%adult%' THEN 'Adult'
                                 WHEN ia.category_2 LIKE '%child%' THEN 'Child'
                                 ELSE '***'
                            END ,
                                     -- X
                 Material_type = CASE WHEN ia.field_10 LIKE '%titanium%' THEN
                                          'Titanium'
                                      WHEN ia.field_10 LIKE '%metal%' THEN 'Metal'
                                      WHEN ia.field_10 LIKE '%plastic%' THEN
                                          'Plastic'
                                      WHEN ia.field_10 LIKE '%TR-90%' THEN
                                          'Plastic'
                                      ELSE '***'
                                 END ,
                                     -- Y
                 ' ' AS Material_description ,
                                     -- Z
                 ' ' AS Precious_Metal_type ,
                                     -- AA
                 ' ' AS Precious_Metal_description ,
                                     -- AB
                 Country_of_Origin = CASE i.country_code
                                          WHEN 'ca' THEN 'Canada'      -- Canada
                                          WHEN 'CH' THEN 'Switzerland' -- Switzerland
                                          WHEN 'CN' THEN 'China'       -- China
                                          WHEN 'de' THEN 'Germany'     -- Germany
                                          WHEN 'fr' THEN 'France'      -- France
                                          WHEN 'IL' THEN 'Israel'      -- Israel
                                          WHEN 'it' THEN 'Italy'       -- Italy
                                          WHEN 'JP' THEN 'Japan'       -- Japan
                                          WHEN 'kp' THEN 'Korea'       -- Korea
                                          WHEN 'KR' THEN 'Korea'       -- Korea
                                          WHEN 'us' THEN 'USA'         -- USA
                                          WHEN 'MU' THEN 'Mauritius'
                                          ELSE '***'
                                     END ,
                                     -- AC
                 Temple_type = CASE WHEN ISNULL(ia.field_13, ' ') LIKE '%skull%' THEN
                                        'Skull'
                                    WHEN ISNULL(ia.field_13, ' ') LIKE '%cable%' THEN
                                        'Cable'
                                    ELSE 'Skull'
                               END , -- Skull
                                     -- AD
                 ' ' AS Temple_Description ,
                                     -- AE
                 Bridge_type = CASE WHEN ISNULL(ia.field_10, '') LIKE '%metal%' THEN
                                        'Adjustable nose pads' -- adjustable nose pads
                                    WHEN ISNULL(ia.field_10, '') LIKE '%plastic%' THEN
                                        'Universal'            -- Universal
                                    ELSE 'Universal'
                               END ,
                                     -- AF
                 ' ' AS Bridge_Description ,
                                     -- AG
                                     --'' as Sunglass_Lens_type,
                 Sunglass_Lens_type = CASE WHEN i.type_code = 'sun' THEN
                                               CASE WHEN ISNULL(ia.field_24, '') LIKE '%polycarb%' THEN
                                                        'Polycarbonate'
                                                    WHEN ISNULL(ia.field_24, '') LIKE '%CR39%' THEN
                                                        'CR-39'
                                                    WHEN i.category = 'revo' THEN
                                                        ISNULL(ia.field_24, '') -- 03/28/2016
                                                    ELSE '????'
                                               END
                                           ELSE ''
                                      END ,
                                     --AH
                                     -- '' as Sun_lens_description,
                 Sun_lens_description = CASE WHEN i.type_code = 'sun' THEN
                                                 ISNULL(ia.field_23, '????')
                                             ELSE ' '
                                        END ,
                                     --AI
                 ' ' AS Trim_type ,
                                     -- AJ 
                 ' ' AS Trim_description ,
                                     -- ak
                 ' ' AS clip_sun_glass_type ,
                                     --AL
                 ' ' Clip_sunglass_description ,
                                     -- am
                 ' ' AS sideshields_type ,
                                     -- AN
                 ' ' AS Side_Shields_Description ,
                 ' ' AS EdgeType ,   -- 120216
                                     -- AO
                 Case_type = CASE i.category
                                  WHEN 'cvo' THEN ''
                                  WHEN 'jmc' THEN 'Soft case included.' -- soft case included
                                  ELSE 'Hard case included.'
                             END ,   -- hard case included
                                     --AP
                 ' ' AS Case_Type_Description ,
                                     --AQ
                                     --'' as Hinge_Type, -- field_13
                 Hinge_type = CASE WHEN ISNULL(ia.field_13, '') LIKE '%spring%' THEN
                                       'Spring Hinge'
                                   WHEN ISNULL(ia.field_13, '') LIKE '%standard%' THEN
                                       'Regular Hinge'
                                   ELSE 'Regular Hinge'
                              END ,
                                     --AR
                                     -- Rim_Type = isnull(cmi.frame_category,''), --Rim_Type = '',
                                     -- case ia.field_11 
                                     --	when '3-pc' then '3-piece compression'
                                     --	when 'Full' then 'Full Rim'
                                     --	when 'Semi-rimless' then 'Semi-Rimless'
                                     --	else '????' end,
                 Rim_Type = CASE ISNULL(cmi.frame_category, ' ')
                                 WHEN 'Full Acetate' THEN 'full rim'
                                 WHEN 'Acetate' THEN 'full rim'
                                 WHEN 'Full plastic' THEN 'full rim'
                                 WHEN 'Full metal' THEN 'full rim'
                                 WHEN 'Plastic combo' THEN 'full rim'
                                 WHEN 'Acetate combo' THEN 'full rim'
                                 WHEN 'metal combo' THEN 'full rim'
                                 WHEN '3-piece rimless' THEN '3-piece'
                                 WHEN 'rimless' THEN '3-piece'
                                 WHEN 'rimless combo' THEN '3-piece'
                                 WHEN 'demi-rimless' THEN 'semi-rimless'
                                 WHEN 'semi-rimless combo' THEN 'semi-rimless'
                                 WHEN 'half-eye' THEN 'semi-rimless'
                                 ELSE ISNULL(cmi.frame_category, '????')
                            END ,
                                     --AS
                 Frame_Shape = CASE ISNULL(
                                        cmi.eye_shape ,
                                        ISNULL(ci.eye_shape, '????'))
                                    WHEN 'almond' THEN 'Modified Oval'
                                    WHEN 'butterfly' THEN 'Rectangle'
                                    WHEN 'modified rectange' THEN 'Rectangle'
                                    WHEN 'modified wayfarer' THEN 'Rectangle'
                                    WHEN 'pillowed rectangle' THEN 'Rectangle'
                                    WHEN 'wayfarer' THEN 'Rectangle'
                                    WHEN 'diamond' THEN 'Geometric'
                                    WHEN 'ELLPTICAL' THEN 'Geometric'
                                    WHEN 'P3' THEN 'Modified Round'
                                    WHEN 'Modifed square' THEN 'Square'
                                    ELSE
                                        ISNULL(
                                            cmi.eye_shape ,
                                            ISNULL(ci.eye_shape, '????'))
                               END ,
                                     -- '????' as Frame_Shape,
                                     --AT
                 DATEPART(m, ia.field_26) AS Month_Introduced ,
                                     --AU
                 DATEPART(yy, ia.field_26) AS Year_Introduced ,
                                     --AV
                 CAST(ROUND(ISNULL(p.price_a, 0), 2) AS DECIMAL(8, 2)) AS Complete_Price ,
                                     --AW
                 CAST(ROUND(
                          ISNULL(
                          (   SELECT pp.price_a
                              FROM   inv_master_add ic ( NOLOCK )
                                     INNER JOIN part_price pp ( NOLOCK ) ON ic.part_no = pp.part_no
                                     INNER JOIN what_part bom ( NOLOCK ) ON ic.part_no = bom.part_no
                              WHERE  ic.category_3 = 'front'
                                     AND bom.asm_no = i.part_no ) ,
                          0) ,
                          2) AS DECIMAL(8, 2)) AS Front_price ,
                                     --AX
                 '0' AS Temple_pair_price ,
                                     --isnull( (select sum(pp.price_a) from inv_master_add ic (nolock)
                                     --inner join part_price pp (nolock) on ic.part_no = pp.part_no
                                     --inner join what_part bom (nolock) on ic.part_no = bom.part_no
                                     --where ic.category_3 like 'temple%' and bom.asm_no = i.part_no), 0) as Temple_Pair_price,

                                     --AY
                 CAST(ROUND(
                          ISNULL(
                          (   SELECT SUM(pp.price_a)
                              FROM   inv_master_add ic ( NOLOCK )
                                     INNER JOIN part_price pp ( NOLOCK ) ON ic.part_no = pp.part_no
                                     INNER JOIN what_part bom ( NOLOCK ) ON ic.part_no = bom.part_no
                              WHERE  ic.category_3 = 'temple-L'
                                     AND bom.asm_no = i.part_no ) ,
                          0) ,
                          2) AS DECIMAL(8, 2)) AS Temple_price ,
                                     --AZ
                 ' ' AS Price_Description ,
                                     --BA
                 '' AS Features ,
                                     --BB
                 '' AS Frame_PD_type ,
                                     --BC
                 '' AS Frame_pd_description ,
                                     --BD
                 '' AS lens_vision_type ,
                                     --BE
                 '' AS lens_vision_description ,
                                     --BF
                 '' AS pattern_name ,
                                     --BG
                 '' AS rx_type ,
                                     --BH
                 '' AS rx_description ,
                                     --BI
                 '' AS warranty_type ,
                                     --BJ
                 '' AS Warranty_description ,
                 '' AS Radii         -- 120216

        -- INTO #framesdatalist
        FROM     #brand b
                 INNER JOIN inv_master i ( NOLOCK ) ON b.brand = i.category
                 INNER JOIN inv_master_add ia ( NOLOCK ) ON i.part_no = ia.part_no
                 INNER JOIN cvo_inv_master_r2_vw ci ( NOLOCK ) ON ci.part_no = i.part_no
                 --left outer join cvo_cmi_catalog_view cmi (nolock) on cmi.collection = ci.collection
                 --	and cmi.model = ci.model and cmi.colorname = ci.colorname and cmi.eye_size = ci.eye_size
                 LEFT OUTER JOIN cvo_cmi_catalog_view cmi ( NOLOCK ) ON cmi.upc_code = i.upc_code
                 INNER JOIN part_price p ( NOLOCK ) ON p.part_no = i.part_no

        WHERE    i.void = 'N'
                 AND i.type_code IN ( 'frame', 'sun' )
                 -- AND i.entered_who = 'CMI'
                 AND (   @ReleaseDate = ia.field_26
                         OR @ReleaseDate = '1/1/1900' )
                 AND ISNULL(ia.field_28, GETDATE()) > '1/1/2010'
        ORDER BY i.part_no;

    --SELECT *
    --FROM #framesdatalist

    -- tempdb..sp_help #framesdatalist

    END;








GO




GRANT EXECUTE ON  [dbo].[cvo_Frames_Data_Extract_sp] TO [public]
GO

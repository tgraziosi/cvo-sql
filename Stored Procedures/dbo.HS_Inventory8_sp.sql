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
-- SELECT * FROM dbo.cvo_hs_inventory_8 WHERE coll = 'bcbgr' AND [CATEGORY:1] = 'REVO SELLDWN' SKU LIKE 'DD%' where [category:1] = 'sun' where  ReleaseDate > '1/1/2018' AND SpecialtyFit = '[multiple]'
-- SELECT DISTINCT [category:1],[category:2] FROM dbo.cvo_hs_inventory_8 AS hi WHERE [hi].[category:1] = 'sun'
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
-- 6/28/2016 - support for July programs - BTS and TWEEN and new OP kit
-- 9/2/2016 - tweeks for 9/6 release and VEW 2016 - hide all releases, not already APR until 9/9
-- 9/8/2016 - tweeks for VEW
-- 10/7/2016 - set up me selldown
-- 11/30/2016 - include all HSPOP POP items, regardless of release date
-- 12/22/2016 - BT READERS
-- 3/13/2017 = add ME unlmtd collection to me selldown
-- 11/8/2017 - tweaks for 2018 sunps/presell season
-- 12/18/2017 - change to look at cvo_part_attributes table instead of field_32
-- 2/5/2018 - misc performance udpates
-- 3/9/2018 - setup temp table for usage instead of joining to the function - performance.
-- 4/27/18 - REVO SELLDOWN
-- 5/23/2018 - ADD DD NYLON BANDS
-- 08/23 - remove revo selldown
-- 8/28 - new revo special values
-- 8/29 - bcbg retail SV for VEW
-- =============================================

CREATE PROCEDURE [dbo].[HS_Inventory8_sp]
AS
BEGIN

    SET NOCOUNT ON;

    SET ANSI_WARNINGS OFF;

    -- EXPORT FOR HANDSHAKE

    DECLARE @today DATETIME,
            @location VARCHAR(10),
            @CH DATETIME,
            @ME DATETIME,
            @UN DATETIME,
            @kodi DATETIME,
			@revosv datetime;

		DECLARE @EOS TABLE
    (
        Columnn INT,
        Prog VARCHAR(3),
        Brand VARCHAR(4),
        Style VARCHAR(60),
        part_no VARCHAR(30),
        pom_date DATETIME,
        Gender VARCHAR(30),
        Avail DECIMAL(10, 2),
        ReserveQty DECIMAL(10, 2),
        TrueAvail_2 DECIMAL(10, 2),
        TrueAvail VARCHAR(20)
    );
    SET @today = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);
    SET @location = '001';
    SET @CH = '9/1/2015'; -- START OF CH SELL-DOWN PERIOD
    SET @ME = '01/31/2017';
    -- START OF me SELL-DOWN PERIOD - 10/7 - on hold per JK
    -- SET @ME = '10/06/2016'; -- START OF me SELL-DOWN PERIOD
    SET @UN = '12/31/2016';
    SET @kodi = '7/3/2017'; -- KO and DI selldown start
	SET @revosv = '08/31/2018 12:00';


    INSERT INTO @EOS (	Columnn, Prog, Brand, Style, part_no, pom_date, Gender, Avail, ReserveQty, TrueAvail_2, TrueAvail)
    EXEC dbo.CVO_EOS_SP;

    -- 8/26/2015
    DELETE @EOS 
	FROM @EOS EOS
	join DBO.inv_master_add ia (nolock) on ia.part_no = EOS.part_no
    WHERE (EOS.Brand = 'ch' AND @today >= @CH
          )
          OR (EOS.Brand = 'me' AND @today >= @ME
             )
          OR (EOS.Brand = 'UN' AND @today >= @UN
             )
          OR (isnull(IA.field_36,'')) = 'SUNPS'
	;	  

	-- get usage data

	
	CREATE TABLE #DRP
	(
		location VARCHAR(10),
		part_no VARCHAR(7500),
		usg_option CHAR(1),
		ASofdate DATETIME,
		e4_wu INT,
		e12_wu INT,
		e26_wu INT,
		e52_wu INT,
		subs_w4 INT,
		subs_w12 INT,
		promo_w4 INT,
		promo_w12 INT,
		rx_w4 INT,
		rx_w12 INT,
		ret_w4 INT,
		ret_w12 INT,
		wty_w4 INT,
		wty_w12 INT,
		gross_w4 INT,
		gross_w12 INT
	);

	INSERT #DRP
	(
	    location,
	    part_no,
	    usg_option,
	    ASofdate,
	    e4_wu,
	    e12_wu,
	    e26_wu,
	    e52_wu,
	    subs_w4,
	    subs_w12,
	    promo_w4,
	    promo_w12,
	    rx_w4,
	    rx_w12,
	    ret_w4,
	    ret_w12,
	    wty_w4,
	    wty_w12,
	    gross_w4,
	    gross_w12
	)
	SELECT location,
           part_no,
           usg_option,
           ASofdate,
           e4_wu,
           e12_wu,
           e26_wu,
           e52_wu,
           subs_w4,
           subs_w12,
           promo_w4,
           promo_w12,
           rx_w4,
           rx_w12,
           ret_w4,
           ret_w12,
           wty_w4,
           wty_w12,
           gross_w4,
           gross_w12
		   from dbo.f_cvo_calc_weekly_usage_coll_loc('o', NULL, @location)

    -- make a list of Costco sku's from history
    IF (OBJECT_ID('tempdb.dbo.#cc') IS NOT NULL)
        DROP TABLE #cc;

    SELECT i.part_no
    INTO #cc
    FROM inv_master i (NOLOCK)
    WHERE EXISTS (
                 SELECT 1
                 FROM cvo_sbm_details sbm (NOLOCK)
                 WHERE i.part_no = sbm.part_no
                       AND sbm.customer = '045217'
                 );

    -- select * from #cc


    IF (OBJECT_ID('tempdb.dbo.#Data1') IS NOT NULL)
        DROP TABLE #Data1;

    CREATE TABLE #Data1
    (
        sku                VARCHAR(30),
        mastersku          VARCHAR(150),
        name               VARCHAR(8000),
        unitPrice          DECIMAL(10, 2),
        minQty             INT,
        multQty            INT,
        manufacturer       VARCHAR(11),
        barcode            VARCHAR(20),
        longDesc           VARCHAR(8000),
        variantdescription VARCHAR(8000),
        imageURLs          VARCHAR(1),
        [category:1]       VARCHAR(20),
        [CATEGORY:2]       VARCHAR(40),
        Color              VARCHAR(40),
        Size               VARCHAR(20),
        [|]                CHAR(1),
        COLL               VARCHAR(12),
        Model              VARCHAR(40),
        POMDate            DATETIME,
        ReleaseDate        DATETIME,
        Status             CHAR(1),
        GENDER             VARCHAR(5),
        SpecialtyFit       VARCHAR(40),
        APR                VARCHAR(1),
        New                VARCHAR(3),
        SUNPS              VARCHAR(5),
        CostCo             VARCHAR(2),
        POM                VARCHAR(3),
        Kit                VARCHAR(3),
        shelfqty           INTEGER,
        ShelfQty2          INTEGER,
        NextPODueDate      DATETIME,
        NextPOOnOrder      INTEGER,
        drp_usg            INTeger,
        qty_avl            INTEGER,
        New_shelfqty       INTEGER
    );

    INSERT INTO #Data1
        (
            sku,
            mastersku,
            name,
            unitPrice,
            minQty,
            multQty,
            manufacturer,
            barcode,
            longDesc,
            variantdescription,
            imageURLs,
            [category:1],
            [CATEGORY:2],
            Color,
            Size,
            [|],
            COLL,
            Model,
            POMDate,
            ReleaseDate,
            Status,
            GENDER,
            SpecialtyFit,
            APR,
            New,
            SUNPS,
            CostCo,
            POM,
            Kit,
            shelfqty,
            ShelfQty2,
            NextPODueDate,
            NextPOOnOrder,
            drp_usg,
            qty_avl,
            New_shelfqty
        )

    SELECT I.part_no AS sku,

           --convert(varchar(150),
           --case when type_code in ('sun','frame') and len(t1.part_no)=11 then left(t1.part_no,4)
           --	when type_code in ('sun','frame') and len(t1.part_no)=14 then left(t1.part_no,7)
           --	when type_code in ('sun','frame') and len(t1.part_no)=13 then left(t1.part_no,6)
           --	when type_code in ('sun','frame') and len(t1.part_no)=12 then left(t1.part_no,5) else '' END 
           --	) as mastersku,
           CONVERT(
                      VARCHAR(150),
                      CASE WHEN I.category IN ( 'revo', 'bt' )
                                OR (
                                   I.category = 'as'
                                   AND IA.field_2 = 'colorful'
                                   ) THEN RTRIM(LEFT(I.part_no, 6)) -- 9/6/2016 put all colorful together
						  when ia.field_2 = 'G-LILAH' AND I.CATEGORY = 'BCBG' THEN 'BCGLIA'
                          WHEN I.type_code IN ( 'sun', 'frame' ) THEN LEFT(I.part_no, LEN(I.part_no) - 7)
						  WHEN IA.FIELD_2 = 'EAR LOCKS' OR I.part_no LIKE 'DDZNB%' THEN LEFT(I.part_no, 5) -- 5/23/2018
						  ELSE ''
						 
                      END
                  ) AS mastersku,
           CASE WHEN I.category IN ( 'revo', 'op' )
                     AND I.type_code IN ( 'other', 'pop' ) THEN CONVERT(VARCHAR(150), I.description)
				WHEN I.category = 'DD' AND I.PART_NO LIKE 'DDZNB%' THEN 'DILLI DALLI ' + REPLACE(REPLACE(IA.FIELD_2,'LARGE',''),'SMALL','')
				ELSE CONVERT(VARCHAR(150),(CAT.description + ' ' + field_2  )  )
           END AS name,
           CONVERT(DECIMAL(10, 2), PP.price_a) AS unitPrice,
           1 AS minQty,
           1 AS multQty,
           CASE WHEN I.category IN ( 'LS' ) THEN 'LONESTAR' -- 9/30/2016 - per JB request
               WHEN EXISTS (
                           SELECT 1
                           FROM dbo.cvo_part_attributes AS pa
                           WHERE pa.part_no = IA.part_no
                                 AND pa.attribute = 'Pogocam'
                           ) THEN 'POGOTEC'                 -- 9/11/2017
               
               WHEN I.type_code IN ( 'other', 'POP' ) THEN 'POP' ELSE 'CLEARVISION'
           END AS manufacturer,
           I.upc_code AS barcode,
           CASE WHEN I.category IN ( 'revo', 'op' )
                     AND I.type_code IN ( 'other', 'pop' ) THEN CONVERT(VARCHAR(150), I.description) ELSE
                                                                                                         CONVERT(
                                                                                                                    VARCHAR(150),
                                                                                                                    (CAT.description
                                                                                                                     + ' '
                                                                                                                     + IA.field_2
                                                                                                                    )
                                                                                                                )
           END AS longDesc,
           CASE WHEN I.type_code IN ( 'other', 'pop', 'PARTS' ) THEN I.description
               WHEN I.type_code = 'sun' THEN
                   CONVERT(
                              VARCHAR(150),
                              (CAT.description + ' ' + field_2 + ' ' + field_3 + ' '
                               + (ISNULL(CAST(STR(field_17, 2, 0) AS VARCHAR(2)), '') + '/'
                                  + ISNULL(CAST(field_6 AS VARCHAR(2)), '') + '/'
                                  + ISNULL(CAST(field_8 AS VARCHAR(3)), '')
                                 ) + ' ' + ISNULL(field_23, '') -- sun lens color - 1/11/16
                              )
                          ) ELSE
                                CONVERT(
                                           VARCHAR(150),
                                           (CAT.description + ' ' + field_2 + ' ' + field_3 + ' '
                                            + (ISNULL(CAST(STR(field_17, 2, 0) AS VARCHAR(2)), '') + '/'
                                               + ISNULL(CAST(field_6 AS VARCHAR(2)), '') + '/'
                                               + ISNULL(CAST(field_8 AS VARCHAR(3)), '')
                                              )
                                           )
                                       )
           END AS variantdescription,
           '' AS imageURLs,
           CASE WHEN I.part_no = 'OPZSUNSKIT' THEN 'SUN'
               WHEN (
                    @today >= @ME
                    AND I.category = 'me'
                    )
                    OR (
                       @today >= @UN
                       AND I.category = 'UN'
                       ) THEN 'ME SELL-DOWN'           -- 10/6/2016
               WHEN I.category = 'BCBG'
                    AND EXISTS (
                               SELECT 1
                               FROM dbo.cvo_part_attributes AS pa (nolock)
                               WHERE pa.part_no = I.part_no
                                     AND pa.attribute = 'RETAIL'
                               ) THEN 'BCBGR SELLDWN'

               WHEN I.type_code IN ( 'OTHER', 'POP' ) THEN 'POP'
                                                       -- 1/11/2016
               -- WHEN i.category = 'CH' AND ia.FIELD_32 = 'LastChance' THEN 'CHLastChance'
               WHEN I.category = 'CH'
                    AND @today >= @CH THEN 'COLE HAAN' -- 05/26 - CHANGE FROM CH RETURNS TO COLE HAAN FOR LAST, LAST, CHANCE BUYS
               WHEN ISNULL(IA.field_28, @today) >= @today THEN I.type_code

                                                       -- 12/12/14 - sunps takes precedence
               WHEN I.type_code = 'SUN'
                    AND ISNULL(IA.field_28, @today) < @today
                    AND ISNULL(IA.field_36, '') <> 'sunps'
                    AND I.category <> 'REVO' -- 5/4/2017 - SHOW ALL REVOS
                    AND NOT EXISTS (
                                   SELECT 1 FROM @EOS EOS WHERE EOS.part_no = I.part_no
                                   ) THEN 'EORS'
               WHEN dbo.f_cvo_get_part_tl_status(I.part_no, @today) = 'R'
                    AND DATEDIFF(m, ISNULL(IA.field_28, @today), @today) < 9 THEN 'RED'
               WHEN DATEDIFF(m, ISNULL(IA.field_28, @today), @today) >= 24
                    AND I.type_code <> 'SUN' THEN 'EOR'
               WHEN DATEDIFF(m, ISNULL(IA.field_28, @today), @today) >= 9
                    AND I.type_code <> 'SUN' THEN 'QOP'
			   WHEN i.category = 'dd' and i.type_code = 'PARTS' THEN 'FRAME'
			   ELSE I.TYPE_CODE
           END AS [category:1],
           CASE
               -- WHEN ia.field_32 = 'lastchance' THEN '' 
               WHEN I.category = 'BT'
                    AND IA.category_2 LIKE '%ADULT%'
                    AND (
                        RIGHT(I.part_no, 2) = 'f1'
                        OR I.type_code = 'lens'
                        ) THEN 'BLUTECH READERS' -- 12/22/2016

               WHEN I.type_code = 'SUN'
                    AND I.category = 'REVO' THEN 'REVO'
               WHEN I.type_code = 'SUN'
                    AND I.category IN ( 'BCBG', 'SM', 'IZOD', 'IZX' )
                    AND ISNULL(IA.field_36, '') = 'SUNPS'
                    AND NOT EXISTS (
                                   SELECT 1
                                   FROM dbo.cvo_part_attributes AS pa (nolock)
                                   WHERE pa.part_no = IA.part_no
                                         AND pa.attribute = 'retail'
                                   ) THEN 'FASHION'
               WHEN I.type_code = 'sun'
                    --AND (
                    --    (I.category IN ( 'et', 'jmc', 'pt' )
                    --    OR ISNULL(IA.field_36, '') <> 'SUNPS')
                       and EXISTS (
                                  SELECT 1 FROM @EOS EOS WHERE EOS.part_no = I.part_no
                                  )
                         THEN 'SELLDOWN'
               WHEN I.category IN ( 'izod', 'izx' ) THEN 'IZOD' ELSE CAT.description
           END [CATEGORY:2],
           ISNULL(IA.field_3, '') AS Color,
           -- sun lens color for REVO
           CASE WHEN I.type_code = 'sun'
                     AND I.category = 'revo' THEN REPLACE(ISNULL(IA.field_23, 'NoLens'), ' ', '') 
				WHEN I.type_code = 'PARTS' AND I.CATEGORY = 'DD' AND I.PART_NO LIKE 'DDZNB%'
						THEN REPLACE(IA.FIELD_2,'NYLON BAND','')
			ELSE -- use lens color as dimension for revo
           (ISNULL(CAST(STR(IA.field_17, 2, 0) AS VARCHAR(2)), '') + '/' + ISNULL(CAST(IA.field_6 AS VARCHAR(2)), '')
            + '/' + ISNULL(CAST(IA.field_8 AS VARCHAR(3)), '')
           )
           END AS Size,
           '|' AS [|],
           I.category AS COLL,
           IA.field_2 AS Model,
           IA.field_28 AS POMDate,
           IA.field_26 AS ReleaseDate,
           dbo.f_cvo_get_part_tl_status(I.part_no, @today) AS Status,
           /*
-- 6/26/2015 tweak for BTS 2015
CASE WHEN CATEGORY_2 LIKE '%CHILD%' AND i.category <> 'dd' /*AND FIELD_2 NOT IN ('843','844')*/  THEN 'KIDS' 
/*WHEN category_2 NOT LIKE '%child%' AND i.category IN('jc','op') THEN 'Tween'*/
ELSE '' END GENDER, 
*/
           -- 6/28/2016 tweak for BTS 2016
           --CASE WHEN category_2 LIKE '%CHILD%'
           --          AND I.category <> 'dd' /*AND FIELD_2 NOT IN ('843','844')*/
           --     THEN 'BTS'
           -- 6/26/2017 - bts 2017
           CASE WHEN IA.category_2 LIKE '%CHILD%'
                     AND I.category IN ( 'SM', 'OP', 'IZOD', 'BT' ) -- added BT 8/28/17 per PG request (not BTS)
           THEN     'Kids'

               WHEN IA.category_2 NOT LIKE '%child%'
                    AND I.category IN ( 'jc', 'op' )
                    AND IA.field_2 NOT IN ( 'Sundae', 'Smoothie' ) THEN 'Tween' ELSE ''
           END GENDER,
           CASE WHEN IA.field_32 IN ( 'none', 'hvc' ) /*OR ia.field_2 IN ('gelato','popsicle','sherbet')*/
           THEN     '' ELSE ISNULL(IA.field_32, '')
           END AS SpecialtyFit,
           CASE WHEN (apr.sku IS NOT NULL) THEN 'Y' ELSE '' END AS APR,
           CASE WHEN I.category IN ( 'ch', 'ME', 'un' ) THEN '' WHEN IA.field_26 > DATEADD(MONTH, -6, @today) THEN
                                                                    'New' ELSE '' END AS New,
           CASE WHEN IA.field_26 > DATEADD(WEEK, 1, @today)
                     AND ISNULL(IA.field_36, '') IN ( 'SUNPS', 'PreSell' ) THEN IA.field_36 -- 11/8/2017 for presell season
               ELSE ''
           END AS SUNPS,
           CASE WHEN c.part_no IS NULL THEN '' ELSE 'CC' END AS CostCo,
           CASE WHEN ISNULL(IA.field_28, @today) < @today THEN 'POM' ELSE '' END AS POM,
           -- 6/9/2016 for kit items to fake inventory # later
           CASE WHEN ISNULL(IA.field_30, '') = 'Y' THEN 'Kit' ELSE '' END AS Kit,
           0 AS shelfqty,
           CONVERT(INTEGER, ISNULL(invupd.ShelfQty, '999')) ShelfQty2,
           cia.NextPODueDate,
           CONVERT(INTEGER, cia.NextPOOnOrder) nextpoonorder,
           ISNULL(drp.e12_wu, 0) drp_usg,
           CONVERT(INTEGER, ISNULL(cia.qty_avl, 0)) qty_avl,
           CONVERT(INTEGER, CASE WHEN ISNULL(cia.qty_avl, 0) <= ISNULL(drp.e12_wu, 0) THEN 0 ELSE ISNULL(cia.qty_avl, 0) END) AS New_shelfqty
    -- INTO #Data1
    FROM dbo.inv_master (NOLOCK) I
        JOIN dbo.inv_master_add (NOLOCK) IA
            ON IA.part_no = I.part_no
        JOIN dbo.category (NOLOCK) CAT
            ON I.category = CAT.kys
        JOIN dbo.part_price (NOLOCK) PP
            ON I.part_no = PP.part_no
        LEFT OUTER JOIN dbo.cvo_item_avail_vw (NOLOCK) cia
            ON cia.location = @location
               AND cia.part_no = I.part_no
        LEFT OUTER JOIN dbo.cvo_hs_inventory_qtyupd invupd (NOLOCK)
            ON I.part_no = invupd.SKU
        LEFT OUTER JOIN #cc c
            ON c.part_no = I.part_no
        -- 030215 -- get apr info from table
        LEFT OUTER JOIN dbo.cvo_apr_tbl apr (nolock)
            ON apr.sku = I.part_no
               AND @today
               BETWEEN apr.eff_date AND apr.obs_date -- 3/2/2015 tag
        -- 032615 use drp 4 week usage as safety stock
        --LEFT OUTER JOIN DPR_Report drp ( NOLOCK ) ON drp.part_no = I.part_no
        --                                             AND drp.location = @location
        LEFT OUTER JOIN #DRP drp
            ON drp.part_no = I.part_no
    WHERE i.category <> 'sp' -- 6/27/2018
		   AND I.void <> 'V'
          AND I.category NOT IN ( 'CORP', 'FP' )
          AND (
              NOT EXISTS (
                         SELECT 1
                         FROM dbo.cvo_part_attributes AS pa (nolock)
                         WHERE pa.part_no = IA.part_no
                               AND pa.attribute IN ( 'HVC', 'RETAIL', 'COSTCO', 'SpecialOrd', 'btconvert', 'customtmpl' )
                         )
              --( ISNULL(field_32, '') NOT IN ( 'HVC', 'RETAIL', 'COSTCO',
              --								'SpecialOrd', 'btconvert' ) -- 5/12/16 -- added special order for revo custom
              -- 4/26/2016 don't need anymore
              --      OR (category IN ('RR') AND ia.field_2 NOT IN ('Rutgers','Vanderbilt','Wildcat Peak') AND GETDATE() >='12/29/2015')
              --	  ) 
              --  4/26/2016 oh yes we do need this
              OR (
                 I.category IN ( 'RR' )
                 AND @today >= '12/29/2015'
                 ) -- add Lonestar
              OR (
                 I.category IN ( 'un' ) -- 3/13/2017
                 AND I.type_code = 'FRAME'
                 AND @today >= @UN
                 )
			  OR (i.part_no = 'DDZEARKIT' OR I.part_no IN (SELECT PART_NO FROM WHAT_PART WHERE asm_no = 'DDZEARKIT')
				 )
			  OR (i.part_no LIKE 'DDZNB%') -- 5/24/2018 -- DILLI DALLI NYLON BANDS
              OR (
                 EXISTS (
                        SELECT 1
                        FROM dbo.cvo_part_attributes AS pa2 (nolock)
                        WHERE pa2.part_no = I.part_no
                              AND pa2.attribute = 'retaiL'
                        )
                 AND I.category IN ( 'BCBG' )
                 AND cia.ReleaseDate <= @today
                 AND ((
                      cia.qty_avl >= 10
                      AND cia.location = '001'
                      )
                     )
                 )
              )
          AND (
              I.type_code IN ( 'SUN', 'FRAME' )
              OR 'HSPOP' = ISNULL(IA.field_36, '')
              OR I.type_code = 'lens'
                 AND ISNULL(IA.field_2, '') LIKE 'bt reader lens%' -- 12/22/2016
              )
          -- 6/29/2015 - set to 1 day.  was 11.  have no idea why
          -- release date quallifications go here
          AND (
              IA.field_26 <= DATEADD(D, 1, @today)
              OR apr.sku IS NOT NULL
              OR (
                 'hspop' = ISNULL(IA.field_36, '')
                 AND (
                     I.type_code = 'POP'
                     OR I.part_no IN ( 'pogodemoc', 'pogolkit' )
                     ) -- 12/28/2017
                 ) -- include POP regardless of release date as long has HSPOP tag is set - 11/29/2016
              OR I.category = 'LS' -- 9/27/2016
              OR (ISNULL(IA.field_36, '') IN ( 'sunps', 'Presell' )) -- 11/8/2017 for new presell seaason
              OR (
                 IA.field_26 = '4/26/2016'
                 AND I.category <> 'AS'
                 )
              );

    -- vee 2016

    -- select * From #data1 where coll = 'bt'


    CREATE CLUSTERED INDEX idx_data1 ON #Data1 (sku);

    CREATE NONCLUSTERED INDEX idx_new_mastersku
    ON dbo.#Data1 (New)
    INCLUDE (mastersku);


    UPDATE #Data1
    SET name = 'IZOD CLEAR DISPLAY FRAME KIT',
        longDesc = 'IZOD CLEAR DISPLAY FRAME KIT',
        [category:1] = 'FRAME',
        manufacturer = 'CLEARVISION'
    WHERE sku = 'IZCLDISKITA';

    -- 06/26/2015
    UPDATE #Data1
    SET [category:1] = 'FRAME',
        manufacturer = 'CLEARVISION',
        longDesc = variantdescription,
        name = variantdescription,
        Size = '' --, model = 'READER'
    WHERE sku IN ( 'ETREADER', 'izztr90kit', 'bczdisplaykit', 'izodinter', 'opsherbetm', 'ascolo6pckit',
                   'ascolo12pckit', 'ascolo18pckit', 'bcbgslp', 'BTZADULTS', 'BTZKIDS', 'DDZEARKIT'
                 ); -- 9/8/2016

    UPDATE #Data1
    SET [category:1] = 'SUN',
        manufacturer = 'CLEARVISION',
        longDesc = variantdescription,
        name = variantdescription,
        Size = '' --, model = 'READER'
    WHERE sku IN ( 'BTZSUNS' ); -- 9/8/2016 


    UPDATE #Data1
    SET [category:1] = 'SUN',
        manufacturer = 'POGOTEC',
        longDesc = variantdescription,
        name = variantdescription,
        Size = '' --, model = 'READER'
    WHERE sku IN ( 'PTSUN' ); -- 9/12/17

    UPDATE #Data1
    SET [category:1] = 'FRAME',
        manufacturer = 'POGOTEC',
        longDesc = variantdescription,
        name = variantdescription,
        Size = '' --, model = 'READER'
    WHERE sku IN ( 'PTOPTICAL', 'POGOCAM' ); -- 9/12/17

    UPDATE #Data1
    SET longDesc = REPLACE(longDesc, 'PERFORMX ', 'IZOD PERFORMX '),
        name = REPLACE(name, 'PERFORMX ', 'IZOD PERFORMX '),
        variantdescription = REPLACE(variantdescription, 'PERFORMX ', 'IZOD PERFORMX ')
    WHERE COLL IN ( 'izod', 'izx' );

    -- 1/2/2015 - tag - for durahinge
    UPDATE #Data1
    SET longDesc = REPLACE(longDesc, 'durahinge durahinge', 'DURAHINGE'),
        name = REPLACE(name, 'durahinge durahinge', 'DURAHINGE'),
        variantdescription = REPLACE(variantdescription, 'durahinge durahinge', 'DURAHINGE')
    WHERE COLL IN ( 'dh', 'cvo' );

    UPDATE #Data1
    SET longDesc = REPLACE(longDesc, '"', ''),
        name = REPLACE(name, '"', ''),
        variantdescription = REPLACE(variantdescription, '"', '');

    -- FIXUP FOR BT READERS

    UPDATE d
    SET mastersku = mastersku
                    + CASE WHEN [category:1] = 'frame' THEN 'R' WHEN [category:1] = 'lens' THEN RIGHT(sku, 3)ELSE '' END,
        [category:1] = 'FRAME'
    FROM #Data1 d
    WHERE [CATEGORY:2] = 'BLUTECH READERS';


    

    -- PULL ALL SPECS for STYLE together
    IF (OBJECT_ID('tempdb.dbo.#Spec') IS NOT NULL)
        DROP TABLE #Spec;

    SELECT DISTINCT
           mastersku,
           Num,
           Spec
    INTO #Spec
    FROM
    (
    SELECT DISTINCT
           mastersku,
           1 AS Num,
           GENDER AS Spec
    FROM #Data1
    WHERE GENDER <> ''
    UNION ALL
    SELECT DISTINCT
           mastersku,
           2 AS num,
           pa.attribute
    FROM #Data1 d
        JOIN dbo.cvo_part_attributes pa
            ON d.sku = pa.part_no
    WHERE pa.attribute NOT IN ( 'none', 'hvc', '' )
    UNION ALL
    SELECT DISTINCT
           mastersku,
           3 AS Num,
           CASE WHEN APR = 'Y' THEN 'APR' ELSE '' END
    FROM #Data1
    WHERE APR <> ''
          AND SUNPS <> 'sunps'
    UNION ALL
    SELECT DISTINCT
           mastersku,
           4 AS Num,
           New
    FROM #Data1
    WHERE New <> ''
    UNION ALL -- 072814 - add special values list
    SELECT DISTINCT
           #Data1.mastersku,
           5 AS num,
           'SPV'
    FROM #Data1
        JOIN dbo.cvo_spv_tbl s
            ON #Data1.sku = s.sku
    WHERE @today
          BETWEEN s.eff_date AND ISNULL(s.obs_date, @today)
          AND s.mastersku IS NOT NULL
          -- 02/27/2015 - if it's already qop it can't be a spv too
          AND #Data1.[category:1] <> 'QOP'
    UNION ALL
    SELECT DISTINCT
           mastersku,
           5 AS Num,
           SUNPS
    FROM #Data1
    WHERE SUNPS <> ''
    --UNION ALL
    --SELECT DISTINCT
    --       mastersku,
    --       6 AS num,
    --       'Selldown'
    --FROM #Data1 d
    --WHERE [category:1] IN ( 'qop', 'eor' )
    --      AND COLL IN ( 'bcbg', 'et' )
    --      AND NOT EXISTS (
    --                     SELECT 1
    --                     FROM #Data1 dd
    --                     WHERE d.mastersku = dd.mastersku
    --                           AND dd.[category:1] NOT IN ( 'qop', 'eor' )
    --                     )
    --UNION ALL
    --SELECT mastersku, 6 AS num, '1.1' FROM #data1 WHERE ReleaseDate = '11/2/2015' AND COLL = 'AS'
    --UNION ALL
    --select mastersku, 6 as Num, '*D*' from #Data1 where POM <> ''
    ) tmp;

    -- --   select * from #Spec
    IF (OBJECT_ID('tempdb.dbo.#Spec1') IS NOT NULL)
        DROP TABLE dbo.#Spec1;

    WITH C
    AS (SELECT mastersku,
               Num,
               Spec
        FROM #Spec)
    SELECT DISTINCT
           mastersku,
           STUFF((
                 SELECT ' ' + Spec FROM #Spec WHERE mastersku = C.mastersku FOR XML PATH('')
                 ),
                 1,
                 1,
                 ''
                ) AS NEW
    INTO #Spec1
    FROM C;

    CREATE NONCLUSTERED INDEX idx_spec ON #Spec (mastersku);

    CREATE NONCLUSTERED INDEX idx_spec1 ON #Spec1 (mastersku);

    -- -- 
    DELETE FROM #Spec
    WHERE mastersku = '';

    --  select * from #Spec1 where mastersku=''
    DELETE FROM #Spec1
    WHERE mastersku = '';

    -- UPDATES
    UPDATE #Data1
    SET mastersku = 'BCGLIL'
    WHERE sku LIKE 'bcglil%';

    UPDATE #Data1
    SET mastersku = 'BCANGS'
    WHERE sku LIKE 'bcANG_______S';

    --2/25/2016
    UPDATE #Data1
    SET mastersku = mastersku + 'X'
    WHERE mastersku IN ( 'RE4064', 'RE4066' )
          AND POMDate <= '1/1/2010';

    UPDATE #Data1
    SET name = 'OCEAN PACIFIC SUNS KIT',
        longDesc = 'OCEAN PACIFIC SUNS KIT',
        [category:1] = 'SUN',
        manufacturer = 'CLEARVISION'
    WHERE sku = 'OPZSUNSKIT';

    UPDATE #Data1
    SET [category:1] = 'FRAME'
    WHERE sku = 'LONESTARTSO';

    -- SELECT * from dbo.cvo_hs_inventory_8 AS hi WHERE sku = 'lonestartso'


    IF (OBJECT_ID('#Final') IS NOT NULL)
        DROP TABLE #Final;

    SELECT sku,
           CASE WHEN manufacturer = 'POP' THEN '' ELSE mastersku END AS mastersku,
           --ISNULL((select name + ' (' + New + case when pomdate is not null then ' *D)' else ' )' end from #Spec1 t2 
           --	 where t1.mastersku=t2.mastersku),name)  AS name, 
           ISNULL((
                  SELECT name + ' (' + NEW + ')' FROM #Spec1 t2 WHERE t1.mastersku = t2.mastersku
                  ),
                  name
                 ) AS name,
           unitPrice,
           minQty,
           multQty,
           manufacturer,
           barcode,
           --ISNULL((select longDesc + ' (' + New + case when pomdate is not null then ' *D)' else ' )' end  from #Spec1 t2 
           --	where t1.mastersku=t2.mastersku),longDesc) AS  longDesc,
           ISNULL((
                  SELECT longDesc + ' (' + NEW + ')'
                  FROM #Spec1 t2
                  WHERE t1.mastersku = t2.mastersku
                  ),
                  longDesc
                 ) AS longdesc,
           ISNULL((
                  SELECT variantdescription + ' (*D)'
                  FROM inv_master_add ia
                  WHERE ia.part_no = t1.sku
                        AND ISNULL(ia.field_28, @today) < @today
                  ),
                  variantdescription
                 ) AS VariantDescription,
           imageURLs,
           --  updated to add EOS to category:1  EL 062514
           [category:1],
           [CATEGORY:2],
           Color,
           -- Lens_color,
           Size,
           [|],
           COLL,
           Model,
           POMDate,
           ReleaseDate,
           Status,
           -- 6/26/2017 2017 bts program tweeks
           CASE WHEN GENDER IN ( 'kids', 'tween' )
                     AND t1.[category:1] <> 'frame'
                          THEN '' ELSE GENDER
           END AS GENDER,
           SpecialtyFit,
           APR,
           New,
           SUNPS,
           CostCo,
           -- , ShelfQty
           -- 2/4/16 - add izod interchangeable fudge qty for 2/23 release
           CASE WHEN t1.COLL = 'izod'
                     AND t1.Model IN ( '6001', '6002', '6003', '6004' ) THEN t1.qty_avl + ISNULL(t1.NextPOOnOrder, 0)
                                                -- 5/26/16 - SHOW ch QTYS FOR LAST, LAST CHANCE BUYS -- WHEN T1.coll = 'CH' then 0
               -- WHEN t1.COLL = 'CH' THEN 0 -- 9/13/2016 - PUT BACK
               WHEN sku = 'IZODINTER' THEN 2000 -- ISNULL(T1.QTY_AVL,0) + ISNULL(t1.NextPOOnOrder,0)
               WHEN Kit = 'Kit' THEN 2000       -- 6/9/2016 - dummy up inventory for all promo kits
               WHEN t1.APR = 'y'
                    OR t1.SUNPS = 'sunps' /*OR t1.[CATEGORY:2] = 'revo'*/
           THEN    2000                         -- APR and sunps and revo
               WHEN t1.[category:1] IN ( 'spv', 'qop', 'eor' ) THEN ISNULL(t1.qty_avl, 0) ELSE
                                                                                              CASE WHEN t1.qty_avl < t1.drp_usg THEN
                                                                                                       0 ELSE
                                                                                                             ISNULL(
                                                                                                                       t1.qty_avl,
                                                                                                                       0
                                                                                                                   ) END
           END AS ShelfQty,
           NextPODueDate,
           0 AS hide
    INTO #Final
    FROM #Data1 t1
    ORDER BY COLL,
             Model;

    UPDATE #Final
    SET hide = CASE WHEN manufacturer = 'POP' THEN CASE WHEN ISNULL(POMDate, @today) < @today THEN 1 ELSE 0 END
                   WHEN ShelfQty <= 0
                        AND [category:1] IN ( 'EOR', 'EORS' ) THEN 1 ELSE 0
               END
    WHERE manufacturer = 'pop'
          OR ShelfQty <= 0;

    UPDATE #Final
    SET hide = CASE -- 9/2/2016
                   --WHEN (
                   --     COLL = 'bt'
                   --     AND @today < '10/25/2016'
                   --     ) THEN 1                                                     -- don't let BT show up early
                   --WHEN (
                   --     COLL = 'LS'
                   --     AND @today < ReleaseDate
                   --     ) THEN 1                                                     -- 9/27/2016 per JB request
                   --WHEN (
                   --     SpecialtyFit = 'slp'
                   --     AND @today < '10/7/2016'
                   --     ) THEN 1
					--WHEN (
					--    ReleaseDate = '9/27/2016'
					--    AND APR = 'Y'
					--    AND @today
					--    BETWEEN '9/14/2016' AND '9/18/2016'
					--    ) THEN 0
                   --WHEN (
                   --     ReleaseDate = '9/27/2016'
                   --     AND (
                   --         APR = 'Y'
                   --         OR SpecialtyFit = '1.3'
                   --         )
                   --     ) THEN 1
                   WHEN (
                        Model = 'COLORFUL'
                        AND COLL = 'AS'
                        AND @today > '9/23/2016'
                        ) THEN 1
                   --WHEN (
                   --     ReleaseDate = '9/6/2016'
                   --     AND @today < '9/9/2016'
                   --     AND APR <> 'Y'
                   --     ) THEN 1
				   when (longdesc LIKE '%R.I%') and ShelfQty = 0 AND ISNULL(SpecialtyFit,'') NOT IN ('R.I','[MULTIPLE]') THEN 1
                                                                                     -- 9/2/2016
                   WHEN COLL = 'revo'
                        AND ISNULL(POMDate, @today) = '01/01/2010' THEN 1
                   WHEN COLL = 'revo'
                        AND Model IN ( 'Straightshot', 'Bearing', 'Heading' ) THEN 1 -- 2/10/2016
                   -- unhide for 4/26 release WHEN mastersku IN ('iz2014','iz2015','iz2016','iz2017') THEN 1
                   WHEN mastersku IN ( 'IZ6001', 'IZ6002', 'IZ6003', 'IZ6004' )
                        AND @today < '5/16/2016' THEN 1
                                                                                     -- 9/7/2016 WHEN mastersku IN ('iz2026','iz2027') THEN 1 -- new iz t&C kit
                   -- WHEN ReleaseDate > GETDATE() AND sunps IN ('sunps','presell') THEN 1 -- 11/8/2017 for new presell season
                   WHEN [CATEGORY:2] = 'BLUTECH READERS' THEN 1                      -- 2/5/2018
				   WHEN [category:1] = 'BCBGR SELLDWN' AND (@today < '9/25/2018' OR @today >= '10/1/2018') THEN 1 -- VEW 2018
				   -- 8/23/18 - remove revo selldown --
                   -- WHEN [category:1] = 'REVO SELLDWN' AND @revosv > @TODAY THEN 1 -- 042718
				   ELSE 0
               END;

    -- plug for VEW 090816
    UPDATE #Final
    SET hide = 0
    WHERE mastersku = 'ascolo'
          OR sku = 'bcbgslp';

    -- plug for semi-rimless
    --UPDATE #Final
    --SET hide = 1
    --WHERE SpecialtyFit = '1.3'
    --      AND @today < '10/8/2016';

    -- per KB - let them show up end of day Friday.


    -- plug for BCBG Danica, only to go to Centennial and Mexico
    UPDATE #Final
    SET hide = 1
    WHERE (
          Model = 'Danica'
          AND COLL = 'bcbg'
          )
          OR sku IN ( 'BCASTNGRE5718', 'BCAPPEBLS5617' );

    DELETE FROM #Final
    WHERE (
          RIGHT(sku, 2) = 'F1'
          AND [CATEGORY:2] IN ( 'revo', 'aspire', 'blutech' )
          )
          OR sku = 'ascolocustom';

    UPDATE D
    SET D.manufacturer = 'BCBGR SV'
    FROM #FINAL D
    WHERE COLL = 'BCBG' AND CHARINDEX('retail',longdesc) > 0 AND CHARINDEX('ssv',longdesc) > 0;


		   

    IF (OBJECT_ID('dbo.cvo_hs_inventory_8') IS NOT NULL)
    BEGIN
        TRUNCATE TABLE cvo_hs_inventory_8;
    END;
    ELSE
    BEGIN
        CREATE TABLE dbo.cvo_hs_inventory_8
        (
            sku VARCHAR(30) NOT NULL,
            mastersku VARCHAR(150) NULL,
            name NVARCHAR(MAX) NULL,
            unitPrice DECIMAL(10, 2) NULL,
            minQty INT NOT NULL,
            multQty INT NOT NULL,
            Manufacturer VARCHAR(11) NOT NULL,
            barcode VARCHAR(20) NULL,
            longdesc NVARCHAR(MAX) NULL,
            VariantDescription VARCHAR(260) NULL,
            imageURLs VARCHAR(1) NOT NULL,
            [category:1] VARCHAR(12) NULL,
            [category:2] VARCHAR(40) NULL,
            Color VARCHAR(40) NOT NULL,
            --[Lens_color] VARCHAR(40) NOT NULL,
            Size VARCHAR(9) NOT NULL,
            [|] VARCHAR(1) NOT NULL,
            COLL VARCHAR(10) NULL,
            Model VARCHAR(40) NULL,
            POMDate DATETIME NULL,
            ReleaseDate DATETIME NULL,
            Status VARCHAR(1) NULL,
            GENDER VARCHAR(5) NOT NULL,
            SpecialtyFit VARCHAR(40) NOT NULL,
            APR VARCHAR(1) NOT NULL,
            New VARCHAR(3) NOT NULL,
            SUNPS VARCHAR(5) NOT NULL,
            CostCo VARCHAR(2) NOT NULL,
            ShelfQty DECIMAL(38, 8) NOT NULL,
            NextPODueDate DATETIME NULL,
            hide INT NOT NULL,
            MasterHIDE INT NOT NULL
        ) ON [PRIMARY];

        CREATE CLUSTERED INDEX idx_inv_btr
        ON dbo.cvo_hs_inventory_8
        (
        Manufacturer,
        mastersku,
        sku
        );

        CREATE NONCLUSTERED INDEX idx_hs_inv_part_no_btr
        ON dbo.cvo_hs_inventory_8 (sku ASC)
        INCLUDE (mastersku)
        WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF,
              ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
             ) ON [PRIMARY];

        CREATE NONCLUSTERED INDEX IDX_HSINV_COLL
        ON dbo.cvo_hs_inventory_8
        (
        COLL,
        sku
        );

        CREATE NONCLUSTERED INDEX IDX_HSINV_MASTERSKU
        ON dbo.cvo_hs_inventory_8 (mastersku);

    END;

    INSERT INTO dbo.cvo_hs_inventory_8
    (
        sku,
        mastersku,
        name,
        unitPrice,
        minQty,
        multQty,
        Manufacturer,
        barcode,
        longdesc,
        VariantDescription,
        imageURLs,
        [category:1],
        [category:2],
        Color,
        Size,
        [|],
        COLL,
        Model,
        POMDate,
        ReleaseDate,
        Status,
        GENDER,
        SpecialtyFit,
        APR,
        New,
        SUNPS,
        CostCo,
        ShelfQty,
        NextPODueDate,
        hide,
        MasterHIDE
    )
    SELECT t1.sku,
           t1.mastersku,
           t1.name,
           t1.unitPrice,
           t1.minQty,
           t1.multQty,
           t1.manufacturer,
           t1.barcode,
           t1.longdesc,
           t1.VariantDescription,
           t1.imageURLs,
           t1.[category:1],
           t1.[CATEGORY:2],
           t1.Color,
           -- t1.lens_color,
           t1.Size,
           t1.[|],
           t1.COLL,
           t1.Model,
           t1.POMDate,
           t1.ReleaseDate,
           t1.Status,
           t1.GENDER,
           t1.SpecialtyFit,
           t1.APR,
           t1.New,
           t1.SUNPS,
           t1.CostCo,
           CASE WHEN t1.ShelfQty < 0 THEN 0 ELSE t1.ShelfQty END ShelfQty,
           t1.NextPODueDate,
           t1.hide,
           CASE WHEN (
                     SELECT COUNT(*) FROM #Final t2 WHERE t1.mastersku = t2.mastersku
                     ) = (
                         SELECT SUM(hide)
                         FROM #Final t2
                         WHERE t1.mastersku = t2.mastersku
                         GROUP BY mastersku
                         ) THEN 1 ELSE 0
           END AS MasterHIDE
    FROM #Final t1;



    DELETE FROM cvo_hs_inventory_8
    WHERE sku LIKE 'izc%TEMPKIT';

    UPDATE cvo_hs_inventory_8
    SET mastersku = 'MESHE'
    WHERE mastersku = 'MESHEB';

    UPDATE cvo_hs_inventory_8
    SET Size = ''
    WHERE Manufacturer = 'pop'
          OR sku = 'IZCLDISKITA';

    UPDATE cvo_hs_inventory_8
    SET sku = UPPER(sku),
        mastersku = UPPER(mastersku),
        VariantDescription = REPLACE(VariantDescription, '//', ''),
        Size = REPLACE(Size, '//', '');

    -- mixed categories

    -- select distinct [category:1] from cvo_hs_inventory_8
    IF (OBJECT_ID('tempdb.dbo.#cats') IS NOT NULL)
        DROP TABLE dbo.#cats;

    CREATE TABLE #cats
    (
        crank INT,
        category VARCHAR(15)
    );

    INSERT INTO #cats
    VALUES
    (1, 'COLE HAAN');

    INSERT INTO #cats
    VALUES
    (2, 'ME SELL-DOWN');

    INSERT INTO #cats
    VALUES
    (3, 'FRAME');

    INSERT INTO #cats
    VALUES
    (4, 'SUN');

    INSERT INTO #cats
    VALUES
    (5, 'SUN SPECIALS');

    INSERT INTO #cats
    VALUES
    (6, 'EORS');

    INSERT INTO #cats
    VALUES
    (7, 'RED');

    INSERT INTO #cats
    VALUES
    (8, 'QOP');

    INSERT INTO #cats
    VALUES
    (9, 'EOR');

    INSERT INTO #cats
    VALUES
    (99, 'POP');

    WITH cte
    AS (SELECT i8.mastersku,
               MIN(#cats.crank) newcat
        FROM dbo.cvo_hs_inventory_8 i8 (nolock)
            LEFT OUTER JOIN #cats
                ON #cats.category = i8.[category:1]
        WHERE i8.mastersku IN (
                              SELECT mastersku
                              FROM cvo_hs_inventory_8 (nolock)
                              WHERE [category:1] <> 'pop'
                                    AND mastersku <> ''
                              GROUP BY mastersku
                              HAVING COUNT(DISTINCT [category:1]) > 1
                              )
        GROUP BY i8.mastersku
    -- order by i8.mastersku
    )
    UPDATE i
    SET i.[category:1] = (
                         SELECT TOP (1)
                                category
                         FROM #cats
                         WHERE crank = cte.newcat
                         ORDER BY category
                         )
    -- select cte.mastersku, cte.newcat, (select category from #cats where crank = cte.newcat)  
    FROM cte
        INNER JOIN dbo.cvo_hs_inventory_8 i (nolock)
            ON i.mastersku = cte.mastersku;

    /*
SELECT 
sku, mastersku , name, unitprice, minqty, multqty, manufacturer,
barcode, longdesc, variantdescription, imageurls,
[category:1],
[category:2], color, size [|], coll, model, pomdate, releasedate, status, gender,
specialtyfit, apr, new, sunps, costco,  nextpoduedate, hide, masterhide
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

    UPDATE dbo.cvo_hs_inventory_8
    SET name = 'OCEAN PACIFIC SUNS KIT',
        longdesc = 'OCEAN PACIFIC SUNS KIT',
        [category:1] = 'SUN',
        Manufacturer = 'CLEARVISION'
    WHERE sku = 'OPZSUNSKIT';

    -- select * from #Data1

    -- 9/13/16 - put everything in CH RETURNS instead
    -- UPDATE dbo.cvo_hs_inventory_8  SET [category:1] = 'CH LASTCHANCE' 
    --	WHERE [category:1] = 'COLE HAAN' AND ShelfQty > 0

    -- 6/22/17 - OPEN UP LAST CHANCE CATEGORY AGAIN FOR FINAL 4700 FRAMES

    UPDATE hsi
    SET hsi.[category:1] = CASE WHEN (iav.qty_avl + iav.ReserveQty) <= 0 THEN 'CH RETURNS' ELSE 'CH LASTCHANCE' END
    FROM dbo.cvo_hs_inventory_8 hsi
        JOIN dbo.cvo_item_avail_vw AS iav
            ON iav.part_no = hsi.sku
               AND iav.location = '001'
    WHERE hsi.[category:1] = 'COLE HAAN';

    UPDATE dbo.cvo_hs_inventory_8
    SET Manufacturer = 'CLEARVISION',
        [category:2] = 'POP'
    WHERE Manufacturer = 'POP'
          AND [category:1] = 'ME SELL-DOWN';

    -- 5/15/2017 - don't do this any more.  Let unlimited show on its own within me sell-down
    ---- 3/17/17
    --UPDATE dbo.cvo_hs_inventory_8
    --SET [category:2] = 'MARC ECKO', COLL = 'ME'
    --WHERE [category:1] = 'ME SELL-DOWN' AND 
    --([category:2]<> 'MARK ECKO' OR COLL <> 'ME');

    -- 2/10/2017 - show everything to allow for returns
    --UPDATE dbo.cvo_hs_inventory_8
    --SET hide = 1 
    --WHERE ShelfQty <= 0
    --AND [category:1] = 'ME SELL-DOWN';

    IF @today >= @kodi
        UPDATE hsi
        SET [category:1] = 'KODI SELLDWN'
        -- SELECT * 
        FROM dbo.cvo_hs_inventory_8 AS hsi
            JOIN
            (
            SELECT DISTINCT
                   iav.Brand,
                   iav.Style
            FROM dbo.cvo_item_avail_vw AS iav (NOLOCK)
            WHERE iav.location = '001'
                  AND iav.Brand IN ( 'KO', 'DI' )
            GROUP BY iav.Brand,
                     iav.Style
            HAVING SUM(iav.qty_avl) + SUM(iav.ReserveQty) >= 0 -- was 50
            ) selldown
                ON hsi.COLL = selldown.Brand
                   AND hsi.Model = selldown.Style;

    -- me sell_down is over ... reclass everytHing to ME RETURNS -- 7/5/2017
    UPDATE hsi
    SET hsi.[category:1] = 'ME RETURNS'
    FROM dbo.cvo_hs_inventory_8 AS hsi
    WHERE [category:1] = 'ME SELL-DOWN';

    --  8/23/18 - remove revo selldown --
    -- 8/29 - SET UP REVO SPECIAL VALUES
    IF @revosv <= GETDATE() 
    begin
	    UPDATE f SET [category:1] = 'REVO S.VALU',
	    mastersku = mastersku+'SV',
	    hide = 0, f.MasterHIDE = 0
	    -- SELECT *
	    FROM dbo.cvo_hs_inventory_8  AS f
	    WHERE f.coll = 'revo'
	    AND f.SpecialtyFit = 'SSV'
	    AND [category:1] <> 'REVO S.VALU';
    END;

	UPDATE f SET NAME = REPLACE(NAME,'(SSV)',''), f.longdesc = REPLACE(longdesc,'(SSV)','')
	-- SELECT *
	FROM dbo.cvo_hs_inventory_8  AS f
	WHERE f.coll = 'revo'
    AND (name LIKE '%SSV%' OR longdesc LIKE '%SSV%');

	--AND f.SpecialtyFit <> 'RevoSldwn'
	--AND [category:1] <> 'REVO SELLDWN';

	UPDATE hsi
        SET [category:1] = 'KIDS SELLDWN'
        -- SELECT * 
        FROM dbo.cvo_hs_inventory_8 AS hsi
            WHERE EXISTS (SELECT 1 FROM dbo.cvo_part_attributes AS pa WHERE pa.part_no = hsi.sku AND pa.attribute = 'KidsSldwn');


END;

















GO

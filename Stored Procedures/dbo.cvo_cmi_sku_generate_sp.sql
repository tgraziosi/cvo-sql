
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_cmi_sku_generate_sp]
	 ( @coll VARCHAR(12), 
	   @model VARCHAR(40) ,
	   @colorname VARCHAR(40) = NULL,
	   @eye_size DECIMAL(20,8) = NULL,
	   @release_date DATETIME,
	   @upd CHAR(1)
	   ,@debug INT = 0 )
AS

BEGIN

-- author:tine graziosi
-- 2015
-- generate sku's from cmi into epicor
--  
-- 
-- exec [cvo_cmi_sku_generate_sp] 'BT', 'eye-density', null, null, '04/26/2016','N', 1

SET XACT_ABORT, NOCOUNT ON;

DECLARE
	@ovhd_pct DECIMAL(20,8),
	@util_cost DECIMAL(20,8),
	@demolen_cost DECIMAL(20,2),
	@pattern_cost DECIMAL(20,2), 
	@pattern_vendor VARCHAR(10)
	
-- SELECT  @coll = 'bt' , @model = 'eye-density', @colorname = null, @eye_size = null, @upd = 'n', @release_date = '04/26/2016'

-- check with accounting/product for periodic changes

SELECT @ovhd_pct = .0721, @util_cost = 0.21, @demolen_cost = .25, @pattern_cost = 0.28, @pattern_vendor = 'MOTIF0'


IF ( OBJECT_ID('tempdb.dbo.#cmi') IS NOT NULL ) DROP TABLE #cmi;

SELECT part_no ,
       cmi_model_id ,
       Collection ,
       CollectionName ,
       UPPER(model) model ,
       short_model ,
       PrimaryDemographic ,
       target_age ,
       eye_shape ,
       RES_type ,
       case_part ,
       frame_category ,
       front_material ,
       temple_material ,
       nose_pads ,
       hinge_type ,
       release_date ,
       prim_img ,
       ColorGroupCode ,
       UPPER(ColorName) colorname ,
       specialty_fit ,
       web_saleable_flag ,
       eye_size ,
       a_size ,
       b_size ,
       ed_size ,
       dbl_size ,
       temple_size ,
       dim_unit ,
       temple_tip_material ,
       suns_only ,
       lens_base ,
       front_price ,
       temple_price ,
       wholesale_price ,
       retail_price ,
	   cmi.frame_price, -- 2/22/16
       progressive_type ,
       component_1 ,
       component_2 ,
       component_3 ,
       spare_temple_length ,
       asterisk_1 ,
       asterisk_2 ,
       asterisk_3 ,
       varImported ,
       varImportDate ,
       variant_release_date ,
       model_id ,
       variant_id ,
       dim_id ,
       wsht_id ,
       clips_available ,
       ispolarizedavailable ,
       supplier ,
       country_origin ,
       frame_cost ,
       front_cost ,
       temple_cost ,
       cost_currency ,
       single_cable_cost ,
       ws_ship1_qty ,
       ws_ship2_qty ,
       ws_ship3_qty ,
       img_34 ,
       img_temple ,
       img_front ,
       img_sku ,
       print_flag ,
       upc_code ,
       date_added ,
       dim_release_date ,
       model_lead_time ,
       lens_color,
	   short_color_name = CASE WHEN LEFT(cmi.ColorName,3) = 'GRE' THEN -- handle the GREY/GREEN dilemma
			 CASE when cmi.ColorGroupCode = 'GRY' THEN 'GRE' -- Grey
				  WHEN cmi.colorgroupcode = 'GRN' THEN 'GRN' 
				  ELSE LEFT(colorname,3) END
		    ELSE LEFT(colorname,3) end -- 1/26/2016	 
	  , ISNULL(cmi.frame_only,0) frame_only
	  , cmi.dim_lens_cost

INTO #cmi
-- FROM [cvo-db-03].cvo.dbo.cvo_cmi_catalog_view cmi
FROM dbo.cvo_cmi_catalog_view cmi
WHERE cmi.model = @model AND cmi.collection = @coll

IF ( OBJECT_ID('tempdb.dbo.#short_model_name') IS NOT NULL )
    DROP TABLE #short_model_name;

SELECT DISTINCT
        Collection ,
        model ,
        UPPER(LEFT(model, 4)) short_model_calc ,
        UPPER(short_model) short_model ,
        0 AS ok

INTO    #short_model_name
FROM    #cmi
WHERE   Collection = @coll
        AND model = @model
		AND ISNULL(dim_release_date, ISNULL(release_date,'1/1/1900')) <= @release_date;

UPDATE  smn
SET     short_model = CASE WHEN ISNULL(smn.short_model, '') = ''
                           THEN smn.short_model_calc
                           ELSE smn.short_model
                      END
FROM    #short_model_name smn;

IF ( OBJECT_ID('tempdb.dbo.#cvo_cmi_sku_xref') IS NOT NULL )
    DROP TABLE #cvo_cmi_sku_xref;

	CREATE TABLE #cvo_cmi_sku_xref
	( dim_id INT,
	  part_no VARCHAR(30) null,
	  upc_code VARCHAR(20) NULL,
	  collection VARCHAR(12),
	  model VARCHAR(40),
	  colorname VARCHAR(40) NULL ,
      eye_size DECIMAL(20, 8) NULL 
	  )
	  

	  INSERT #cvo_cmi_sku_xref (dim_id, collection, model, colorname, eye_size)
	  select DISTINCT dim_id, Collection, model, ColorName, eye_size
	  FROM    #cmi
		WHERE   Collection = @coll
        AND model = @model
		AND colorname = @colorname
		AND eye_size = @eye_size
		AND ISNULL(dim_release_date, ISNULL(release_date,'1/1/1900')) <= @release_date;

IF ( OBJECT_ID('tempdb.dbo.#parts_list') IS NOT NULL )
    DROP TABLE #parts_list;
CREATE TABLE #parts_list
    (
      id INT IDENTITY(1, 1) ,
      collection VARCHAR(30) ,
      model VARCHAR(40) ,
      short_model VARCHAR(5) ,
      colorname VARCHAR(40) NULL ,
      eye_size DECIMAL(20, 8) NULL ,
      temple_size DECIMAL(18, 1) NULL ,
      part_type VARCHAR(15) ,
      part_no VARCHAR(30)
    );

INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                NULL ,
                0 ,
                NULL ,
                'BRUIT' ,
                CASE WHEN c.collection = 'izx' THEN 'IZX' ELSE UPPER(LEFT(c.Collection, 2)) END + RTRIM(smn.short_model)
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
        WHERE   1 = 1
                AND smn.Collection = @coll
                AND smn.model = @model;

INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                NULL ,
                0 ,
                NULL ,
                'PATTERN' ,
                CASE WHEN c.collection = 'izx' THEN 'IZX' ELSE UPPER(LEFT(c.Collection, 2)) END + RTRIM(smn.short_model) + 'P'
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
        WHERE   1 = 1;

INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                upper(c.colorname) colorname ,
                c.eye_size ,
                c.temple_size ,
                'FRAME' ,
                UPPER(
				CASE WHEN c.collection = 'izx' THEN 'IZX' ELSE UPPER(LEFT(c.Collection, 2)) END + RTRIM(smn.short_model)
                + ISNULL(short_color_name, 'ccc')
                + CAST(c.eye_size AS VARCHAR(2))
                + CAST(c.dbl_size AS VARCHAR(2))
				)
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
		WHERE   1 = 1
				AND c.colorname = ISNULL(@colorname,c.colorname)
				AND c.eye_size = ISNULL(@eye_size, c.eye_size);

-- Frame only - 2/10/2016

INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                upper(c.colorname) colorname ,
                c.eye_size ,
                c.temple_size ,
                'FRAME ONLY' ,
                UPPER(
				CASE WHEN c.collection = 'izx' THEN 'IZX' ELSE UPPER(LEFT(c.Collection, 2)) END + RTRIM(smn.short_model)
                + ISNULL(short_color_name, 'ccc')
                + CAST(c.eye_size AS VARCHAR(2))
                + CAST(c.dbl_size AS VARCHAR(2))
				+ 'F1'
				)
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
		WHERE   1 = 1
				AND c.colorname = ISNULL(@colorname,c.colorname)
				AND c.eye_size = ISNULL(@eye_size, c.eye_size)
				AND C.frame_only = 1;


INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                upper(c.colorname) colorname ,
                c.eye_size ,
                NULL ,
                'FRONT' ,
                UPPER(
				CASE WHEN c.collection = 'izx' THEN 'IZX' ELSE UPPER(LEFT(c.Collection, 2)) END + RTRIM(smn.short_model)
                + ISNULL(short_color_name, 'ccc') + 'F'
                + CAST(c.eye_size AS VARCHAR(2))
				)
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
        WHERE   1 = 1
				AND c.colorname = ISNULL(@colorname,c.colorname)
				AND c.eye_size = ISNULL(@eye_size, c.eye_size);

-- Demolens for Frames
INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                 NULL ,
                c.eye_size ,
                NULL ,
                'DEMOLEN' ,
                CASE WHEN c.collection = 'izx' THEN 'IZX' ELSE UPPER(LEFT(c.Collection, 2)) END + RTRIM(smn.short_model) + 'DEM'
                + CAST(c.eye_size AS VARCHAR(2))
				
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
        WHERE   1 = 1
                AND c.RES_type IN ('frame');

-- DEMOLENS for Suns
INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                upper(c.colorname) colorname ,
                c.eye_size ,
                NULL ,
                'DEMOLEN' ,
                CASE WHEN c.collection = 'izx' THEN 'IZX' ELSE UPPER(LEFT(c.Collection, 2)) END + RTRIM(smn.short_model)
                + 'SUN' + ISNULL(short_color_name, 'ccc') 
                + CAST(c.eye_size AS VARCHAR(2))
				
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
        WHERE   1 = 1
				AND c.colorname = ISNULL(@colorname,c.colorname)
				AND c.eye_size = ISNULL(@eye_size, c.eye_size)
				AND C.RES_type = 'SUN';


INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                upper(c.colorname) colorname ,
                0 ,
                CAST(c.temple_size AS DECIMAL(18,1)) ,
                'TEMPLE-L' ,
				CASE WHEN c.collection = 'izx' THEN 'IZX' ELSE UPPER(LEFT(c.Collection, 2)) END + RTRIM(smn.short_model)
                + ISNULL(short_color_name, 'ccc') + 'LS'
                + CAST(CAST(c.temple_size AS INT) AS VARCHAR(3))
				
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
        WHERE   1 = 1
				AND c.colorname = ISNULL(@colorname,c.colorname)
				AND c.eye_size = ISNULL(@eye_size, c.eye_size)
                AND CHARINDEX('cable', c.hinge_type) = 0;

INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                upper(c.colorname) colorname ,
                0 ,
                c.temple_size ,
                'TEMPLE-R' ,
                CASE WHEN c.collection = 'izx' THEN 'IZX' ELSE UPPER(LEFT(c.Collection, 2)) END + RTRIM(smn.short_model)
                + ISNULL(short_color_name, 'ccc') + 'RS'
                + CAST(CAST(c.temple_size AS INT) AS VARCHAR(3))
				
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
        WHERE   1 = 1
				AND c.colorname = ISNULL(@colorname,c.colorname)
				AND c.eye_size = ISNULL(@eye_size, c.eye_size)
                AND CHARINDEX('cable', c.hinge_type) = 0;

/* Cant do this yet - 1/26/2016

INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                upper(c.colorname) colorname ,
                0 ,
                c.temple_size ,
                'TEMPLE-TIP' ,
                UPPER(
				LEFT(c.Collection, 2) + RTRIM(smn.short_model)
                + ISNULL(short_color_name, 'ccc') + 'TT'
                + CAST(c.eye_size AS VARCHAR(2))
				)
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
        WHERE   1 = 1
				AND c.colorname = ISNULL(@colorname,c.colorname)
				AND c.eye_size = ISNULL(@eye_size, c.eye_size)
                AND ISNULL(c.temple_tip_material, '') > ''; 
*/

INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                upper(c.colorname) colorname ,
                0 ,
                c.temple_size ,
                'CABLE-L' ,
				CASE WHEN c.collection = 'izx' THEN 'IZX' ELSE UPPER(LEFT(c.Collection, 2)) END + RTRIM(smn.short_model)
                + ISNULL(short_color_name, 'ccc') + 'LC'
                + CAST(CAST(c.temple_size AS INT) AS VARCHAR(3))
				
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
        WHERE   1 = 1
				AND c.colorname = ISNULL(@colorname,c.colorname)
				AND c.eye_size = ISNULL(@eye_size, c.eye_size)
                 AND CHARINDEX('cable', c.hinge_type) <> 0; 

INSERT  INTO #parts_list
        ( collection ,
          model ,
          short_model ,
          colorname ,
          eye_size ,
          temple_size ,
          part_type ,
          part_no
        )
        SELECT DISTINCT
                UPPER(c.Collection) collection ,
                UPPER(c.model) model ,
                UPPER(smn.short_model) short_model ,
                upper(c.colorname) colorname ,
                0 ,
                c.temple_size ,
                'CABLE-R' ,
				UPPER(
                CASE WHEN c.collection = 'izx' THEN 'IZX' ELSE UPPER(LEFT(c.Collection, 2)) END + RTRIM(smn.short_model)
                + ISNULL(short_color_name, 'ccc') + 'RC'
                + CAST(CAST(c.temple_size AS INT) AS VARCHAR(3))
				)
        FROM    #cmi c
                INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                                    AND smn.model = c.model
        WHERE   1 = 1
				AND c.colorname = ISNULL(@colorname,c.colorname)
				AND c.eye_size = ISNULL(@eye_size, c.eye_size)
                AND CHARINDEX('cable', c.hinge_type) <> 0;

IF ( OBJECT_ID('tempdb.dbo.#err_list') IS NOT NULL )
    DROP TABLE #err_list;
CREATE TABLE #err_list
    (
	  collection VARCHAR(12),
	  model VARCHAR(40),
      part_no VARCHAR(30) ,
      part_type VARCHAR(20) ,
      bad_data VARCHAR(80) ,
      error_desc VARCHAR(80)
    );

INSERT  INTO #err_list
        SELECT  pl.collection,
				model,
				part_no ,
                part_type ,
                part_no ,
                'part already exists in inv_master'
        FROM    #parts_list pl
        WHERE   EXISTS ( SELECT 1
                         FROM   dbo.inv_master i ( NOLOCK )
                         WHERE  i.part_no = pl.part_no );

INSERT  INTO #err_list
        SELECT  pl.collection,
				pl.model,
				part_no ,
                part_type ,
                part_no ,
                'part already exists in inv_master_add'
        FROM    #parts_list pl
        WHERE   EXISTS ( SELECT 1
                         FROM   dbo.inv_master_add i ( NOLOCK )
                         WHERE  i.part_no = pl.part_no );

--IF @debug = 1
--begin
-- select * from #err_list
-- select * From #parts_list
--END


IF ( OBJECT_ID('tempdb.dbo.#parts_to_add') IS NOT NULL )
    DROP TABLE #parts_to_add;

SELECT DISTINCT
        collection = CAST(c.Collection AS VARCHAR(30)) ,
        c.model ,
        smn.short_model ,
        part_type = CAST(pl.part_type AS VARCHAR(15)),
        part_no = CAST(pl.part_no AS VARCHAR(30)) ,
        PrimaryDemographic =  CAST(c.PrimaryDemographic AS VARCHAR(15)) ,
        target_age = CAST(c.target_age AS varchar(15)),
        c.eye_shape ,
        res_type = CASE WHEN pl.part_type IN ( 'bruit', 'pattern' )
                        THEN pl.part_type
                        ELSE c.[RES_type]
                   END ,
        case_part  = CAST(CASE WHEN pl.part_type IN ( 'frame', 'frame only', 'bruit' ) THEN [case_part] ELSE null END AS VARCHAR(80) ),
        frame_category = CASE WHEN pl.part_type IN ( 'frame', 'frame only', 'bruit', 'front' ) THEN [frame_category] ELSE null END ,
        frame_material = CASE WHEN pl.part_type IN ( 'frame', 'frame only', 'bruit', 'front' ) THEN [front_material] ELSE null END ,
        temple_material = CASE WHEN pl.part_type IN ( 'frame', 'frame only','bruit', 'temple-l', 'temple-r', 'cable-l', 'cable-r' ) THEN [temple_material] ELSE null end ,
        nose_pads = CASE WHEN pl.part_type IN ( 'frame', 'frame only', 'bruit', 'front' ) THEN [nose_pads] ELSE null END,
		hinge_type = CASE WHEN pl.part_type NOT IN ( 'pattern', 'front', 'frame only', 'demolen' ) THEN [hinge_type] ELSE NULL END ,
        release_date = ISNULL(c.dim_release_date, ISNULL(release_date,'1/1/1900')),
		colorgroupcode = CAST(CASE WHEN pl.part_type NOT IN ( 'bruit', 'pattern', 'demolen' ) THEN [ColorGroupCode] ELSE null END AS varchar(15)) ,
        colorname = CASE WHEN pl.part_type NOT IN ( 'bruit', 'pattern', 'demolen' ) THEN c.ColorName ELSE NULL end ,
        specialty_fit = CASE WHEN pl.part_type NOT IN ('bruit','pattern','demolen') THEN c.specialty_fit ELSE NULL end ,
        web_saleable_Flag = CASE WHEN pl.part_type IN ( 'frame' , 'frame only') THEN [web_saleable_flag] END ,
        eye_size = CASE WHEN pl.part_type IN ( 'frame', 'frame only', 'front', 'demolen' ) THEN c.[eye_size] ELSE NULL END ,
        a_size = CASE WHEN pl.part_type IN ( 'frame', 'frame only', 'front', 'demolen' ) THEN c.a_size ELSE NULL END ,
        b_size = CASE WHEN pl.part_type IN ( 'frame', 'frame only', 'front', 'demolen' ) THEN c.b_size ELSE NULL END , 
        ed_size = CASE WHEN pl.part_type IN ( 'frame', 'frame only', 'front', 'demolen' ) THEN c.ed_size ELSE NULL END ,
        dbl_size = CASE WHEN pl.part_type IN ( 'frame', 'frame only', 'front', 'demolen' ) THEN c.dbl_size ELSE NULL END ,
        temple_size =   
			CASE WHEN pl.part_type IN ( 'frame', 'frame only', 'temple-l', 'temple-r', 'cable-r', 'cable-l' ) 
			THEN c.temple_size
			ELSE NULL END ,
  --     
		temple_tip_material = CASE WHEN pl.part_type IN ( 'frame', 'frame only', 'temple-l', 'temple-r', 'cable-r', 'cable-l' ) THEN c.temple_tip_material ELSE NULL END ,
        suns_only = CASE WHEN pl.part_type IN ( 'frame', 'bruit', 'front' ) THEN suns_only ELSE NULL END ,
        isnull([front_price],0) front_price ,
        isnull([temple_price],0) temple_price ,
        isnull([wholesale_price],0) wholesale_price ,
        isnull([retail_price],0) retail_price ,
		ISNULL(FRAME_price,0) frame_price,
        [progressive_type] ,
        [component_1] ,
        [component_2] ,
        [component_3] ,
        [spare_temple_length] ,
        [asterisk_1] ,
        [asterisk_2] ,
        [asterisk_3] ,
        clips_available ,
        ispolarizedavailable ,
        c.supplier,
        country_origin ,
        isnull(frame_cost,0) frame_cost ,
        isnull(front_cost,0) front_cost ,
        isnull(temple_cost,0) temple_cost,
		ISNULL(c.dim_lens_cost,0) lens_cost
		, lens_color = CASE WHEN pl.part_type IN ('frame','front','demolen') THEN c.lens_color ELSE NULL END
		, lens_base = CASE WHEN pl.part_type IN ('frame','front','demolen') THEN c.lens_base ELSE NULL END
		, model_lead_time lead_time
INTO    #parts_to_add
FROM    #parts_list pl
        INNER JOIN #cmi c ON c.Collection = pl.collection
            AND pl.model = c.model
            AND c.ColorName = ISNULL(pl.colorname, c.ColorName)
            AND c.eye_size = CASE
				WHEN pl.eye_size = 0
				THEN c.eye_size
				ELSE ISNULL(pl.eye_size, c.eye_size)
				END
            AND c.temple_size = ISNULL(pl.temple_size,c.temple_size)
        INNER JOIN #short_model_name smn ON smn.Collection = c.Collection
                                            AND smn.model = c.model
WHERE   1 = 1
        --AND NOT EXISTS ( SELECT 1
        --                 FROM   #err_list
        --                 WHERE  part_no = pl.part_no );


--IF @debug = 1  SELECT * FROM #parts_to_add

-- More Validations

INSERT  INTO #err_list
        SELECT  pl.Collection,
				pl.model,
				part_no ,
                part_type ,
                frame_material ,
                'frame material missing'
        FROM    #parts_to_add pl
        WHERE   pl.part_type IN ( 'frame', 'bruit', 'front', 'frame only' )
		AND NOT EXISTS ( SELECT TOP 1 kys FROM     dbo.CVO_frame_matl
                                       WHERE    description = ISNULL(pl.frame_material,'') AND ISNULL(void,'N') = 'N')

INSERT  INTO #err_list
        SELECT  pl.Collection,
				pl.model,
				part_no ,
                part_type ,
                frame_price ,
                'frame only price missing'
        FROM    #parts_to_add pl
        WHERE   pl.part_type IN ( 'frame only' ) AND ISNULL(pl.frame_price,0) = 0

INSERT  INTO #err_list
        SELECT  pl.Collection,
				pl.model,
				part_no ,
                part_type ,
                pl.wholesale_price ,
                'wholesale price missing'
        FROM    #parts_to_add pl
        WHERE   pl.part_type IN ( 'frame' ) AND ISNULL(pl.wholesale_price,0) = 0

-- inv_master_add

IF ( OBJECT_ID('tempdb.dbo.#ia') IS NOT NULL )
    DROP TABLE #ia;

CREATE TABLE #ia
    (
      [part_no] [VARCHAR](30) NOT NULL ,
      [category_1] [VARCHAR](15) NULL
                                 DEFAULT NULL , -- watch
      [category_2] [VARCHAR](15) NULL , -- gender
      [category_3] [VARCHAR](15) NULL
                                 DEFAULT '' , -- part_type
      [category_4] [VARCHAR](15) NULL
                                 DEFAULT '' , -- target age
      [category_5] [VARCHAR](15) NULL , -- color group code
      [datetime_1] [DATETIME] NULL , -- disco date (not used)
      [datetime_2] [DATETIME] NULL
                              DEFAULT NULL , -- backorder date
      [field_1] [VARCHAR](40) NULL
                              DEFAULT '' , -- case part no
      [field_2] [VARCHAR](40) NULL , -- model
      [field_3] [VARCHAR](40) NULL , -- color description
      [field_4] [VARCHAR](40) NULL
                              DEFAULT '' , -- pattern part #
      [field_5] [VARCHAR](40) NULL
                              DEFAULT 'N' , -- polarized avail
      [field_6] [VARCHAR](40) NULL , -- bridge size
      [field_7] [VARCHAR](40) NULL , -- nose pad
      [field_8] [VARCHAR](40) NULL , -- temple length
      [field_9] [VARCHAR](40) NULL , -- overall temple length
      [field_10] [VARCHAR](40) NULL , -- frame material
      [field_11] [VARCHAR](40) NULL , -- frame type 
      [field_12] [VARCHAR](40) NULL , -- temple material
      [field_13] [VARCHAR](40) NULL , -- hinge type
      [field_14] [VARCHAR](255) NULL , -- not used
      [field_15] [VARCHAR](255) NULL , -- not used
      [field_16] [VARCHAR](255) NULL , -- not used
      [long_descr] [TEXT] NULL ,

      [field_17] [DECIMAL](20, 8) NULL
                                  DEFAULT 0 , -- eye size
      [field_18] [VARCHAR](1) NULL
                              DEFAULT 'N' , -- not used
      [field_19] [DECIMAL](20, 8) NULL
                                  DEFAULT 0 , -- a size
      [field_20] [DECIMAL](20, 8) NULL
                                  DEFAULT 0 , -- b size
      [field_21] [DECIMAL](20, 8) NULL
                                  DEFAULT 0 , -- ed size
      [field_22] [VARCHAR](32) NULL
                               DEFAULT 'N' , -- clips available
      [field_23] [VARCHAR](20) NULL , -- lens color (suns)
      [field_24] [VARCHAR](20) NULL , -- lens material (suns)
      [field_25] [VARCHAR](20) NULL , -- lens type (suns)
      [field_26] [DATETIME] NULL , -- release date
      [field_27] [VARCHAR](1) NULL
                              DEFAULT 'N' , -- royalty rate applies (not used)
      [field_28] [DATETIME] NULL , -- pom date
      [field_29] [DATETIME] NULL ,  -- not used
      [field_30] [VARCHAR](40) NULL
                               DEFAULT 'N' , -- not used
      [field_31] [VARCHAR](40) NULL , -- tip length
      [field_32] [VARCHAR](40) NULL
                               DEFAULT NULL , -- specialty fit
      [field_33] [VARCHAR](40) NULL , -- not used
      [field_34] [VARCHAR](40) NULL , -- not used
      [field_35] [VARCHAR](40) NULL
                               DEFAULT 'CMI' , -- IT attribute
      [field_36] [VARCHAR](40) NULL , -- not used
      [field_37] [VARCHAR](40) NULL , -- not used
      [field_38] [VARCHAR](255) NULL , -- not used
      [field_39] [VARCHAR](255) NULL , -- not used 
      [field_40] [VARCHAR](255) NULL , -- not used
      [field_18_a] [VARCHAR](40) NULL
                                 DEFAULT 'N' , -- not used
      [field_18_b] [VARCHAR](40) NULL
                                 DEFAULT 'N' , -- not used
      [field_18_c] [VARCHAR](40) NULL
                                 DEFAULT 'N' , -- not used
      [field_18_d] [VARCHAR](40) NULL
                                 DEFAULT 'N' , -- not used
      [field_18_e] [VARCHAR](40) NULL
                                 DEFAULT 'N' -- not used
    );

	CREATE UNIQUE CLUSTERED INDEX idx_ia ON #ia (part_no) WITH  IGNORE_DUP_KEY

-- inv_master
IF ( OBJECT_ID('tempdb.dbo.#i') IS NOT NULL ) DROP TABLE #i;

CREATE TABLE #i
    (
      [part_no] [VARCHAR](30) NOT NULL ,
      [upc_code] [VARCHAR](20) NULL ,
      [sku_no] [VARCHAR](30) NULL ,
      [description] [VARCHAR](255) NULL ,
      [vendor] [VARCHAR](12) NULL ,
      [category] [VARCHAR](10) NULL ,
      [type_code] [VARCHAR](10) NULL ,
      [status] [CHAR](1) NULL
                         DEFAULT 'P' ,
      [cubic_feet] [DECIMAL](20, 8) NOT NULL
                                    DEFAULT 1 ,
      [weight_ea] DECIMAL(20, 8) NOT NULL
                                 DEFAULT 0 ,
      [labor] [DECIMAL](20, 8) NOT NULL
                               DEFAULT 0 ,
      [uom] [CHAR](2) NOT NULL
                      DEFAULT 'EA' ,
      [account] [VARCHAR](32) NULL ,
      [comm_type] [VARCHAR](10) NULL
                                DEFAULT 'NONE' ,
      [void] [CHAR](1) NULL
                       DEFAULT 'N' ,
      [void_who] [VARCHAR](20) NULL ,
      [void_date] [DATETIME] NULL ,
      [entered_who] [VARCHAR](20) NULL
                                  DEFAULT 'CMI' ,
      [entered_date] [DATETIME] NULL
                                DEFAULT GETDATE() ,
      [std_cost] [DECIMAL](20, 8) NULL
                                  DEFAULT 0 ,
      [utility_cost] [DECIMAL](20, 8) NULL
                                      DEFAULT 0 ,
      [qc_flag] [CHAR](1) NULL
                          DEFAULT 'N' ,
      [lb_tracking] [CHAR](1) NULL
                              DEFAULT 'Y' ,
      [rpt_uom] [CHAR](2) NULL
                          DEFAULT 'EA' ,
      [freight_unit] [DECIMAL](20, 8) NULL
                                      DEFAULT 0 ,
      [taxable] [INT] NULL
                      DEFAULT 1 ,
      [freight_class] [VARCHAR](10) NULL ,
      [conv_factor] [DECIMAL](20, 8) NULL
                                     DEFAULT 1.0 ,
      [note] [VARCHAR](255) NULL ,
      [cycle_type] [VARCHAR](10) NULL
                                 DEFAULT 'MONTHLY' ,
      [inv_cost_method] [CHAR](1) NULL
                                  DEFAULT 'S' ,
      [buyer] [VARCHAR](10) NULL ,
      [cfg_flag] [CHAR](1) NULL
                           DEFAULT 'N' ,
      [allow_fractions] [SMALLINT] NULL
                                   DEFAULT 0 ,
      [tax_code] [VARCHAR](10) NULL
                               DEFAULT 'EXEMPT' ,
      [obsolete] [SMALLINT] NULL
                            DEFAULT 0 ,
      [serial_flag] [SMALLINT] NULL
                               DEFAULT 0 ,
      [web_saleable_flag] [CHAR](1) NOT NULL
                                    DEFAULT 'N' ,
      [reg_prod] [CHAR](1) NOT NULL
                           DEFAULT 0 ,
      [warranty_length] [INT] NULL ,
      [call_limit] [INT] NULL ,
      [yield_pct] [DECIMAL](5, 2) NULL
                                  DEFAULT 100.00 ,
      [tolerance_cd] [VARCHAR](10) NULL
                                   DEFAULT 'STD' ,
      [pur_prod_flag] [CHAR](1) NOT NULL
                                DEFAULT 'Y' ,
      [sales_order_hold_flag] [INT] NOT NULL
                                    DEFAULT 0 ,
      [abc_code] [CHAR](1) NULL ,
      [abc_code_frozen_flag] [INT] NOT NULL
                                   DEFAULT 0 ,
      [country_code] [VARCHAR](3) NULL ,
      [cmdty_code] [VARCHAR](8) NULL ,
      [height] [DECIMAL](20, 8) NOT NULL
                                DEFAULT 0 ,
      [width] [DECIMAL](20, 8) NOT NULL
                               DEFAULT 0 ,
      [length] [DECIMAL](20, 8) NOT NULL
                                DEFAULT 0 ,
      [min_profit_perc] [SMALLINT] NULL
                                   DEFAULT 0 ,
      [sku_code] [VARCHAR](16) NULL ,
      [eprocurement_flag] [INT] NULL
                                DEFAULT 0 ,
      [non_sellable_flag] [CHAR](1) NULL
                                    DEFAULT 'N' ,
      [so_qty_increment] [DECIMAL](20, 8) NULL
                                          DEFAULT 1.0
	  , lead_time int DEFAULT 0 -- for inv_list
    );

-- cvo inv master add

IF ( OBJECT_ID('tempdb.dbo.#cia') IS NOT NULL )
    DROP TABLE #cia;

CREATE TABLE #cia
    (
      [part_no] [VARCHAR](30) NOT NULL ,
	  eye_shape VARCHAR(30) NULL,
	  dbl_size DECIMAL(20,8) NULL,
	  sugg_retail_price DECIMAL(20,8) null
    );

	CREATE UNIQUE CLUSTERED INDEX idx_cia ON #cia (part_no) WITH  IGNORE_DUP_KEY


-- inv_master
IF ( OBJECT_ID('tempdb.dbo.#pp') IS NOT NULL )
    DROP TABLE #pp;

CREATE TABLE #pp -- need pricing for frames, front, temples
    (
      [part_no] [VARCHAR](30) NOT NULL ,
      p_price DECIMAL(20, 8) NULL
                             DEFAULT 0 ,
      std_cost DECIMAL(20, 8) NULL
                              DEFAULT 0 ,
      std_ovhd_dolrs DECIMAL(20, 8) NULL
                                    DEFAULT 0 ,
      std_util_dolrs DECIMAL(20, 8) NULL
                                    DEFAULT 0
    );

-- create INV_MASTER_ADD entries
INSERT  #ia
        ( part_no ,
          category_2 ,
          category_3 ,
          category_4 ,
          category_5 ,
          field_1 ,
          field_2 ,
          field_3 ,
          field_4 ,
          field_5 ,
          field_6 ,
          field_7 ,
          field_8 , 
-- field_9, 
          field_10 ,
          field_11 ,
          field_12 ,
          field_13 ,
          field_17 ,
          field_19 ,
          field_20 ,
          field_21 ,
          field_22 ,
          field_23 ,
          field_24 ,
          field_25 ,
          field_26 ,
          field_32
        )
        SELECT DISTINCT
                c.part_no ,
                category_2 = ISNULL(( SELECT TOP 1
                                        kys
                               FROM     dbo.CVO_Gender
                               WHERE    description = c.PrimaryDemographic AND ISNULL(void,'N') = 'N'
                             ),'') ,  -- gender
                category_3 = CASE WHEN c.part_type NOT IN ( 'FRAME', 'frame only', 'BRUIT',
                                                            'PATTERN' )
                                  THEN c.part_type
							 ELSE ''
                             END , -- part-type
                category_4 = ISNULL(( SELECT TOP 1 kys
                                         FROM   dbo.CVO_age
                                         WHERE  kys = c.target_age AND ISNULL(void,'N') = 'N'
                                       ), '')
	                           , -- target age
                category_5 = CASE WHEN c.part_type IN ( 'BRUIT', 'PATTERN',
                                                        'DEMOLEN' ) THEN ''
                                  ELSE ( SELECT TOP 1
                                                kys
                                         FROM   dbo.CVO_Color_Code
                                         WHERE  kys = c.colorgroupcode AND ISNULL(void,'N') = 'N'
                                       )
                             END , -- color code

							 -- SELECT * FROM #ia

                field_1 = CASE WHEN c.part_type IN ( 'FRAME', 'frame only', 'sun', 'bruit' )
                               THEN ISNULL(( SELECT TOP 1
                                                ia.part_no
                                      FROM      dbo.inv_master_add ia
									  JOIN		dbo.inv_master i ON i.part_no = ia.part_no
                                      WHERE     c.case_part = CAST(ISNULL(ia.long_descr,'') AS VARCHAR(80)) 
										AND ISNULL(i.void,'N') = 'N'
										AND i.type_code = 'case' AND i.obsolete = 0
										AND cast (ISNULL(ia.long_descr,'') AS VARCHAR(80)) > ''
										AND i.category = c.collection
                                    ), '')
						  ELSE ''
                          END , -- case 
                field_2 = UPPER(c.model) , -- model
                field_3 = UPPER(CASE WHEN c.part_type IN ( 'pattern', 'demolen', 'bruit' ) THEN ''
                               ELSE ISNULL(c.colorname,'')
                          END) ,
                -- field_4 = CASE WHEN c.part_type IN ( 'frame', 'front', 'bruit' )
				field_4 = CASE WHEN c.part_type IN ( 'frame', 'frame only', 'bruit' )
                               THEN ( SELECT TOP 1
                                                cc.part_no
                                      FROM      #parts_list cc
                                      WHERE     cc.part_type = 'pattern'
                                                AND cc.collection = c.Collection
                                                AND cc.model = c.model
                                    )
								ELSE ''
                          END , -- pattern part #
                field_5 = CASE WHEN c.ispolarizedavailable = 1 THEN 'Y'
                               ELSE null
                          END , -- polarized
                field_6 = CASE WHEN c.part_type NOT IN ( 'bruit', 'demolen', 'temple-l','temple-r','cable-r','cable-l' )
                               THEN c.dbl_size
							   ELSE ''
                          END , -- bridge size (dbl size)
                field_7 = CASE WHEN c.part_type IN ( 'frame', 'frame only', 'front', 'bruit' )
                               THEN ISNULL(( SELECT TOP 1
                                                kys
                                      FROM      dbo.CVO_nose_pad
                                      WHERE     description = c.nose_pads AND ISNULL(void,'N') = 'N'
                                    ), 'N/A')
                               ELSE 'N/A'
                          END , -- nose pad
                field_8 = CASE WHEN c.part_type NOT IN ( 'pattern', 'demolen' )
                               THEN CAST(ISNULL(c.temple_size,0) AS integer)
							   ELSE 0
                          END , -- temple length
                field_10 = CASE WHEN c.part_type IN ( 'frame', 'frame only', 'front','bruit')
				                       THEN ISNULL(( SELECT TOP 1
                                                kys
									   FROM     dbo.CVO_frame_matl
                                       WHERE    description = c.frame_material AND ISNULL(void,'N') = 'N'
                                     ), 'UNKNOWN' ) 
									 ELSE ''
				           END , -- frame material

				field_11 = CASE WHEN c.part_type IN ( 'frame', 'frame only', 'front','bruit')
                                THEN ( SELECT TOP 1
                                                kys
                                       FROM     dbo.CVO_frame_type
                                       WHERE    description = REPLACE(c.frame_category,'','') AND ISNULL(void,'N') = 'N'
                                     )
									 ELSE 'UNKNOWN'
                           END , -- frame type
                field_12 = CASE WHEN c.part_type NOT IN ( 'pattern', 'demolen', 'front' )
                                THEN ISNULL(( SELECT TOP 1
                                                kys
                                       FROM     dbo.CVO_temple_matl
                                       WHERE    description = c.temple_material AND ISNULL(void,'N') = 'N'
                                     ),'UNKNOWN')
									 ELSE ''
                           END , -- temple material, if different than frame
                field_13 = CASE WHEN c.part_type NOT IN ( 'pattern', 'demolen' ,'front')
                                THEN ISNULL(( SELECT TOP 1
                                                kys
                                       FROM     dbo.CVO_temple_hindge
                                       WHERE    description = c.hinge_type AND ISNULL(void,'N') = 'N'
                                     ), 'Skull-Spring')  -- 2/15/2016
									 ELSE ''
                           END , -- hinge type
			    field_17 = CASE WHEN c.part_type IN ( 'frame', 'frame only', 'front',
                                                      'bruit', 'pattern',
                                                      'demolen' )
                                THEN CAST(ISNULL(c.eye_size,0) AS DECIMAL(18,1))
								ELSE null
                           END , -- eye size
                field_19 = 
					CASE WHEN c.part_type IN ( 'frame', 'frame only', 'front',
                                                      'bruit', 'pattern',
                                                      'demolen' )
                                THEN c.a_size
								ELSE 0
                           END , -- A size
                field_20 = 
						CASE WHEN c.part_type IN ( 'frame', 'frame only', 'front',
                                                      'bruit', 'pattern',
                                                      'demolen' )
                                THEN c.b_size
								ELSE 0
                           END , -- B size
                field_21 = 
						CASE WHEN c.part_type IN ( 'frame', 'frame only', 'front',
                                                      'bruit', 'pattern',
                                                      'demolen' )
                                THEN c.ed_size
								ELSE 0
                           END , -- ED size
                field_22 = CASE WHEN c.clips_available = 1
                                     AND c.part_type IN ( 'frame', 'frame only', 'front',
                                                          'bruit', 'pattern',
                                                          'demolen' ) THEN 'Y'
                                ELSE 'N'
                           END , -- Clip
                field_23 = CASE WHEN c.res_type = 'sun'
                                THEN ( SELECT TOP 1
                                                kys
                                       FROM     dbo.CVO_sun_lens_color
                                       WHERE    description = LTRIM(RTRIM(c.lens_color)) AND ISNULL(void,'N') = 'N'
                                     ) 
								ELSE null
                           END , -- lens color (suns)
                FIELD_24 = CASE WHEN c.res_type = 'sun'
								THEN ( SELECT TOP 1
											kys
											FROM dbo.CVO_sun_lens_material
											WHERE description = c.suns_only AND ISNULL(void,'N') = 'N'
									)
								ELSE null
						   END , -- lens material (suns)
                FIELD_25 = CASE WHEN c.res_type = 'sun'
								THEN ( SELECT TOP 1
											kys
											FROM dbo.CVO_sun_lens_type
											WHERE description = c.lens_base AND ISNULL(void,'N') = 'N'
									)
								ELSE null
						   END , -- lens base (suns)
                field_26 = c.release_date , -- release date
                field_32 = CASE WHEN c.res_type NOT IN ('bruit','pattern')
							THEN ( SELECT TOP 1
                                    kys
                             FROM   dbo.cvo_specialty_fit
                             WHERE  description = c.specialty_fit AND ISNULL(void,'N') = 'N'
                           ) 
						   ELSE null
						   END  -- attribute
        FROM    #parts_to_add c
			-- WHERE NOT EXISTS ( SELECT 1 FROM #err_list e WHERE e.part_no = c.part_no);

--
-- set up INV_MASTER entries
--


-- IF @debug = 1 SELECT * FROM #parts_to_add


INSERT  #i
        ( part_no ,
          description ,
          vendor ,
          category ,
          type_code ,
          weight_ea ,
          account ,
          country_code ,
          cmdty_code
		  , lead_time
        )
        SELECT DISTINCT
                c.part_no ,
                description = LEFT(UPPER(
						CASE WHEN c.part_type = 'frame'
                                   THEN ISNULL(c.Collection,'') + ' ' + ISNULL(c.model,'') + ' '
                                        + UPPER(ISNULL(ia.field_3,'')) + ' '
                                        + CAST(ROUND(ISNULL(c.eye_size,0), 0) AS VARCHAR(2))
                                        + '/'
                                        + CAST(ROUND(ISNULL(c.dbl_size,0), 0) AS VARCHAR(2))
                                        + '/'
                                        + CAST(RTRIM(Ia.field_8) AS VARCHAR(3))
			
									WHEN c.part_type = 'frame only'
                                    THEN ISNULL(c.Collection,'') + ' ' + ISNULL(c.model,'') + ' '
                                        + UPPER(ISNULL(ia.field_3,'')) + ' FRAME ONLY '
                                        + CAST(ROUND(ISNULL(c.eye_size,0), 0) AS VARCHAR(2))
                                        + '/'
                                        + CAST(ROUND(ISNULL(c.dbl_size,0), 0) AS VARCHAR(2))
                                        + '/'
                                        + CAST(RTRIM(Ia.field_8) AS VARCHAR(3))
			
			                       WHEN c.part_type IN ( 'bruit', 'pattern' )
                                   THEN LTRIM(RTRIM(c.Collection)) + ' '
                                        + LTRIM(RTRIM(c.model)) + ' '
                                        + LTRIM(RTRIM(c.res_type))
                                   WHEN c.part_type = 'front'
                                   THEN c.Collection + ' ' + c.model + ' '
                                        + UPPER(ia.field_3) + ' '
                                        + ia.category_3 + ' '
                                        + CAST(CAST (c.eye_size AS INTEGER) AS VARCHAR(2))
                                   WHEN c.part_type IN ( 'temple-l',
                                                         'temple-r', 'cable-r',
                                                         'cable-l' )
                                   THEN c.Collection + ' ' + c.model + ' '
                                        + UPPER(ia.field_3) + ' '
                                        + ia.category_3 + ' '
                                        + CAST(CAST (ISNULL(c.temple_size,0) AS INTEGER) AS VARCHAR(3))
                                   WHEN c.part_type = 'temple-tip'
                                   THEN c.Collection + ' ' + c.model + ' '
                                        + ia.category_3 + ' '
                                        + CAST(CAST(c.eye_size AS INTEGER) AS VARCHAR(2))
                                   WHEN c.part_type = 'demolen'
                                   THEN LTRIM(RTRIM(c.Collection)) 
										+ ' ' 
									    + LTRIM(RTRIM(c.model)) 
										+ ' ' 
                                    	+ CASE WHEN c.res_type = 'SUN' THEN UPPER(ISNULL(ia.field_3,'')) ELSE '' END
									    + ' DEMOLENS '
										+ CAST(CAST (c.eye_size AS INTEGER) AS VARCHAR(4))
                              END
							  ), 255),
                vendor = ISNULL(CASE WHEN c.part_type = 'pattern' THEN @pattern_vendor
									ELSE
									( SELECT TOP 1 vendor_code
									  FROM     dbo.apmaster
									  WHERE    address_name = c.supplier
									) END
						 , '')  ,
                category = LEFT(c.Collection, 10) ,
                type_code = CASE WHEN c.part_type IN ( 'bruit', 'frame', 'frame only',
                                                       'pattern' )
                                 THEN LEFT(c.res_type, 10)
                                 ELSE 'PARTS'
                            END ,
                weight_ea = CASE WHEN c.part_type IN ( 'bruit', 'frame', 'frame only' )
                                 THEN CAST (0.05 AS DECIMAL(20, 8))
                                 WHEN c.part_type = 'front'
                                 THEN CAST (0.025 AS DECIMAL(20, 8))
                                 WHEN c.part_type IN ( 'temple-l', 'temple-r',
                                                       'cable-r', 'cable-l' )
                                 THEN CAST (0.0125 AS DECIMAL(20, 8))
                                 WHEN c.part_type IN ( 'pattern', 'demolen',
                                                       'temple-tip' )
                                 THEN CAST (0.001 AS DECIMAL(20, 8))
                                 ELSE CAST(0.00 AS DECIMAL(20, 8))
                            END ,
---- validate against in_account

                account = ( CASE WHEN c.Collection = 'IZX' THEN 'IZX'
                                 ELSE LTRIM(RTRIM(LEFT(c.Collection, 2)))
                            END ) + ' '
                + CASE WHEN c.res_type IN ('sun') THEN 'Sun'
					   WHEN (LEFT(c.PrimaryDemographic, 3) IN ( 'boy', 'gir') 
					   OR c.specialty_fit = 'pediatric'
                       or CHARINDEX('child',c.primarydemographic,0)>0
					   OR CHARINDEX('kid',c.primarydemographic,0)>0 )
					   THEN 'Kid'
                       ELSE LEFT(c.PrimaryDemographic, 3)
                  END ,
                country_code = ISNULL ((SELECT TOP 1 country_code 
					FROM      gl_country
					WHERE     description = c.country_origin
                            OR country_code = c.country_origin
                ), '' ),
                cmdty_code = CASE WHEN c.part_type = 'demolen' THEN 'PLASTIC'
                                  WHEN c.part_type IN ( 'frame', 'frame only', 'front',
                                                        'bruit' )
                                  THEN CASE WHEN (c.frame_material LIKE '%acetate%'
                                          Or    c.frame_material LIKE '%plastic%'
										  OR c.frame_material LIKE '%polyamide%'
                                          or c.frame_material LIKE '%cellulose%'
                                          OR c.frame_material LIKE '%tr-90%'
                                          or c.frame_material LIKE '%polymer%'
										  ) THEN 'PLASTIC'
										  WHEN
                                          (c.frame_material LIKE '%metal%'
                                           or c.frame_material LIKE '%steel%'
                                           or c.frame_material LIKE '%bronze%'
                                           or c.frame_material LIKE '%titanium%'
											) THEN 'METAL'
                                            ELSE 'UNKNOWN'
                                       END
                                  WHEN c.part_type IN ( 'temple-l', 'temple-r',
                                                        'cable-r', 'cable-l' )
                                  THEN CASE WHEN 
								  (c.temple_material LIKE '%acetate%'
                                            OR c.temple_material LIKE '%plastic%'
                                            OR c.temple_material LIKE '%polyamide%'
                                            OR c.temple_material LIKE '%cellulose%'
                                            OR c.temple_material LIKE '%tr-90%'
                                            OR c.temple_material LIKE '%polymer%'
											)
                                            THEN 'PLASTIC'
                                            WHEN 
											(c.temple_material LIKE '%metal%'
                                           OR c.temple_material LIKE '%steel%'
                                           OR c.temple_material LIKE '%bronze%'
                                           OR c.temple_material LIKE '%titanium%'
										   )
                                            THEN 'METAL'
                                            ELSE 'UNKNOWN'
                                       END
                                  WHEN c.part_type = 'temple-tip'
                                  THEN CASE WHEN (c.temple_tip_material LIKE '%acetate%'
                                            OR c.temple_tip_material LIKE '%plastic%'
                                            OR c.temple_tip_material LIKE '%polyamide%'
                                            OR c.temple_tip_material LIKE '%cellulose%'
                                            OR c.temple_tip_material LIKE '%tr-90%'
											OR c.temple_tip_material LIKE '%POLYMER%'
											)
                                            THEN 'PLASTIC'
                                            WHEN (c.temple_tip_material LIKE '%metal%'
                                             OR c.temple_tip_material LIKE '%steel%'
                                             OR c.temple_tip_material LIKE '%bronze%'
                                             OR c.temple_tip_material LIKE '%titanium%'
											 )
                                            THEN 'METAL'
                                            ELSE 'UNKNOWN'
                                       END
									   ELSE 'PLASTIC'
                             END
							 , ISNULL(c.lead_time,0) lead_time
        FROM    #parts_to_add c
                INNER JOIN #ia ia ON ia.part_no = c.part_no
        -- WHERE   NOT EXISTS ( SELECT 1
        --                     FROM   #err_list e
        --                     WHERE  e.part_no = c.part_no );

INSERT INTO #cia
        ( part_no ,
          eye_shape ,
          dbl_size
        )
SELECT c.part_no, c.eye_shape, c.dbl_size
        FROM    #parts_to_add c
                INNER JOIN #ia ia ON ia.part_no = c.part_no
        WHERE  1=1
			--and NOT EXISTS ( SELECT 1
   --                          FROM   #err_list e
   --                          WHERE  e.part_no = c.part_no )
			AND c.res_type IN ('frame','sun');

-- do extra validations

INSERT  INTO #err_list
        SELECT  #i.category collection,
				#ia.field_2 model,
				#i.part_no ,
                type_code ,
                account ,
                'invalid account code'
        FROM    #i 
				JOIN #ia ON #ia.part_no = #i.part_no
        WHERE   NOT EXISTS ( SELECT 1
                             FROM   dbo.in_account i ( NOLOCK )
                             WHERE  i.acct_code = #i.account
                                    AND i.void = 'n' );

INSERT INTO #err_list
        ( collection ,
          model ,
          part_no ,
          part_type ,
          bad_data ,
          error_desc
        )
		 SELECT  #i.category collection,
				#ia.field_2 model,
				#i.part_no ,
                type_code ,
                #i.country_code ,
                'invalid or missing country code'
        FROM    #i 
				JOIN #ia ON #ia.part_no = #i.part_no
		WHERE NOT EXISTS (SELECT TOP 1 country_code 
					FROM      gl_country
					WHERE     description = #i.country_code
                            OR country_code = #i.country_code );

INSERT INTO #err_list
        ( collection ,
          model ,
          part_no ,
          part_type ,
          bad_data ,
          error_desc
        )
		 SELECT  #i.category collection,
				#ia.field_2 model,
				#i.part_no ,
                type_code ,
                #i.lead_time ,
                'missing lead time'
        FROM    #i 
				JOIN #ia ON #ia.part_no = #i.part_no
		WHERE ISNULL(#i.lead_time,0) = 0;


INSERT INTO #err_list
        ( collection ,
          model ,
          part_no ,
          part_type ,
          bad_data ,
          error_desc
        )
		 SELECT  #i.category collection,
				#ia.field_2 model,
				#i.part_no ,
                type_code ,
                #i.vendor ,
                'missing vendor code'
        FROM    #i 
				JOIN #ia ON #ia.part_no = #i.part_no
		WHERE ISNULL(#i.vendor,'') = '';

INSERT INTO #err_list
        ( collection ,
          model ,
          part_no ,
          part_type ,
          bad_data ,
          error_desc
        )
		 SELECT  #i.category collection,
				#ia.field_2 model,
				#i.part_no ,
                type_code ,
                #ia.field_1 ,
                'missing case part'
        FROM    #i 
				JOIN #ia ON #ia.part_no = #i.part_no
		WHERE #i.type_code IN ('frame','sun','bruit')
		AND NOT EXISTS (SELECT 1 FROM inv_master_add ia WHERE ia.field_1 = #ia.field_1);

-- build pricing table

INSERT  #pp
        ( part_no ,
          p_price ,
          std_cost ,
          std_ovhd_dolrs ,
          std_util_dolrs
        )
        SELECT DISTINCT
                c.part_no ,
                isnull(c.front_price,0) front_price ,
                ROUND(c.front_cost,2) ,
                ROUND(c.front_cost * @ovhd_pct,2) ,
                CASE WHEN c.front_cost > 1 THEN @util_cost
                     ELSE 0
                END
        FROM    #parts_to_add c
                INNER JOIN #ia ia ON ia.part_no = c.part_no
        WHERE   1=1
				--AND NOT EXISTS ( SELECT 1
    --                         FROM   #err_list e
    --                         WHERE  e.part_no = c.part_no )
                AND c.part_type = 'front';

INSERT  #pp
        ( part_no ,
          p_price ,
          std_cost ,
          std_ovhd_dolrs ,
          std_util_dolrs
        )
        SELECT DISTINCT
                c.part_no ,
                isnull(c.temple_price,0) temple_price ,
                ROUND(c.temple_cost,2) ,
                ROUND(c.temple_cost * @ovhd_pct,2) ,
                CASE WHEN c.temple_cost > 1 THEN @util_cost
                     ELSE 0
                END
        FROM    #parts_to_add c
                INNER JOIN #ia ia ON ia.part_no = c.part_no
        WHERE   1=1
				--AND NOT EXISTS ( SELECT 1
    --                         FROM   #err_list e
    --                         WHERE  e.part_no = c.part_no )
                AND c.part_type IN ( 'temple-l', 'temple-r', 'cable-r',
                                     'cable-l' ); 

INSERT  #pp
        ( part_no ,
          p_price ,
          std_cost ,
          std_ovhd_dolrs ,
          std_util_dolrs
        )
        SELECT DISTINCT
                c.part_no ,
                CASE WHEN c.part_type = 'frame' THEN c.wholesale_price
					 WHEN c.part_type = 'frame only' THEN c.frame_price
					 ELSE 0 end ,
                ROUND(c.frame_cost,2) + CASE WHEN c.part_type = 'frame' THEN ROUND(c.lens_cost,2) ELSE 0 end,
                ROUND((c.frame_cost + CASE WHEN c.part_type = 'frame' THEN c.lens_cost ELSE 0 END)* @ovhd_pct,2) ,
                CASE WHEN c.frame_cost > 1 THEN @util_cost
                     ELSE 0
                END
        FROM    #parts_to_add c
                INNER JOIN #ia ia ON ia.part_no = c.part_no
        WHERE   1=1 
				--AND NOT EXISTS ( SELECT 1
    --                         FROM   #err_list e
    --                         WHERE  e.part_no = c.part_no )
                AND c.part_type IN ( 'frame', 'frame only' );

INSERT  #pp
        ( part_no ,
          p_price ,
          std_cost ,
          std_ovhd_dolrs ,
          std_util_dolrs
        )
        SELECT DISTINCT
                c.part_no ,
                c.wholesale_price ,
				frame_cost = ROUND((SELECT AVG(frame_cost+lens_cost) FROM #parts_to_add m WHERE m.collection = c.collection AND m.model = c.model),2),
		        std_ovhd_dolrs = ROUND((SELECT AVG(frame_cost+lens_cost) FROM #parts_to_add m WHERE m.collection = c.collection AND m.model = c.model) * @ovhd_pct,2) ,
                std_util_dolrs = CASE WHEN c.frame_cost+lens_cost > 1 THEN @util_cost ELSE 0 END
        FROM    #parts_to_add c
                INNER JOIN #ia ia ON ia.part_no = c.part_no
				WHERE   1=1 
				--AND NOT EXISTS ( SELECT 1
    --                         FROM   #err_list e
    --                         WHERE  e.part_no = c.part_no )
                AND c.part_type IN ( 'bruit' );

INSERT  #pp
        ( part_no ,
          p_price ,
          std_cost ,
          std_ovhd_dolrs ,
          std_util_dolrs
        )
        SELECT DISTINCT
                c.part_no ,
                0 AS wholesale_price ,
                ROUND(CASE WHEN c.part_type = 'demolen' THEN @demolen_cost
						   WHEN c.part_type = 'pattern' THEN @pattern_cost
						   ELSE 0 END, 2) ,
                ROUND(CASE WHEN c.part_type = 'demolen' THEN @demolen_cost
						   WHEN c.part_type = 'pattern' THEN @pattern_cost
						   ELSE 0 END * @ovhd_pct,2) ,
                CASE WHEN CASE WHEN c.part_type = 'demolen' THEN @demolen_cost
						   WHEN c.part_type = 'pattern' THEN @pattern_cost
						   ELSE 0 END > 1 THEN @util_cost
                     ELSE 0
                END
        FROM    #parts_to_add c
                INNER JOIN #ia ia ON ia.part_no = c.part_no
        WHERE   1=1 
				--AND NOT EXISTS ( SELECT 1
    --                         FROM   #err_list e
    --                         WHERE  e.part_no = c.part_no )
                AND c.part_type IN ( 'demolen','pattern' );

IF @debug = 1
--begin
--	 SELECT  'cmi', * FROM    #ia;
--	 -- elect 'epc', * From dbo.inv_master_add where field_2 = @model
--	 SELECT  'cmi', * FROM    #i;
--	 -- select 'epc', * From dbo.inv_master where part_no like 'asadv%'
SELECT  * FROM    #pp;
--end

IF @upd = 'Y'
BEGIN
	---- set up a loop and start adding stuff
	declare @last_part varchar(30)
	, @upc_code varchar(12)
	, @last_desc varchar(255)
	, @inv_price_id int
	, @p_price decimal(20,8)
	, @std_cost decimal(20,8)
	, @account varchar(32)
	, @vendor varchar(12)
	, @v_curr varchar(3)
	, @ITEM_NO VARCHAR(30)
	, @std_ovhd_dolrs DECIMAL (20,8)
	, @std_util_dolrs decimal (20,8)
	, @part_no varchar(30)
	, @org_level int
	, @loc_org_id varchar(30)
	, @promo_type char(1)
	, @promo_rate decimal(20,8)
	, @promo_start datetime
	, @promo_end datetime
	, @p_level int
	, @p_qty decimal(20,8)
	, @catalog_id int
	, @curr_key varchar(8)
	, @active_ind int 
	, @promo_entered datetime
	, @upd_type int
	, @dup_part varchar(30)
	, @check_digit char(1)
	, @type_code varchar(10)
	, @rc INT
    , @lead_time INT


	select @last_part = min(part_no) from #ia
	where not exists ( select 1 from #err_list where #err_list.part_no = #ia.part_no)
	AND NOT EXISTS ( SELECT 1 FROM inv_master_add ia WHERE ia.part_no = #ia.part_no)
	AND NOT EXISTS ( SELECT 1 FROM inv_master i WHERE i.part_no = #ia.part_no)

	while @last_part is not null
	begin

		select @last_desc = description
			, @account = account
			, @vendor = vendor
			, @v_curr = (select top 1 nat_cur_code from apmaster where vendor_code = #i.vendor)
			, @type_code = type_code
			, @lead_time = lead_time
		 from #i where part_no = @last_part
		select @p_price = p_price, @std_cost = std_cost, @std_ovhd_dolrs = std_ovhd_dolrs,
			@std_util_dolrs = std_util_dolrs from #pp where part_no = @last_part
	
		-- get a upc (LAST 5 DIGITS)
		begin tran
			update dbo.next_upc12 set last_no = last_no + 1
			select @upc_code = last_no from dbo.next_upc12
			-- select * from dbo.next_upc12
			select @upc_code = (select top 1 VALUE_STR FROM config (nolock) where flag = 'ID_CVO_MASK') + @upc_code
			select @check_digit = dbo.CalcChkDigitGTIN12( @upc_code )
			select @upc_code = @upc_code + @check_digit
			--select @upc_code
		commit tran

		begin tran
			--select @upc_code
			INSERT INTO inv_master_add ( part_no, category_1, category_2, category_3, category_4, 
			category_5, field_1, field_2, field_3, field_4, field_5, field_6, field_7, field_8, 
			field_9, field_10, field_11, field_12, field_13, long_descr, field_17, field_30, 
			field_18, field_19, field_20, field_21, field_22, field_23, field_24, field_25, field_26, field_27, 
			field_28, field_32, field_33, field_18_a, field_18_b, field_18_c, field_18_d, field_18_e ) 
			select distinct
			part_no, category_1, category_2, category_3, category_4, 
			category_5, field_1, field_2, field_3, field_4, field_5, field_6, field_7, field_8, 
			field_9, field_10, field_11, field_12, field_13, CONVERT(VARCHAR(255),long_descr), field_17, field_30, 
			field_18, field_19, field_20, field_21, field_22, field_23, field_24, field_25, field_26, field_27, 
			field_28, field_32, field_33, field_18_a, field_18_b, field_18_c, field_18_d, field_18_e 
			from #ia where part_no = @last_part
			AND NOT EXISTS ( SELECT 1 FROM inv_master_add ia WHERE ia.part_no = @last_part)
		
		
			INSERT INTO inv_master ( part_no, upc_code, description, vendor, category, type_code, 
			status, cubic_feet, weight_ea, labor, uom, account, comm_type, void, entered_who, 
			entered_date, std_cost, utility_cost, qc_flag, lb_tracking, rpt_uom, freight_unit, 
			taxable, conv_factor, cycle_type, inv_cost_method, buyer, allow_fractions, cfg_flag, 
			tax_code, obsolete, serial_flag, web_saleable_flag, tolerance_cd, reg_prod, 
			pur_prod_flag, country_code, cmdty_code, min_profit_perc, height, width, length, 
			eprocurement_flag, non_sellable_flag, so_qty_increment ) 
			SELECT distinct
			part_no, @upc_code as upc_code, description, vendor, category, type_code, 
			status, cubic_feet, weight_ea, labor, uom, account, comm_type, void, entered_who, 
			entered_date, std_cost, utility_cost, qc_flag, lb_tracking, rpt_uom, freight_unit, 
			taxable, conv_factor, cycle_type, inv_cost_method, buyer, allow_fractions, cfg_flag, 
			tax_code, obsolete, serial_flag, web_saleable_flag, tolerance_cd, reg_prod, 
			'Y' as pur_prod_flag, country_code, cmdty_code, min_profit_perc, height, width, length, 
			eprocurement_flag, non_sellable_flag, so_qty_increment 
			from #i where part_no = @last_part
			AND NOT EXISTS ( SELECT 1 FROM inv_master i WHERE i.part_no = @last_part)

			INSERT dbo.cvo_inv_master_add
			        ( part_no ,
			          eye_shape ,
			          dbl_size )
			SELECT part_no, eye_shape, dbl_size
			FROM #cia WHERE part_no = @last_part
			AND NOT EXISTS ( SELECT 1 FROM cvo_inv_master_add i WHERE i.part_no = @last_part)

			-- select * from #i		
			-- Using the UPC code
			
			exec @rc = dbo.scm_pb_set_dw_uom_id_code_sp 'I',@last_part,'EA',
			@upc_code,NULL,NULL,NULL,NULL,@last_desc,NULL,NULL 
		
			-- set up pricing

			IF EXISTS (SELECT 1 FROM #pp WHERE #pp.part_no = @last_part)
			begin
			IF ( OBJECT_ID('tempdb.dbo.#inv_price') IS NULL ) 
				create table #inv_price
				(rc int, msg varchar(255), inv_price_id int, catalog_id int);
		
			set @inv_price_id = -1 -- get a new price id

			INSERT #inv_price
			EXEC @rc = dbo.adm_upd_inv_price_wrap @part_no = @last_part, @org_level = 0, @loc_org_id = '', @promo_type = 'N', @promo_rate = 0, @promo_start = NULL, @promo_end = NULL, @p_level = 1, @p_qty = 0, @p_price = @p_price, @catalog_id = 1, @inv_price_id = @inv_price_id, @curr_key = 'USD', @active_ind = 1, @promo_entered = NULL, @upd_type = 0, @dup_part = ''  
			INSERT #inv_price
			EXEC @rc = dbo.adm_upd_inv_price_wrap @part_no = @last_part, @org_level = 0, @loc_org_id = '', @promo_type = 'N', @promo_rate = 0, @promo_start = NULL, @promo_end = NULL, @p_level = 2, @p_qty = 0, @p_price = 0, @catalog_id = 1, @inv_price_id = @inv_price_id , @curr_key = 'USD', @active_ind = 1, @promo_entered = NULL, @upd_type = 0, @dup_part = '' 
			INSERT #inv_price
			EXEC @rc = dbo.adm_upd_inv_price_wrap @part_no = @last_part, @org_level = 0, @loc_org_id = '', @promo_type = 'N', @promo_rate = 0, @promo_start = NULL, @promo_end = NULL, @p_level = 3, @p_qty = 0, @p_price = 0, @catalog_id = 1, @inv_price_id = @inv_price_id , @curr_key = 'USD', @active_ind = 1, @promo_entered = NULL, @upd_type = 0, @dup_part = '' 
			INSERT #inv_price
			EXEC @rc = dbo.adm_upd_inv_price_wrap @part_no = @last_part, @org_level = 0, @loc_org_id = '', @promo_tYpe = 'N', @promo_rate = 0, @promo_start = NULL, @promo_end = NULL, @p_level = 4, @p_qty = 0, @p_price = 0, @catalog_id = 1, @inv_price_id = @inv_price_id , @curr_key = 'USD', @active_ind = 1, @promo_entered = NULL, @upd_type = 0, @dup_part = '' 
			INSERT #inv_price
			EXEC @rc = dbo.adm_upd_inv_price_wrap @part_no = @last_part, @org_level = 0, @loc_org_id = '', @promo_type = 'N', @promo_rate = 0, @promo_start = NULL, @promo_end = NULL, @p_level = 5, @p_qty = 0, @p_price = 0, @catalog_id = 1, @inv_price_id = @inv_price_id , @curr_key = 'USD', @active_ind = 1, @promo_entered = NULL, @upd_type = 0, @dup_part = '' 
			END
					
			-- set up std cost and main location 001
			INSERT INTO inv_list ( location, part_no, bin_no, avg_cost, in_stock, 
			min_stock, min_order, lead_time, labor, issued_mtd, issued_ytd, hold_qty, 
			qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, 
			std_cost, max_stock, setup_labor, freight_unit, std_labor, acct_code, 
			std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, avg_direct_dolrs, 
			avg_ovhd_dolrs, avg_util_dolrs, cycle_date, status, eoq, dock_to_stock, 
			order_multiple, rank_class, po_uom, so_uom ) 
			select '001', @last_part, 'N/A', 0.00000000, 0.00000000, 0.00000000, 0.00000000, @lead_Time, 
			0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 
			0.00000000, 'sa', getdate(), 'N', @std_cost, 
			0.00000000, 0.00000000, 0.00000000, 0.00000000, @account, 
			0.00000000, @std_ovhd_dolrs, @std_util_dolrs, 0.00000000, 0.00000000, 
			0.00000000, getdate(), 'P', 0.00000000, 0, 0.00000000, 'N', 'EA', 'EA' 

			if @type_code in ('frame','sun','case','pop','pattern')
			begin
				INSERT INTO inv_list ( location, part_no, bin_no, avg_cost, in_stock, 
				min_stock, min_order, lead_time, labor, issued_mtd, issued_ytd, hold_qty, 
				qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, 
				std_cost, max_stock, setup_labor, freight_unit, std_labor, acct_code, 
				std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, avg_direct_dolrs, 
				avg_ovhd_dolrs, avg_util_dolrs, cycle_date, status, eoq, dock_to_stock, 
				order_multiple, rank_class, po_uom, so_uom ) 
				select l.location, @last_part, 'N/A', 0.00000000, 0.00000000, 0.00000000, 0.00000000, @lead_time, 
				0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 
				0.00000000, 'sa', getdate(), 'N', @std_cost, 
				0.00000000, 0.00000000, 0.00000000, 0.00000000, @account, 
				0.00000000, @std_ovhd_dolrs, @std_util_dolrs, 0.00000000, 0.00000000, 
				0.00000000, getdate(), 'P', 0.00000000, 0, 0.00000000, 'N', 'EA', 'EA' 
				FROM (SELECT location FROM locations WHERE ISNUMERIC(LEFT(location,1)) = 1 AND void <> 'v') L
				where not exists (select 1 from inv_list il (nolock) where il.part_no = @last_part and il.location = l.location)
			end
			
			-- create build plan
			INSERT INTO what_part 
			( asm_no, part_no, uom, who_entered, seq_no, attrib, active, bench_stock, 
			note, eff_date, date_entered, conv_factor, constrain, fixed, qty, alt_seq_no, 
			note2, note3, note4, plan_pcs, lag_qty, cost_pct, location, pool_qty )
			select distinct a.part_no, c.part_no, 'EA', 'sa', '001', 1.00000000, 'A', 'N', '', datediff(dd,0,getdate())
			, getdate(), 1.00000000, 'N', 'N', 1.00000000, '', '', '', '', 0.00000000, 0.00000000
			, 0.00000000, 'ALL', 0.00000000 
			from #parts_list c 
			inner join #parts_list a on a.collection = c.collection and a.model = c.model
				and a.colorname = c.colorname and a.eye_size = c.eye_size
			where a.part_type IN ( 'frame', 'frame only' ) and c.part_type = 'front' 
			and not exists (select 1 from what_part where a.part_no = asm_no and seq_no = '001')
		
			-- select * from what_part where asm_no like 'bcflv%'
	
			INSERT INTO what_part 
			( asm_no, part_no, uom, who_entered, seq_no, attrib, active, bench_stock, 
			note, eff_date, date_entered, conv_factor, constrain, fixed, qty, alt_seq_no, 
			note2, note3, note4, plan_pcs, lag_qty, cost_pct, location, pool_qty )
			select distinct a.part_no, c.part_no, 'EA', 'sa', '003', 1.00000000, 'A', 'N', '', datediff(dd,0,getdate())
			, getdate(), 1.00000000, 'N', 'N', 1.00000000, '', '', '', '', 0.00000000, 0.00000000
			, 0.00000000, 'ALL', 0.00000000 
			from #parts_list c 
			inner join #parts_list a on a.collection = c.collection and a.model = c.model
				and a.colorname = c.colorname and a.temple_size = c.temple_size
				where c.part_type = 'temple-l' and a.part_type IN ( 'frame', 'frame only')
			and not exists (select 1 from what_part where a.part_no = asm_no and seq_no = '003')

			INSERT INTO what_part 
			( asm_no, part_no, uom, who_entered, seq_no, attrib, active, bench_stock, 
			note, eff_date, date_entered, conv_factor, constrain, fixed, qty, alt_seq_no, 
			note2, note3, note4, plan_pcs, lag_qty, cost_pct, location, pool_qty )
			select distinct a.part_no, c.part_no, 'EA', 'sa', '005', 1.00000000, 'A', 'N', '', datediff(dd,0,getdate())
			, getdate(), 1.00000000, 'N', 'N', 1.00000000, '', '', '', '', 0.00000000, 0.00000000
			, 0.00000000, 'ALL', 0.00000000 
			from #parts_list c
			inner join #parts_list a on a.collection = c.collection and a.model = c.model
				and a.colorname = c.colorname and a.temple_size = c.temple_size
			where c.part_type = 'temple-r' and a.part_type  IN ( 'frame', 'frame only')
			and not exists (select 1 from what_part where a.part_no = asm_no and seq_no = '005')

			INSERT INTO what_part 
			( asm_no, part_no, uom, who_entered, seq_no, attrib, active, bench_stock, 
			note, eff_date, date_entered, conv_factor, constrain, fixed, qty, alt_seq_no, 
			note2, note3, note4, plan_pcs, lag_qty, cost_pct, location, pool_qty )
			select distinct a.part_no, c.part_no, 'EA', 'sa', '007', 1.00000000, 'A', 'N', '', datediff(dd,0,getdate())
			, getdate(), 1.00000000, 'N', 'N', 1.00000000, '', '', '', '', 0.00000000, 0.00000000
			, 0.00000000, 'ALL', 0.00000000 
			from #parts_list c
			inner join #parts_list a on a.collection = c.collection and a.model = c.model
				and a.colorname = c.colorname and a.temple_size = c.temple_size
			where c.part_type = 'cable-r' and a.part_type  IN ( 'frame', 'frame only')
			and not exists (select 1 from what_part where a.part_no = asm_no and seq_no = '007')

			INSERT INTO what_part 
			( asm_no, part_no, uom, who_entered, seq_no, attrib, active, bench_stock, 
			note, eff_date, date_entered, conv_factor, constrain, fixed, qty, alt_seq_no, 
			note2, note3, note4, plan_pcs, lag_qty, cost_pct, location, pool_qty )
			select distinct a.part_no, c.part_no, 'EA', 'sa', '009', 1.00000000, 'A', 'N', '', datediff(dd,0,getdate())
			, getdate(), 1.00000000, 'N', 'N', 1.00000000, '', '', '', '', 0.00000000, 0.00000000
			, 0.00000000, 'ALL', 0.00000000 
			from #parts_list c
			inner join #parts_list a on a.collection = c.collection and a.model = c.model
				and a.colorname = c.colorname and a.temple_size = c.temple_size
			where c.part_type = 'cable-l' and a.part_type  IN ( 'frame', 'frame only')
			and not exists (select 1 from what_part where a.part_no = asm_no and seq_no = '009')
		
			commit tran
		
			-- rollback tran

			-- add vendor quote info
			INSERT INTO #inv_price (rc)
			exec cvo_createVendorQuote_sp @last_part, @V_CURR, @STD_COST
		
			-- select * From vendor_sku where sku_no like 'bcflv%'

		select @last_part = min(part_no) from #ia 
		where part_no > @last_part
		and not exists ( select 1 from #err_list where #err_list.part_no = #ia.part_no)
		AND NOT EXISTS ( SELECT 1 FROM inv_master_add ia WHERE ia.part_no = #ia.part_no)
		AND NOT EXISTS ( SELECT 1 FROM inv_master i WHERE i.part_no = #ia.part_no)

	
	end

	DECLARE @dim_id INT
	SELECT @dim_id = MIN(dim_id) FROM #cvo_cmi_sku_xref
	WHILE @dim_id IS NOT NULL
	begin
		update c set c.part_no = inv.part_no, c.upc_code = inv.upc_code
		-- SELECT * 
		FROM #cvo_cmi_sku_xref c 
		INNER join 
		(SELECT DISTINCT i.part_no, i.upc_code , ia.field_2 model, ia.field_17 eye_size, ia.field_3 colorname
			 FROM inv_master_add ia 
		INNER JOIN inv_master i ON i.part_no = ia.part_no
		where i.type_code in ('frame','sun') AND i.void = 'n'
		-- and ia.field_2 = 'spirited'

		) inv ON inv.model = c.model AND inv.colorname = c.colorname AND inv.eye_size = c.eye_size 
		WHERE c.dim_id = @dim_id

		SELECT @dim_id = MIN(dim_id) FROM #cvo_cmi_sku_xref WHERE dim_id > @dim_id
	end

	insert cvo_cmi_sku_xref
	(dim_id, part_no, upc_code, date_added)
	select dim_id, part_no, upc_code, getdate() 
	FROM #cvo_cmi_sku_xref c
	WHERE NOT EXISTS (SELECT 1 FROM cvo_cmi_sku_xref WHERE dim_id = c.dim_id AND c.part_no IS NOT null)

END -- update
	
	IF ( OBJECT_ID('dbo.cvo_tmp_sku_gen') IS NULL ) 
		CREATE TABLE dbo.cvo_tmp_sku_gen
		(
			collection VARCHAR(12),
			model VARCHAR(40),
			part_no VARCHAR(30) ,
			part_type VARCHAR(20) ,
			data VARCHAR(80) ,
			message_desc VARCHAR(80),
			severity varchar(80)
		);

	IF @debug = 1 TRUNCATE TABLE dbo.cvo_tmp_sku_gen

	INSERT cvo_tmp_sku_gen (collection, model, part_no, part_type, Data, Message_Desc, Severity) 
	SELECT collection,
		   model,
		   part_no ,
           part_type ,
           bad_data Data,
           error_desc Message_Desc,
		   'Error' AS Severity FROM #err_list
	UNION ALL
    SELECT #i.category, #ia.field_2, #i.part_no, #i.type_code, #i.description, 'part added ', 'Info' FROM #i
		JOIN #ia ON #ia.part_no = #i.part_no
		WHERE NOT EXISTS (SELECT 1 FROM #err_list WHERE #err_list.part_no = #i.part_no)
	--UNION ALL
 --   SELECT 'coll','model','part_no','type_code','description','placeholder for warnings','Warning'
	--ORDER BY part_no

	IF @debug = 1 SELECT collection ,
                         model ,
                         part_no ,
                         part_type ,
                         Data ,
                         Message_Desc ,
                         Severity FROM cvo_tmp_sku_gen

END -- procedure






GO

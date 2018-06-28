SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_reset_cycle_count_master_data_sp]
AS
BEGIN

SET NOCOUNT ON

-- shut down all the skus to count

UPDATE /*top (2500)*/ il
SET il.rank_class = 'N'
-- SELECT cycle_type, rank_class, type_code, field_28, i.part_no
FROM inv_master i
    JOIN inv_master_add ia
        ON ia.part_no = i.part_no
    JOIN inv_list il
        ON il.part_no = i.part_no
           AND il.location = '001'
-- WHERE il.rank_class <> 'N'
WHERE il.rank_class <> 'N'


UPDATE /*top (2500)*/ i
SET i.cycle_type = 'NEVER'
-- UPDATE top (2500) il SET il.rank_class = 'N'
-- SELECT cycle_type, rank_class, type_code, field_28, i.part_no
FROM inv_master i
    JOIN inv_master_add ia
        ON ia.part_no = i.part_no
    JOIN inv_list il
        ON il.part_no = i.part_no
           AND il.location = '001'
-- WHERE il.rank_class <> 'N'
WHERE i.cycle_type <> 'NEVER'
      AND il.rank_class = 'N'


-- SET THE NEW RANK CLASSES

IF (OBJECT_ID('tempdb.dbo.#INV_CLASS_TEMP_PARTS')) IS NULL
    CREATE TABLE #INV_CLASS_temp_PARTS
    (
        PART_NO VARCHAR(30),
        percentage NUMERIC,
        old_rank CHAR(1),
        new_rank CHAR(1),
        rowid INT IDENTITY(1, 1),
        sel_flg INT NULL
    );

DECLARE @TODAY DATETIME,
        @TODAYMINUS3 DATETIME;
SET @TODAY = GETDATE();
SET @TODAYMINUS3 = DATEADD(MONTH, -3, @TODAY);

EXEC dbo.tdc_determine_abc_part_classification_sp @upper_percentage = 80,     -- decimal(20, 8)
                                                  @lower_percentage = 20,     -- decimal(20, 8)
                                                  @location = '001',          -- varchar(12)
                                                  @start_date = @TODAYMINUS3, -- varchar(35)
                                                  @end_date = @TODAY,         -- varchar(35)
                                                  @processing_option = 2,     -- int
                                                  @part_type = '<ALL>',       -- char(5)
                                                  --@part_group = '<ALL>'          -- varchar(10) <ALL>
												  @part_group = 'DD';         -- varchar(10) <ALL>
-- SELECT * FROM #INV_CLASS_temp_PARTS
UPDATE #INV_CLASS_temp_PARTS SET sel_flg = 1

EXEC tdc_process_abc_part_classification_sp '001';

UPDATE il SET rank_class = 'N'
-- SELECT il.part_no, il.rank_class, ia.field_28
FROM inv_list il (NOLOCK)
JOIN inv_master_add ia (NOLOCK) ON ia.part_no = il.part_no
JOIN inv_master i (NOLOCK) ON i.part_no = il.part_no
WHERE 1=1
-- AND ia.field_28 < GETDATE() 
AND il.rank_class <> 'n' AND il.location = '001'
AND i.type_code NOT IN ('frame')



-- SET THE CYCLE TYPES
UPDATE -- TOP (2500) 
    I
SET I.cycle_type = CASE WHEN rank_class = 'A' THEN 'QTRLY'
                   WHEN RANK_CLASS = 'B' THEN 'BI-ANNUAL'
                   WHEN RANK_CLASS = 'C' THEN 'ANNUAL' ELSE 'NEVER'
                   END
FROM inv_list
    (NOLOCK)
    JOIN inv_master I
    (ROWLOCK)
        ON I.part_no = inv_list.part_no
WHERE location = '001'
      AND I.cycle_type <> CASE WHEN rank_class = 'A' THEN 'QTRLY'
                          WHEN rank_class = 'B' THEN 'BI-ANNUAL'
                          WHEN rank_class = 'C' THEN 'ANNUAL' ELSE 'NEVER'
                          END;

-- UPDATE THE CYCLE FREQUENCIES


UPDATE dbo.cycle_types SET num_items =  6, cycle_days  = 9 WHERE kys IN ('ANNUAL','BI-ANNUAL')
UPDATE dbo.cycle_types SET num_items = 24, cycle_days  = 9 WHERE kys IN ('QTRLY')

--UPDATE dbo.cycle_types SET num_items = 6, cycle_days  = 365 WHERE kys IN ('ANNUAL')
--UPDATE dbo.cycle_types SET num_items = 6, cycle_days  = 180 WHERE kys IN ('BI-ANNUAL')
--UPDATE dbo.cycle_types SET num_items = 24, cycle_days  = 90 WHERE kys IN ('QTRLY')

--SELECT COUNT(i.PART_NO), IL.rank_class, i.type_code 
--FROM INV_LIST IL (nolock)
--JOIN inv_master i (NOLOCK) ON i.part_no = IL.part_no
--WHERE LOCATION = '001' AND IL.rank_class <> 'n'
--GROUP BY IL.rank_class, i.type_code

END

GRANT EXECUTE ON dbo.cvo_reset_cycle_count_master_data_sp TO PUBLIC



GO
GRANT EXECUTE ON  [dbo].[cvo_reset_cycle_count_master_data_sp] TO [public]
GO

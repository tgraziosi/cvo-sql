SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_inv_qc_setup_sp]
AS
  /*
  Find inv_master entries for frame/sun/parts with qc_flag = 'N'
  insert #i (part_no) 
  */
  
  SET NOCOUNT ON;

  IF ( OBJECT_ID('tempdb.dbo.#i') IS NOT NULL ) DROP TABLE #i;

  select TOP 5000 part_no, type_code INTO #i
  FROM inv_master 
  WHERE type_code IN ('frame','sun','parts') 
	AND qc_flag = 'N' AND ISNULL(void,'N')='N'
	AND status = 'P'

  /*Check the res_type -- frame, sun, parts
  for frame/sun
	add alignment, color-fnsh, mark-pack
  for parts
	add 'parts test'
  */
 INSERT dbo.qc_part
          ( part_no ,
            test_key ,
            min_val ,
            max_val ,
            target ,
            coa ,
            print_note ,
            void ,
            void_who ,
            void_date ,
            note
          )
SELECT #i.part_no, qc.kys, qc.min_val, qc.max_val, qc.target,
 qc.coa, qc.print_note, qc.void, qc.void_who, qc.void_date, qc.note
FROM #i CROSS JOIN qc_test qc
WHERE
#i.type_code <> 'parts'
AND qc.kys IN ('alignment','color-fnsh','mark-pack')
AND NOT EXISTS (SELECT 1 FROM qc_part p WHERE p.part_no = #i.part_no AND p.test_key = qc.kys)
UNION all
SELECT #i.part_no, qc.kys, qc.min_val, qc.max_val, qc.target,
 qc.coa, qc.print_note, qc.void, qc.void_who, qc.void_date, qc.note
FROM #i CROSS JOIN qc_test qc
WHERE
#i.type_code = 'parts'
AND qc.kys IN ('parts test')
AND NOT EXISTS (SELECT 1 FROM qc_part p WHERE p.part_no = #i.part_no AND p.test_key = qc.kys)

UPDATE i SET qc_flag = 'Y'
FROM #i JOIN inv_master  i (ROWLOCK) ON i.part_no = #i.part_no
WHERE i.type_code IN ('frame','sun','parts') 
	AND status = 'P' AND qc_flag = 'N' AND ISNULL(void,'N')='N'
GO

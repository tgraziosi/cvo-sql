SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
          
          
          
          
          
          
          
          
           
          
CREATE procedure [dbo].[adm_ins_SO_dtl_validate]           
          
          
          
          
          
          
          
          
          
          
as          
          
          
-- more > 1 same line in same PONumber.          
 INSERT INTO #ewerror          
 (module_id,err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 4900, tempd.SONumber, tempd.LineNumber, tempd.LineNumber            
 FROM CVO_TempSOD tempd           
 INNER JOIN CVO_TempSOD tempd2 ON tempd.key_table <> tempd2.key_table           
 AND tempd.SONumber = tempd2.SONumber AND tempd.LineNumber = tempd2.LineNumber          
          
          
-- if insert and so does not have lines.          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 3700, tempd.SONumber, tempd.SONumber, tempd.LineNumber          
 FROM CVO_TempSOD tempd          
 LEFT JOIN CVO_TempSO temp ON tempd.SONumber = temp.SONumber          
 WHERE temp.SONumber IS NULL           
          
-- if update and so_no is not found.          
          
          
          
          
          
          
          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)           
 SELECT DISTINCT 19000, 3900, tempd.SONumber, tempd.Type, tempd.LineNumber          
 FROM CVO_TempSOD tempd          
 WHERE tempd.Type NOT IN ('P','M','X', 'V', 'C', 'E', 'J') AND tempd.Type IS NOT NULL          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 4000, tempd.SONumber, tempd.PartNo, tempd.LineNumber          
 FROM CVO_TempSOD tempd          
 INNER JOIN CVO_TempSO temp ON tempd.SONumber = temp.SONumber          
 LEFT JOIN inv_master inv (NOLOCK) ON tempd.PartNo = inv.part_no          
 WHERE inv.part_no IS NULL           
 AND tempd.Type ='P'          
          
          
-- insert      
/* Fzambada          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 4100, tempd.SONumber, tempd.UnitOfMeasure, tempd.LineNumber          
 FROM CVO_TempSOD tempd          
 LEFT JOIN uom_table uom (NOLOCK) ON (tempd.PartNo = uom.item OR uom.item = 'STD')           
 INNER JOIN CVO_TempSO temp ON tempd.SONumber = temp.SONumber          
 WHERE uom.item IS NULL --AND tempd.Type = 'P'           
 UNION ALL          
 SELECT DISTINCT 19000, 4100, tempd.SONumber, tempd.UnitOfMeasure, tempd.LineNumber          
 FROM CVO_TempSOD tempd          
 LEFT JOIN uom_list uom (NOLOCK) ON uom.uom =  tempd.UnitOfMeasure          
 INNER JOIN CVO_TempSO temp ON tempd.SONumber = temp.SONumber          
 WHERE uom.uom IS NULL --AND tempd.Type = 'P'           
    */      
          
-- insert           
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 4200, tempd.SONumber, tempd.Quantity, tempd.LineNumber          
 FROM CVO_TempSOD tempd          
 INNER JOIN CVO_TempSO temp ON tempd.SONumber = temp.SONumber          
 WHERE tempd.Quantity < 1           
          
          
-- insert          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 4300, tempd.SONumber, tempd.Loc, tempd.LineNumber          
 FROM CVO_TempSOD tempd          
 INNER JOIN CVO_TempSO temp ON tempd.SONumber = temp.SONumber          
 LEFT JOIN locations l (NOLOCK) ON tempd.Loc = l.location           
 WHERE l.location IS NULL           
          
          
-- insert          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 4400, tempd.SONumber, tempd.Account, tempd.LineNumber          
 FROM CVO_TempSOD tempd          
 INNER JOIN CVO_TempSO temp ON tempd.SONumber = temp.SONumber           
 LEFT JOIN adm_glchart inv (NOLOCK) ON tempd.Account = inv.account_code          
 WHERE inv.account_code IS NULL           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 4500, tempd.SONumber, tempd.ItemDescription, tempd.LineNumber          
 FROM CVO_TempSOD tempd          
 INNER JOIN CVO_TempSO temp ON tempd.SONumber = temp.SONumber          
 WHERE tempd.ItemDescription = '' AND tempd.ItemDescription IS NOT NULL          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 6700, temp.SONumber, temp.SONumber, 0          
 FROM CVO_TempSO temp          
 INNER JOIN CVO_TempSOD tempd ON temp.SONumber = tempd.SONumber          
 WHERE temp.Blanket = 'Y'          
 GROUP BY temp.SONumber, temp.BlanketAmount          
 HAVING temp.BlanketAmount < sum((tempd.Quantity * tempd.Price ))          
          
/**/ 
GO
GRANT EXECUTE ON  [dbo].[adm_ins_SO_dtl_validate] TO [public]
GO

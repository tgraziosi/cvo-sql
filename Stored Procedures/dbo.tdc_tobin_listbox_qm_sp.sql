SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
CREATE TABLE #bin_listbox (								
								bin_no varchar(30) null,						
								to_bin varchar(12) null,						
								row_cnt int identity not null)

exec tdc_tobin_listbox_qm_sp 'CBBLA4000', '001', 'F01F-03-01'
select * from #bin_listbox
drop table #bin_listbox

*/
CREATE PROCEDURE [dbo].[tdc_tobin_listbox_qm_sp](  
  @part_no  varchar (30),  
  @location varchar (10),  
  @from_bin varchar (12)  
)  
AS  
  
DECLARE @pat_index int,  
 @bin_no varchar(30),  
 @to_bin varchar(12),  
 @partial varchar(4),  
 @qty decimal(12,2),  
 @row_cnt int,  
 @in_stock decimal(20,8),  
 @orderby varchar(20),  
 @sqlstatement varchar(1000)  
   
  
 -- primary bin  
 INSERT INTO #bin_listbox (bin_no, to_bin)  
  SELECT bin_no + '<1>', bin_no  
    FROM tdc_bin_part_qty (nolock)   
   WHERE location = @location   
     AND part_no = @part_no   
     AND [primary] = 'Y'
	 AND NOT (bin_no = '' OR bin_no = '<NONE>')
   
 -- secondary bin  
 INSERT INTO #bin_listbox (bin_no, to_bin)  
  SELECT bin_no + '<2>', bin_no  
    FROM tdc_bin_part_qty (nolock)  
   WHERE location = @location  
     AND part_no = @part_no  
     AND bin_no <> @from_bin  
     AND seq_no > 0  
     AND NOT (bin_no = '' OR bin_no = '<NONE>')
  ORDER BY seq_no  
  
 SELECT @orderby =   
  CASE value_str  
   WHEN '1' THEN 'date_expires'  
   WHEN '2' THEN 'date_expires desc'  
           WHEN '3' THEN 'lot_ser'  
           WHEN '4' THEN 'lot_ser desc'  
           WHEN '5' THEN 'qty'  
    WHEN '6' THEN 'qty desc'  
           ELSE 'bin_no'  
  END  
   FROM tdc_config (nolock)   
  WHERE [function] = 'dist_cust_pick'  
  
-- exec tdc_tobin_listbox_sp 'MFS73', 'DALLAS', 'AA104'  
-- select * from #bin_listbox ORDER BY row_cnt  
-- select distinct bin_no from lot_bin_stock where location = 'Dallas'  
  
 -- v1.0 Start 
IF NOT EXISTS (SELECT 1 FROM #bin_listbox)
BEGIN
 SELECT @sqlstatement = 'SELECT m.bin_no, m.bin_no  
      FROM tdc_bin_master m (nolock)  
     WHERE m.location = ' + '''' + @location + '''' +   
     ' AND m.bin_no <> ' + '''' + @from_bin + '''' +  
     '  AND (usage_type_code = ''OPEN'')  
       AND m.status = ''A''             
    ORDER BY m.bin_no'
  
 INSERT INTO #bin_listbox (bin_no, to_bin)  
  EXEC (@sqlstatement)  
END
-- v1.0 End
  
-- START v1.1
-- 080812 - tag -- reserve bin if from bin = an 'r' bin
	IF left(@from_bin,1) = 'R' and @location = '001' 
	begin
		INSERT INTO #bin_listbox (bin_no, to_bin)
		SELECT bin_no + '<E>', bin_no
		  FROM tdc_bin_master (nolock) 
		 WHERE location = @location
		   AND (usage_type_code = 'OPEN' OR usage_type_code = 'REPLENISH')
		   AND status = 'A' 
		   AND bin_no = 'reserve bin'			  
		   AND bin_no NOT IN (SELECT to_bin FROM #bin_listbox)
		ORDER BY bin_no
	end
-- END v1.1

 DECLARE bin_cursor CURSOR FOR  
    SELECT to_bin, row_cnt FROM #bin_listbox  
  
 OPEN bin_cursor  
 FETCH NEXT FROM bin_cursor INTO @to_bin, @row_cnt  
  
 WHILE(@@FETCH_STATUS = 0)  
 BEGIN     
  DELETE FROM #bin_listbox WHERE to_bin = @to_bin AND row_cnt > @row_cnt  
  FETCH NEXT FROM bin_cursor INTO @to_bin, @row_cnt  
 END  
  
 CLOSE bin_cursor  
 DEALLOCATE bin_cursor  
  
 DECLARE bin_cursor CURSOR FOR  
    SELECT bin_no, to_bin FROM #bin_listbox  
  
 OPEN bin_cursor  
 FETCH NEXT FROM bin_cursor INTO @bin_no, @to_bin  
  
 WHILE(@@FETCH_STATUS = 0)  
 BEGIN  
  SELECT @qty = ISNULL( (SELECT qty   
      FROM tdc_bin_part_qty (nolock)   
     WHERE location = @location   
       AND part_no = @part_no   
       AND bin_no = @to_bin), 0)  
  
  SELECT @in_stock = ISNULL( (SELECT sum(qty)  
           FROM lot_bin_stock (nolock)  
          WHERE part_no = @part_no    
            AND location = @location   
            AND bin_no = @to_bin    
         GROUP BY location, part_no, bin_no), 0)   
  
  SET @partial = NULL  
  SELECT @pat_index = 0  
  
  SELECT @pat_index = PATINDEX('%<1>%', @bin_no)  
  IF (@pat_index > 0)   
  BEGIN  
   SELECT @partial = '<1>'  
  END  
  ELSE  
  BEGIN  
   SELECT @pat_index = PATINDEX('%<2>%', @bin_no)  
   IF (@pat_index > 0)   
   BEGIN  
    SELECT @partial = '<2>'  
   END  
  END  
  
  IF (@partial IS NOT NULL)  
  BEGIN  
   IF((@qty - @in_stock) > 0)  
   BEGIN  
    UPDATE #bin_listbox   
       SET bin_no = @to_bin + @partial + RTRIM(CAST(CAST((@qty - @in_stock) AS decimal(10,2)) AS varchar(10)))  
     WHERE CURRENT OF bin_cursor   
   END  
--   ELSE  
--   BEGIN     
--    DELETE FROM #bin_listbox WHERE CURRENT OF bin_cursor  
--    INSERT INTO #bin_listbox VALUES(@to_bin + @partial + '0+0', @to_bin)   
--   END  
  END  
    
  FETCH NEXT FROM bin_cursor INTO @bin_no, @to_bin   
 END  
  
 CLOSE bin_cursor  
 DEALLOCATE bin_cursor  
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_tobin_listbox_qm_sp] TO [public]
GO

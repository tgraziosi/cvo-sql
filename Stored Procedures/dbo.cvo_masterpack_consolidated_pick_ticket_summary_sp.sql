SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* testing code:
DECLARE @summary1 VARCHAR(60), @summary2 VARCHAR(60), @summary3 VARCHAR(60) 

EXEC cvo_masterpack_consolidated_pick_ticket_summary_sp 3, '001',@summary1 OUTPUT, @summary2 OUTPUT, @summary3 OUTPUT

SELECT @summary1,@summary2,@summary3
*/
 
CREATE PROC [dbo].[cvo_masterpack_consolidated_pick_ticket_summary_sp] (@consolidation_no INT,  
																	@location VARCHAR(10),  
																	@summary1 VARCHAR(60) OUTPUT,  
																	@summary2 VARCHAR(60) OUTPUT,  
																	@summary3 VARCHAR(60) OUTPUT)  
AS  
BEGIN  
 DECLARE @type_code VARCHAR(10),  
   @qty VARCHAR(10),  
   @line_count INT,  
   @detail VARCHAR(100)  
  
 -- Create temporary table  
 CREATE TABLE #pick_summary(  
  type_code VARCHAR(10) NULL,  
  qty DECIMAL(20,8) NULL)  
  
 INSERT INTO #pick_summary(  
  type_code,  
  qty)  
 SELECT   
  b.type_code,   
  SUM(a.qty_to_process)  
 FROM   
  dbo.tdc_pick_queue a  (NOLOCK)
 INNER JOIN  
  dbo.inv_master b (NOLOCK)  
 ON  
  a.part_no = b.part_no  
 WHERE  
  a.mp_consolidation_no = @consolidation_no  
  AND a.location = @location  
 GROUP BY  
  b.type_code  
  
 SET @type_code = ''  
 SET @summary1 = 'Order Summary       '  
 SET @summary2 = ''  
 SET @summary3 = ''  
 SET @line_count = 1  
 WHILE 1=1  
 BEGIN  
  
  SELECT TOP 1  
   @type_code = type_code,  
   @qty = CAST(CAST(qty AS INT) AS VARCHAR(10))  
  FROM  
   #pick_summary  
  WHERE  
   type_code > @type_code  
   AND qty <> 0  
  ORDER BY  
   type_code  
  
  IF @@ROWCOUNT = 0  
   BREAK  
  
  SET @line_count = @line_count + 1  
  SET @detail = @type_code + ' x ' + @qty + '                    '  
  SEt @detail = LEFT(@detail,20)    
  
  IF @line_count <= 3  
  BEGIN  
   IF @summary1 = ''  
   BEGIN  
    SET @summary1 = @detail  
   END  
   ELSE  
   BEGIN  
    SET @summary1 = @summary1 + @detail  
   END  
  END  
  
  IF @line_count > 3 AND @line_count <= 6  
  BEGIN  
   IF @summary2 = ''  
   BEGIN  
    SET @summary2 = @detail  
   END  
   ELSE  
   BEGIN  
    SET @summary2 = @summary2 + @detail  
   END  
  END  
  
  IF @line_count > 6  
  BEGIN  
   IF @summary3 = ''  
   BEGIN  
    SET @summary3 = @detail  
   END  
   ELSE  
   BEGIN  
    SET @summary3 = @summary3 + @detail  
   END  
  END   
 END  
  
 DROP TABLE #pick_summary  
END  
GO
GRANT EXECUTE ON  [dbo].[cvo_masterpack_consolidated_pick_ticket_summary_sp] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apposum_sp] AS DECLARE @result int,  @sequence_loop int,  @vendor_code varchar(12), 
 @remit_code varchar(12),  @class_code varchar(8),  @branch_code varchar(8),  @apply_date int, 
 @process_key int,  @smuser_id int select @result = 0 CREATE TABLE #apintsum_pivot 
(
 sequence_id int identity(1,1),  vendor_code varchar(12),  remit_code varchar(12), 
 class_code varchar(8),  branch_code varchar(8),  apply_date int,  process_key int, 
 smuser_id int 
)
 INSERT #apintsum_pivot (  vendor_code,  remit_code,  class_code,  branch_code, 
 apply_date,  process_key,  smuser_id  )  SELECT DISTINCT vendor_code,  pay_to_code, 
 class_code,  branch_code,  date_applied,  0,  user_id  FROM #apinpchg  SELECT @sequence_loop = MIN(sequence_id) 
 FROM #apintsum_pivot  WHILE @sequence_loop IS NOT NULL  BEGIN  SELECT @vendor_code = vendor_code, 
 @remit_code = remit_code,  @class_code = class_code,  @branch_code = branch_code, 
 @apply_date = apply_date,  @process_key = process_key,  @smuser_id = smuser_id  FROM #apintsum_pivot 
 WHERE sequence_id = @sequence_loop  EXEC apintsum_sp @vendor_code,  @remit_code, 
 @class_code,  @branch_code,  @apply_date,  @process_key,  @smuser_id  SELECT @sequence_loop = MIN(sequence_id) 
 FROM #apintsum_pivot  WHERE sequence_id > @sequence_loop  END  DROP TABLE #apintsum_pivot 
RETURN @result 
GO
GRANT EXECUTE ON  [dbo].[apposum_sp] TO [public]
GO

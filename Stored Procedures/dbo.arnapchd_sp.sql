SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 2001 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 2001 Epicor Software Corporation, 2001
                 All Rights Reserved 
 */
                                             CREATE PROC [dbo].[arnapchd_sp] @from_child varchar(8), 
 @to_child varchar(8),  @parent varchar(8),  @relation_code varchar(8),  @include_children_flag smallint, 
 @source smallint,  @idForm int  AS  DECLARE @tiered_flag smallint,  @error_code smallint, 
 @child varchar(8),   @new char(3),    @tlevel smallint    SELECT @error_code = 0, 
 @child = @parent,  @new = '>>>',  @tlevel = 0       SELECT @tiered_flag = tiered_flag FROM arrelcde 
 WHERE relation_code = @relation_code  IF ( @tiered_flag IS NULL )  BEGIN  SELECT @error_code = -2 
 SELECT @error_code  RETURN  END  IF ( @tiered_flag = 1 )  BEGIN            IF ( @source = 0 )  
 BEGIN      SELECT @tlevel = tier_level  FROM artierrl  WHERE rel_cust = @parent 
 AND relation_code = @relation_code  IF ( @tlevel IS NULL )  SELECT @tlevel = 0  IF ( @tlevel = 10 )  
 BEGIN  SELECT @error_code = -1  SELECT @error_code  RETURN  END  ELSE  BEGIN    IF (@idForm = 4996 ) 
 BEGIN  INSERT #ttarnarl4991  SELECT DISTINCT NULL, @new, @parent, customer_code, 
 @relation_code  FROM arcust  WHERE customer_code >= @from_child  AND customer_code <= @to_child 
 AND customer_code <> @parent          AND customer_code NOT IN ( SELECT parent FROM arnarel 
 WHERE relation_code = @relation_code  AND parent <> @parent )  AND customer_code NOT IN ( SELECT child FROM arnarel 
 WHERE relation_code = @relation_code  AND parent <> @parent )  AND customer_code NOT IN 
 ( SELECT parent FROM #ttarnarl4991  WHERE relation_code = @relation_code )  AND customer_code NOT IN 
 ( SELECT child FROM #ttarnarl4991  WHERE relation_code = @relation_code )  END 
 IF (@idForm = 4997 )  BEGIN  INSERT #ttarnarl4992  SELECT DISTINCT NULL, @new, @parent, customer_code, 
 @relation_code  FROM arcust  WHERE customer_code >= @from_child  AND customer_code <= @to_child 
 AND customer_code <> @parent          AND customer_code NOT IN ( SELECT parent FROM arnarel 
 WHERE relation_code = @relation_code  AND parent <> @parent )  AND customer_code NOT IN ( SELECT child FROM arnarel 
 WHERE relation_code = @relation_code  AND parent <> @parent )  AND customer_code NOT IN ( SELECT parent FROM #ttarnarl4992 
 WHERE relation_code = @relation_code )  AND customer_code NOT IN ( SELECT child FROM #ttarnarl4992 
 WHERE relation_code = @relation_code )  END    END  END       END  ELSE  BEGIN  IF ( @include_children_flag = 0 ) 
 BEGIN  IF ( @source = 0 )   BEGIN    IF (@idForm = 4996 )  BEGIN  INSERT #ttarnarl4991 
 SELECT DISTINCT NULL, @new, @parent, customer_code,  @relation_code  FROM arcust 
 WHERE customer_code >= @from_child  AND customer_code <= @to_child  AND customer_code <> @parent  
 AND customer_code NOT IN ( SELECT child FROM #ttarnarl4991  WHERE parent = @parent 
 AND relation_code = @relation_code )  AND customer_code NOT IN ( SELECT child FROM arnarel 
 WHERE parent = @parent  AND relation_code = @relation_code )  END  IF (@idForm = 4997 ) 
 BEGIN  INSERT #ttarnarl4992  SELECT DISTINCT NULL, @new, @parent, customer_code, 
 @relation_code  FROM arcust  WHERE customer_code >= @from_child  AND customer_code <= @to_child 
 AND customer_code <> @parent   AND customer_code NOT IN ( SELECT child FROM #ttarnarl4992 
 WHERE parent = @parent  AND relation_code = @relation_code )  AND customer_code NOT IN ( SELECT child FROM arnarel 
 WHERE parent = @parent  AND relation_code = @relation_code )  END    END  ELSE  BEGIN 
   IF (@idForm = 4996 )  BEGIN  INSERT #ttarnarl4991  SELECT DISTINCT NULL, @new, customer_code, @child, 
 @relation_code  FROM arcust  WHERE customer_code >= @from_child  AND customer_code <= @to_child 
 AND customer_code <> @child   AND customer_code NOT IN ( SELECT parent FROM #ttarnarl4991 
 WHERE child = @child  AND relation_code = @relation_code )  AND customer_code NOT IN ( SELECT parent FROM arnarel 
 WHERE child = @child  AND relation_code = @relation_code )  END  IF (@idForm = 4997 ) 
 BEGIN  INSERT #ttarnarl4992  SELECT DISTINCT NULL, @new, customer_code, @child, 
 @relation_code  FROM arcust  WHERE customer_code >= @from_child  AND customer_code <= @to_child 
 AND customer_code <> @child   AND customer_code NOT IN ( SELECT parent FROM #ttarnarl4992 
 WHERE child = @child  AND relation_code = @relation_code )  AND customer_code NOT IN ( SELECT parent FROM arnarel 
 WHERE child = @child  AND relation_code = @relation_code )  END    END  END  ELSE 
 BEGIN       IF ( @source = 0 )   BEGIN    EXEC arparchl_sp @from_child, @to_child, @parent, @relation_code, @idForm 
 END  ELSE   BEGIN        EXEC archlpar_sp @from_child, @to_child, @parent, @relation_code, @idForm 
 END  END  END  SELECT @error_code = 0  SELECT @error_code  RETURN 

 /**/
GO
GRANT EXECUTE ON  [dbo].[arnapchd_sp] TO [public]
GO

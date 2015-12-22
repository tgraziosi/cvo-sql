SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[arparchl_sp] @from_parent varchar(8),  @to_parent varchar(8),  @parent varchar(8), 
 @relation_code varchar(8),  @idForm int AS DECLARE @child varchar(8),  @new char(3) 
SELECT @child = '',  @new = '>>>' IF (@idForm = 4996) BEGIN       INSERT #ttarnarl4991 
 SELECT NULL, @new, @parent, customer_code, @relation_code  FROM arcust WHERE customer_code >= @from_parent 
 AND customer_code <= @to_parent  AND customer_code NOT IN ( SELECT child FROM #ttarnarl4991 ) 
 ORDER BY customer_code       INSERT #arparch SELECT DISTINCT child, 0 FROM arnarel 
 WHERE parent IN ( SELECT child FROM #ttarnarl4991  WHERE relation_code = @relation_code 
 AND child >= @from_parent  AND child <= @to_parent )  AND relation_code = @relation_code 
 AND child NOT IN ( SELECT child FROM #arparch )  ORDER BY child      WHILE ( 1=1 ) 
 BEGIN  SELECT @child = MIN(child)  FROM #arparch  WHERE cflag = 0  AND child > @child 
                 IF (@@rowcount = 0 OR @child IS NULL )  BEGIN  INSERT #ttarnarl4991 SELECT NULL, @new, @parent, child, @relation_code 
 FROM #arparch  WHERE child NOT IN ( SELECT child FROM #ttarnarl4991  WHERE relation_code = @relation_code ) 
 AND child <> @parent       DELETE #ttarnarl4991 WHERE parent = child  BREAK  END 
      UPDATE #arparch SET cflag = 1 WHERE child = @child  INSERT #arparch SELECT arnarel.child, 0 FROM arnarel, #arparch 
 WHERE arnarel.parent = @child  AND arnarel.relation_code = @relation_code  AND #arparch.cflag = 1 
 AND arnarel.child NOT IN ( SELECT child FROM #arparch )  ORDER BY #arparch.child 
 END END IF (@idForm = 4997) BEGIN     INSERT #ttarnarl4992 SELECT NULL, @new, @parent, customer_code, @relation_code 
FROM arcust WHERE customer_code >= @from_parent  AND customer_code <= @to_parent 
 AND customer_code NOT IN ( SELECT child FROM #ttarnarl4992 ) ORDER BY customer_code 
    INSERT #arparch SELECT DISTINCT child, 0 FROM arnarel  WHERE parent IN ( SELECT child FROM #ttarnarl4992 
 WHERE relation_code = @relation_code  AND child >= @from_parent  AND child <= @to_parent ) 
 AND relation_code = @relation_code  AND child NOT IN ( SELECT child FROM #arparch ) 
 ORDER BY child      WHILE ( 1=1 )  BEGIN  SELECT @child = MIN(child)  FROM #arparch 
 WHERE cflag = 0  AND child > @child                  IF (@@rowcount = 0 OR @child IS NULL ) 
 BEGIN  INSERT #ttarnarl4992 SELECT NULL, @new, @parent, child, @relation_code  FROM #arparch 
 WHERE child NOT IN ( SELECT child FROM #ttarnarl4992  WHERE relation_code = @relation_code ) 
 AND child <> @parent       DELETE #ttarnarl4992 WHERE parent = child  BREAK  END 
      UPDATE #arparch SET cflag = 1 WHERE child = @child  INSERT #arparch SELECT arnarel.child, 0 FROM arnarel, #arparch 
 WHERE arnarel.parent = @child  AND arnarel.relation_code = @relation_code  AND #arparch.cflag = 1 
 AND arnarel.child NOT IN ( SELECT child FROM #arparch )  ORDER BY #arparch.child 
 END END  RETURN 
GO
GRANT EXECUTE ON  [dbo].[arparchl_sp] TO [public]
GO

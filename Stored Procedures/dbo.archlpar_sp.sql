SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[archlpar_sp] @from_parent varchar(8),  @to_parent varchar(8),  @child varchar(8), 
 @relation_code varchar(8),  @idForm int AS DECLARE @parent varchar(8),  @new char(3) 
SELECT @parent = '',  @new = '>>>'  IF (@idForm = 4996) BEGIN       INSERT #ttarnarl4991 
 SELECT NULL, @new, customer_code, @child, @relation_code  FROM arcust WHERE customer_code >= @from_parent 
 AND customer_code <= @to_parent  AND customer_code NOT IN ( SELECT parent FROM #ttarnarl4991 ) 
 ORDER BY customer_code       INSERT #archpar SELECT DISTINCT parent, 0 FROM arnarel 
 WHERE child IN ( SELECT parent FROM #ttarnarl4991  WHERE relation_code = @relation_code 
 AND parent >= @from_parent  AND parent <= @to_parent )  AND relation_code = @relation_code 
 AND parent NOT IN ( SELECT parent FROM #archpar )  ORDER BY parent        WHILE ( 1=1 ) 
 BEGIN  SELECT @parent = MIN(parent)  FROM #archpar  WHERE cflag = 0  AND parent > @parent 
                 IF @@rowcount = 0  BEGIN  INSERT #ttarnarl4991 SELECT NULL, @new, parent, @child, @relation_code 
 FROM #archpar  WHERE parent NOT IN ( SELECT parent FROM #ttarnarl4991  WHERE relation_code = @relation_code ) 
 AND parent <> @child       DELETE #ttarnarl4991 WHERE parent = child  BREAK  END 
      UPDATE #archpar SET cflag = 1 WHERE parent = @parent  INSERT #archpar SELECT arnarel.parent, 0 FROM arnarel, #archpar 
 WHERE arnarel.child = @parent  AND arnarel.relation_code = @relation_code  AND #archpar.cflag = 1 
 AND arnarel.parent NOT IN ( SELECT parent FROM #archpar )  ORDER BY #archpar.parent 
 END END IF (@idForm = 4997) BEGIN       INSERT #ttarnarl4992  SELECT NULL, @new, customer_code, @child, @relation_code 
 FROM arcust WHERE customer_code >= @from_parent  AND customer_code <= @to_parent 
 AND customer_code NOT IN ( SELECT parent FROM #ttarnarl4992 )  ORDER BY customer_code 
      INSERT #archpar SELECT DISTINCT parent, 0 FROM arnarel  WHERE child IN ( SELECT parent FROM #ttarnarl4992 
 WHERE relation_code = @relation_code  AND parent >= @from_parent  AND parent <= @to_parent ) 
 AND relation_code = @relation_code  AND parent NOT IN ( SELECT parent FROM #archpar ) 
 ORDER BY parent        WHILE ( 1=1 )  BEGIN  SELECT @parent = MIN(parent)  FROM #archpar 
 WHERE cflag = 0  AND parent > @parent                  IF @@rowcount = 0  BEGIN 
 INSERT #ttarnarl4992 SELECT NULL, @new, parent, @child, @relation_code  FROM #archpar 
 WHERE parent NOT IN ( SELECT parent FROM #ttarnarl4992  WHERE relation_code = @relation_code ) 
 AND parent <> @child       DELETE #ttarnarl4992 WHERE parent = child  BREAK  END 
      UPDATE #archpar SET cflag = 1 WHERE parent = @parent  INSERT #archpar SELECT arnarel.parent, 0 FROM arnarel, #archpar 
 WHERE arnarel.child = @parent  AND arnarel.relation_code = @relation_code  AND #archpar.cflag = 1 
 AND arnarel.parent NOT IN ( SELECT parent FROM #archpar )  ORDER BY #archpar.parent 
 END END  RETURN 
GO
GRANT EXECUTE ON  [dbo].[archlpar_sp] TO [public]
GO

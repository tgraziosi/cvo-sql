SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arbldrel.SPv - e7.2.2 : 1.8
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[arbldrel_sp] @tier_relation_code char(8)

AS
DECLARE @first_pass smallint,
 @min_code char(8), 
 @max_code char(8)


IF EXISTS ( SELECT relation_code FROM artierrl where relation_code = @tier_relation_code )
BEGIN
	DELETE artierrl
	WHERE relation_code = @tier_relation_code
END

SELECT @max_code = ' ', @first_pass = 1
 
WHILE ( 1 = 1 )
BEGIN

 SET ROWCOUNT 2000
 INSERT artierrl ( 
 relation_code,
 parent, 
 child_1, 
 child_2, 
 child_3, 
 child_4, 
 child_5,
 child_6, 	
 child_7, 
 child_8, 
 child_9, 
 rel_cust,
		tier_level ) 
 SELECT @tier_relation_code, 
 a0.customer_code, 
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 a0.customer_code,
		1
 FROM arcust a0
 WHERE a0.customer_code > @max_code
 AND a0.customer_code 
 NOT IN ( select a1.child
 FROM arnarel a1
 WHERE a1.relation_code = @tier_relation_code
 AND a1.child != a1.parent
 )
 ORDER BY a0.customer_code

 IF @@ROWCOUNT = 0 
	BEGIN
 IF @first_pass = 1
	 BEGIN
	 
	 RETURN 0
	 END

 ELSE
 BEGIN
		
		BREAK
	 END
	END

 ELSE
 BEGIN

		
 SELECT @first_pass = 0
 END
 
	
 SELECT @max_code = max(parent)
 FROM artierrl
	WHERE relation_code = @tier_relation_code

	
	CONTINUE
END

SELECT @first_pass = 1
SET ROWCOUNT 0

WHILE ( 1 = 1 )
BEGIN
 INSERT artierrl ( 
 relation_code,
 parent, 
 child_1, 
 child_2, 
 child_3, 
 child_4, 
 child_5,
 child_6, 
 child_7, 
 child_8, 
 child_9, 
 rel_cust,
		tier_level )
 SELECT @tier_relation_code,
 a0.parent,
 a1.child,
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 a1.child,
	 2
 FROM artierrl a0, arnarel a1
 WHERE a0.relation_code = @tier_relation_code
 AND a0.parent = a1.parent
 AND a1.child != a1.parent
 AND a1.relation_code = @tier_relation_code
 AND a1.child NOT IN ( SELECT child_1 FROM artierrl
				 WHERE artierrl.relation_code = @tier_relation_code)

 IF @@ROWCOUNT = 0 
 RETURN 0
 ELSE
 BREAK
END

WHILE ( 1 = 1 )
BEGIN
 INSERT artierrl ( 
 relation_code,
 parent, 
 child_1, 
 child_2, 
 child_3, 
 child_4, 
 child_5,
 child_6, 
 child_7, 
 child_8, 
 child_9, 
 rel_cust,
		tier_level )
 SELECT @tier_relation_code,
 a0.parent,
 a0.child_1,
 a1.child,
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 a1.child,
	 3
 FROM artierrl a0, arnarel a1
 WHERE a0.relation_code = @tier_relation_code
 AND a0.child_1 = a1.parent
 AND a1.child != a1.parent
 AND a1.relation_code = @tier_relation_code
 AND a1.child NOT IN ( SELECT child_2 FROM artierrl
				 WHERE artierrl.relation_code = @tier_relation_code)

 IF @@ROWCOUNT = 0 
		RETURN 0
 ELSE
 BREAK
END

WHILE ( 1 = 1 )
BEGIN
 INSERT artierrl ( 
 relation_code,
 parent, 
 child_1, 
 child_2, 
 child_3, 
 child_4, 
 child_5,
 child_6, 
 child_7, 
 child_8, 
 child_9, 
 rel_cust,
		tier_level )
 SELECT @tier_relation_code,
 a0.parent,
 a0.child_1,
 a0.child_2,
 a1.child,
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 a1.child,
	 4
 FROM artierrl a0, arnarel a1
 WHERE a0.relation_code = @tier_relation_code
 AND a0.child_2 = a1.parent
 AND a1.child != a1.parent
 AND a1.relation_code = @tier_relation_code
 AND a1.child NOT IN ( SELECT child_3 FROM artierrl
				 WHERE artierrl.relation_code = @tier_relation_code)

 IF @@ROWCOUNT = 0
 RETURN 0
 ELSE
 BREAK
END

WHILE ( 1 = 1 )
BEGIN
 INSERT artierrl ( 
 relation_code,
 parent, 
 child_1, 
 child_2, 
 child_3, 
 child_4, 
 child_5,
 child_6, 
 child_7, 
 child_8, 
 child_9, 
 rel_cust,
		tier_level )
 SELECT @tier_relation_code,
 a0.parent,
 a0.child_1,
 a0.child_2,
 a0.child_3,
 a1.child,
 '        ',
 '        ',
 '        ',
 '        ',
 '        ',
 a1.child,
	 5
 FROM artierrl a0, arnarel a1
 WHERE a0.relation_code = @tier_relation_code
 AND a1.relation_code = @tier_relation_code
 AND a1.child != a1.parent
 AND a0.child_3 = a1.parent
 AND a1.child NOT IN ( SELECT child_4 FROM artierrl
				 WHERE artierrl.relation_code = @tier_relation_code)

 IF @@ROWCOUNT = 0 
 RETURN 0
 ELSE
 BREAK
END

WHILE ( 1 = 1 )
BEGIN
 INSERT artierrl ( 
 relation_code,
 parent, 
 child_1, 
 child_2, 
 child_3, 
 child_4, 
 child_5,
 child_6, 
 child_7, 
 child_8, 
 child_9, 
 rel_cust,
		tier_level )
 SELECT @tier_relation_code,
 a0.parent,
 a0.child_1,
 a0.child_2,
 a0.child_3,
 a0.child_4,
 a1.child,
 '        ',
 '        ',
 '        ',
 '        ',
 a1.child,
	 6
 FROM artierrl a0, arnarel a1
 WHERE a0.relation_code = @tier_relation_code
 AND a0.child_4 = a1.parent
 AND a1.child != a1.parent
 AND a1.relation_code = @tier_relation_code
 AND a1.child NOT IN ( SELECT child_5 FROM artierrl
				 WHERE artierrl.relation_code = @tier_relation_code)

 IF @@ROWCOUNT = 0
 RETURN 0
 ELSE
 BREAK
END

WHILE ( 1 = 1 )
BEGIN
 INSERT artierrl ( 
 relation_code,
 parent, 
 child_1, 
 child_2, 
 child_3, 
 child_4, 
 child_5,
 child_6, 
 child_7, 
 child_8, 
 child_9, 
 rel_cust,
		tier_level )
 SELECT @tier_relation_code,
 a0.parent,
 a0.child_1,
 a0.child_2,
 a0.child_3,
 a0.child_4,
 a0.child_5,
 a1.child,
 '        ',
 '        ',
 '        ',
 a1.child,
	 7
 FROM artierrl a0, arnarel a1
 WHERE a0.relation_code = @tier_relation_code
 AND a0.child_5 = a1.parent
 AND a1.child != a1.parent
 AND a1.relation_code = @tier_relation_code
 AND a1.child NOT IN ( SELECT child_6 FROM artierrl
				 WHERE artierrl.relation_code = @tier_relation_code)

 IF @@ROWCOUNT = 0 
 RETURN 0
 ELSE
 BREAK
END

WHILE ( 1 = 1 )
BEGIN
 INSERT artierrl ( 
 relation_code,
 parent, 
 child_1, 
 child_2, 
 child_3, 
 child_4, 
 child_5,
 child_6, 
 child_7, 
 child_8, 
 child_9, 
 rel_cust,
		tier_level )
 SELECT @tier_relation_code,
 a0.parent,
 a0.child_1,
 a0.child_2,
 a0.child_3,
 a0.child_4,
 a0.child_5,
 a0.child_6,
 a1.child,
 '        ',
 '        ',
 a1.child,
	 8
 FROM artierrl a0, arnarel a1
 WHERE a0.relation_code = @tier_relation_code
 AND a0.child_6 = a1.parent
 AND a1.child != a1.parent
 AND a1.relation_code = @tier_relation_code
 AND a1.child NOT IN ( SELECT child_7 FROM artierrl
				WHERE artierrl.relation_code = @tier_relation_code)

 IF @@ROWCOUNT = 0 
 RETURN 0
 ELSE
 BREAK
END

WHILE ( 1 = 1 )
BEGIN
 INSERT artierrl ( 
 relation_code,
 parent, 
 child_1, 
 child_2, 
 child_3, 
 child_4, 
 child_5,
 child_6, 
 child_7, 
 child_8, 
 child_9, 
 rel_cust,
		tier_level )
 SELECT @tier_relation_code,
 a0.parent,
 a0.child_1,
 a0.child_2,
 a0.child_3,
 a0.child_4,
 a0.child_5,
 a0.child_6,
 a0.child_7,
 a1.child,
 '        ',
 a1.child,
	 9
 FROM artierrl a0, arnarel a1
 WHERE a0.relation_code = @tier_relation_code
 AND a0.child_7 = a1.parent
 AND a1.child != a1.parent
 AND a1.relation_code = @tier_relation_code
 AND a1.child NOT IN ( SELECT child_8 FROM artierrl
				 WHERE artierrl.relation_code = @tier_relation_code)

 IF @@ROWCOUNT = 0 
 RETURN 0
 ELSE
 BREAK
END

WHILE ( 1 = 1 )
BEGIN
 INSERT artierrl ( 
 relation_code,
 parent, 
 child_1, 
 child_2, 
 child_3, 
 child_4, 
 child_5,
 child_6, 
 child_7, 
 child_8, 
 child_9, 
 rel_cust,
		tier_level )
 SELECT @tier_relation_code,
 a0.parent,
 a0.child_1,
 a0.child_2,
 a0.child_3,
 a0.child_4,
 a0.child_5,
 a0.child_6,
 a0.child_7,
 a0.child_8,
 a1.child,
 a1.child,
	 10
 FROM artierrl a0, arnarel a1
 WHERE a0.relation_code = @tier_relation_code
 AND a0.child_8 = a1.parent
 AND a1.child != a1.parent
 AND a1.relation_code = @tier_relation_code
 AND a1.child NOT IN ( SELECT child_9 FROM artierrl
				 WHERE artierrl.relation_code = @tier_relation_code)

 IF @@ROWCOUNT = 0 
 RETURN 0
 ELSE
 BREAK
END

RETURN 0


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arbldrel_sp] TO [public]
GO

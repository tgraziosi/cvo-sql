SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\archktl.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[archktl_sp]	@parent varchar(8),
 @relation_code varchar(8),
 @source smallint 
AS

 DECLARE @child1 char(8),
 @child2 char(8),
 @child3 char(8),
 @child4 char(8),
 @child5 char(8),
 @child6 char(8),
 @child7 char(8),
 @child8 char(8),
 @child9 char(8),
 @child10 char(8),
 @count smallint,
 @tlevel char(20),
 @tier_flag smallint,
 @error_code smallint,
 @par_child smallint,
 @child_par smallint



 SELECT @par_child = 0, 
 @child_par = 1 


 SELECT @count = 0
 SELECT @child1 = NULL,
 @child2 = NULL,
 @child3 = NULL,
 @child4 = NULL,
 @child5 = NULL,
 @child6 = NULL,
 @child7 = NULL,
 @child8 = NULL,
 @child9 = NULL,
 @child10 = NULL

 SELECT @tier_flag = tiered_flag
 FROM arrelcde
 WHERE relation_code = @relation_code

 IF ( @@error <> 0 )
 BEGIN
 SELECT @error_code = -1
 RETURN
 END 


 SELECT @child1 = parent,
 @child2 = child_1, 
 @child3 = child_2, 
 @child4 = child_3, 
 @child5 = child_4, 
 @child6 = child_5, 
 @child7 = child_6, 
 @child8 = child_7, 
 @child9 = child_8, 
 @child10 = child_9 
 FROM artierrl
 WHERE relation_code = @relation_code 
 AND rel_cust = @parent
 
 IF ( @@error <> 0 )
 BEGIN
 SELECT @error_code = -2
 RETURN
 END 

 IF @child1 = @parent
 IF @source = @par_child 
 SELECT @count = 1  
 ELSE 
 SELECT @count = 2 
 IF @child2 = @parent
 SELECT @count = 2
 IF @child3 = @parent
 SELECT @count = 3
 IF @child4 = @parent
 SELECT @count = 4
 IF @child5 = @parent
 SELECT @count = 5
 IF @child6 = @parent
 SELECT @count = 6
 IF @child7 = @parent
 SELECT @count = 7
 IF @child8 = @parent
 SELECT @count = 8 
 IF @child9 = @parent 
 SELECT @count = 9
 IF @child10 = @parent 
 SELECT @count = 10
 
 IF ( @count <> 0 )
 BEGIN
 IF ( @count = 1 )
 SELECT @tlevel = tier_label1
 FROM arrelcde
 WHERE relation_code = @relation_code
 IF ( @count = 2 )
 SELECT @tlevel = tier_label2
 FROM arrelcde
 WHERE relation_code = @relation_code
 IF ( @count = 3 )
 SELECT @tlevel = tier_label3
 FROM arrelcde
 WHERE relation_code = @relation_code
 IF ( @count = 4 )
 SELECT @tlevel = tier_label4
 FROM arrelcde
 WHERE relation_code = @relation_code
 IF ( @count = 5 )
 SELECT @tlevel = tier_label5
 FROM arrelcde
 WHERE relation_code = @relation_code
 IF ( @count = 6 )
 SELECT @tlevel = tier_label6
 FROM arrelcde
 WHERE relation_code = @relation_code
 IF ( @count = 7 )
 SELECT @tlevel = tier_label7
 FROM arrelcde
 WHERE relation_code = @relation_code
 IF ( @count = 8 )
 SELECT @tlevel = tier_label8
 FROM arrelcde
 WHERE relation_code = @relation_code
 IF ( @count = 9 )
 SELECT @tlevel = tier_label9
 FROM arrelcde
 WHERE relation_code = @relation_code
 IF ( @count = 10 )
 SELECT @tlevel = tier_label10
 FROM arrelcde
 WHERE relation_code = @relation_code
 END
 ELSE
 SELECT @tlevel = ""

 SELECT @error_code = 0
 SELECT @tlevel, @tier_flag, @count, @error_code
 RETURN


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[archktl_sp] TO [public]
GO

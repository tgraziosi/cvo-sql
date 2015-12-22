SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/* PVCS Revision or Version:Revision                
I:\vcs\AR\PROCS\arbldna.SPv - e7.2.2 : 1.0  
              Confidential Information                    
   Limited Distribution of Authorized Persons Only        
   Created 1996 and Protected as Unpublished Work         
         Under the U.S. Copyright Act of 1976             
Copyright (c) 1996 Epicor Software Corporation, 1996    
                 All Rights Reserved                      
*/                                                  
  
-- v1.0 CB 10/10/2013 - Fix issue with std routine inserting duplicate records  
  
CREATE PROC [dbo].[arbldna_sp]   
  @tier_relation_code char(8),  
  @parent char(8)  
As  
  
Delete artierrl   
Where relation_code = @tier_relation_code  
And parent = @parent  
  
  
  
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
Values (  
 @tier_relation_code,   
 @parent, ' ', ' ', ' ', ' ',   
 ' ', ' ', ' ', ' ', ' ',   
 @parent, 1)  
  
   
  
INSERT artierrl (   
 relation_code, parent, child_1,   
 child_2, child_3, child_4, child_5,   
 child_6, child_7, child_8, child_9,   
 rel_cust, tier_level )   
SELECT DISTINCT @tier_relation_code, a0.parent,  -- v1.0 
 a1.child, ' ', ' ', ' ',   
 ' ', ' ', ' ', ' ', ' ', a1.child, 2   
FROM artierrl a0, arnarel a1   
WHERE a0.relation_code = @tier_relation_code   
AND a0.parent = a1.parent   
AND a1.child != a1.parent   
AND a1.relation_code = @tier_relation_code   
AND a1.parent = @parent  
  
  
  
If @@rowcount = 0  
 Return  
  
INSERT artierrl (   
 relation_code, parent, child_1, child_2,   
 child_3, child_4, child_5, child_6,   
 child_7, child_8, child_9, rel_cust,   
 tier_level )   
SELECT @tier_relation_code,   
 a0.parent, a0.child_1, a1.child, ' ',   
 ' ', ' ', ' ', ' ', ' ', ' ',   
 a1.child, 3   
FROM artierrl a0,   
 arnarel a1   
WHERE a0.relation_code = @tier_relation_code   
AND a1.relation_code = @tier_relation_code   
AND a0.parent = @parent  
AND a0.child_1 = a1.parent  
AND a1.parent in   
  (Select child_1  
   From artierrl  
   Where relation_code = @tier_relation_code   
   And parent = @parent  
   And child_1 > ' ')  
  
  
  
If @@rowcount = 0  
 Return  
  
INSERT artierrl ( relation_code, parent,   
 child_1, child_2, child_3,   
 child_4, child_5, child_6, child_7,   
 child_8, child_9, rel_cust, tier_level )   
SELECT @tier_relation_code, a0.parent, a0.child_1,   
 a0.child_2, a1.child, ' ', ' ', ' ', ' ',   
 ' ', ' ', a1.child, 4   
FROM artierrl a0,   
 arnarel a1   
WHERE a0.relation_code = @tier_relation_code   
AND a1.relation_code = @tier_relation_code   
AND a0.parent = @parent  
AND a0.child_2 = a1.parent  
AND a1.parent in   
  (Select child_2  
   From artierrl  
   Where relation_code = @tier_relation_code   
   And parent = @parent  
   And child_2 > ' ')  
      
If @@rowcount = 0  
 Return  
     
INSERT artierrl ( relation_code, parent,   
 child_1, child_2, child_3, child_4,   
 child_5, child_6, child_7, child_8,   
 child_9, rel_cust, tier_level )   
SELECT @tier_relation_code, a0.parent, a0.child_1,   
 a0.child_2, a0.child_3, a1.child, ' ', ' ', ' ',   
 ' ', ' ', a1.child, 5   
FROM artierrl a0,   
 arnarel a1   
WHERE a0.relation_code = @tier_relation_code   
AND a1.relation_code = @tier_relation_code   
AND a0.parent = @parent  
AND a0.child_3 = a1.parent   
AND a1.parent in   
  (Select child_3  
   From artierrl  
   Where relation_code = @tier_relation_code   
   And parent = @parent  
   And child_3 > ' ')  
  
If @@rowcount = 0  
 Return  
  
INSERT artierrl ( relation_code, parent,   
 child_1, child_2, child_3, child_4,   
 child_5, child_6, child_7, child_8, child_9,   
 rel_cust, tier_level )   
SELECT @tier_relation_code, a0.parent,   
 a0.child_1, a0.child_2, a0.child_3, a0.child_4,   
 a1.child, ' ', ' ', ' ', ' ', a1.child, 6   
FROM artierrl a0,   
 arnarel a1   
WHERE a0.relation_code = @tier_relation_code   
AND a1.relation_code = @tier_relation_code   
AND a0.parent = @parent  
AND a0.child_4 = a1.parent   
AND a1.parent in   
  (Select child_4  
   From artierrl  
   Where relation_code = @tier_relation_code   
   And parent = @parent  
   And child_4 > ' ')  
  
If @@rowcount = 0  
 Return  
  
INSERT artierrl ( relation_code, parent,   
 child_1, child_2, child_3, child_4,   
 child_5, child_6, child_7, child_8, child_9,   
 rel_cust, tier_level )   
SELECT @tier_relation_code, a0.parent, a0.child_1, a0.child_2,   
 a0.child_3, a0.child_4, a0.child_5, a1.child,   
 ' ', ' ', ' ', a1.child, 7   
FROM artierrl a0,   
 arnarel a1   
WHERE a0.relation_code = @tier_relation_code   
AND a1.relation_code = @tier_relation_code   
AND a0.parent = @parent  
AND a0.child_5 = a1.parent   
AND a1.parent in   
  (Select child_5  
   From artierrl  
   Where relation_code = @tier_relation_code   
   And parent = @parent  
   And child_5 > ' ')  
  
If @@rowcount = 0  
 Return  
  
INSERT artierrl ( relation_code, parent,   
 child_1, child_2, child_3, child_4,   
 child_5, child_6, child_7, child_8, child_9,   
 rel_cust, tier_level )   
SELECT @tier_relation_code, a0.parent, a0.child_1, a0.child_2,   
 a0.child_3, a0.child_4, a0.child_5, a0.child_6,   
 a1.child, ' ', ' ', a1.child, 8   
FROM artierrl a0,   
 arnarel a1   
WHERE a0.relation_code = @tier_relation_code   
AND a1.relation_code = @tier_relation_code   
AND a0.parent = @parent  
AND a0.child_6 = a1.parent   
AND a1.parent in   
  (Select child_6  
   From artierrl  
   Where relation_code = @tier_relation_code   
   And parent = @parent  
   And child_6 > ' ')  
  
If @@rowcount = 0  
 Return  
  
INSERT artierrl (   
 relation_code, parent, child_1,   
 child_2, child_3, child_4, child_5, child_6,   
 child_7, child_8, child_9, rel_cust, tier_level )   
SELECT @tier_relation_code, a0.parent, a0.child_1,   
 a0.child_2, a0.child_3, a0.child_4, a0.child_5, a0.child_6,   
 a0.child_7, a1.child, ' ', a1.child, 9   
FROM artierrl a0,   
 arnarel a1   
WHERE a0.relation_code = @tier_relation_code   
AND a1.relation_code = @tier_relation_code   
AND a0.parent = @parent  
AND a0.child_7 = a1.parent   
AND a1.parent in   
  (Select child_7  
   From artierrl  
   Where relation_code = @tier_relation_code   
   And parent = @parent  
   And child_7 > ' ')  
  
If @@rowcount = 0  
 Return  
  
INSERT artierrl (   
 relation_code, parent, child_1,   
 child_2, child_3, child_4, child_5, child_6,   
 child_7, child_8, child_9, rel_cust, tier_level )   
SELECT @tier_relation_code, a0.parent, a0.child_1,   
 a0.child_2, a0.child_3, a0.child_4, a0.child_5, a0.child_6,   
 a0.child_7, a0.child_8, a1.child, a1.child, 10   
FROM artierrl a0,   
 arnarel a1   
WHERE a0.relation_code = @tier_relation_code   
AND a1.relation_code = @tier_relation_code   
AND a0.parent = @parent  
AND a0.child_8 = a1.parent   
AND a1.parent in   
  (Select child_8  
   From artierrl  
   Where relation_code = @tier_relation_code   
   And parent = @parent  
   And child_8 > ' ')  
  
Return  
  
GO
GRANT EXECUTE ON  [dbo].[arbldna_sp] TO [public]
GO

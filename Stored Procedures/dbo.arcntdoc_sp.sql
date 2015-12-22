SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arcntdoc.SPv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[arcntdoc_sp] @doc_ctrl_num char(16) AS

DECLARE @count1 int, @count2 int 

SELECT @count1 = count(*) 
FROM arinpchg 
WHERE arinpchg.doc_ctrl_num= @doc_ctrl_num
 AND arinpchg.trx_type <= 2031 

 SELECT @count2 = count(*) 
FROM artrx 
WHERE artrx.doc_ctrl_num= @doc_ctrl_num
 AND artrx.trx_type <= 2031 

SELECT @count1 + @count2 


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcntdoc_sp] TO [public]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 18/07/2012 - cvo version of std wrapper, returns value as opposed to selecting it and creates temp table reqd

CREATE PROCEDURE [dbo].[cvo_fs_archklmt_sp_wrap] @customer_code varchar(10),  @date_entered int,  @ordno int,  @ordext int   
AS   
BEGIN  
  
DECLARE  @err1  int  

CREATE TABLE #arcrchk (
	customer_code varchar(8), 
	check_credit_limit smallint, 
	credit_limit float, 
	limit_by_home smallint) 

CREATE UNIQUE INDEX #arcrchk_ind_0 ON #arcrchk (customer_code)
  
exec  fs_archklmt_sp  @customer_code,  @date_entered,   @ordno,  @ordext,  @err1  OUT  

DROP TABLE #arcrchk
  
RETURN @err1 
  
END  

GO
GRANT EXECUTE ON  [dbo].[cvo_fs_archklmt_sp_wrap] TO [public]
GO

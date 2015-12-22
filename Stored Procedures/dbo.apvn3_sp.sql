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
          create proc [dbo].[apvn3_sp] @WhereClause varchar(1024)="" as DECLARE  @Sub1 varchar(1024), 
 @Sub2 varchar(1024),  @OrderBy varchar(255) select @OrderBy = " order by address_name" 
   if (charindex('%ACTIVE%',@WhereClause) <> 0) begin  select @Sub1 = substring(@WhereClause, 1, charindex('%ACTIVE%',@WhereClause) - 1) 
 select @Sub2 = substring(@WhereClause, charindex('%ACTIVE%',@WhereClause) + 1, datalength(@WhereClause)) 
 select @WhereClause = @Sub1 + @Sub2 end       exec (" select * from apvn3_vw " + @WhereClause + @OrderBy ) 
GO
GRANT EXECUTE ON  [dbo].[apvn3_sp] TO [public]
GO
